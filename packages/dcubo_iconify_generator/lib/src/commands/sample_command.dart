import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:dcubo_iconify_generator/src/api.dart';
import 'package:dcubo_iconify_generator/src/generator.dart';
import 'package:mason_logger/mason_logger.dart';

/// This variable may change if the template path changes
const templatePath = 'packages/_/dcubo_iconify_{{ fileName }}/';
const templatePartedPath = 'packages/_/dcubo_iconify_{{ fileName }}_parted/';
const partedThreshold = 2000;

/// The path the rendered packages will be moved into
const templateTargetPath = 'packages/dcubo_iconify_{{ fileName }}/';

/// {@template sample_command}
///
/// `dcubo_iconify_generator sample`
/// A [Command] to exemplify a sub command
/// {@endtemplate}
class SampleCommand extends Command<int> {
  /// {@macro sample_command}
  SampleCommand({
    required Logger logger,
  }) : _logger = logger {
    argParser
      ..addFlag(
        'yes',
        help: 'Skip confirmation prompt',
        abbr: 'y',
        negatable: false,
      )
      ..addFlag(
        'release',
        help: 'Generate the release version of the package',
        abbr: 'r',
        negatable: false,
      )
      ..addFlag(
        'force',
        help: 'Force generation of the package, even if it is up to date',
        abbr: 'f',
      )
      ..addOption(
        'throttle',
        abbr: 't',
        help: 'Throttle the requests (in seconds)',
        defaultsTo: '0',
      );
  }

  @override
  String get description => 'A command to generate all icon packages. '
      'You optionally specify which to generate vie arguments';

  @override
  String get name => 'generate';

  final Logger _logger;

  @override
  Future<int> run() async {
    final sets = await getIconSets(globalResults?.option('token') ?? '');
    final setNamesToGenerate = argResults?.rest ?? [];
    final setsToGenerate = setNamesToGenerate.isEmpty
        ? sets
        : setNamesToGenerate.map((name) {
            final set = sets.firstWhere(
              (element) => element.name.startsWith(name),
              orElse: () => throw Exception('Set $name not found'),
            );
            return set;
          }).toList();

    _logger.info('${setsToGenerate.length} sets to generate');
    if (argResults?.flag('yes') != true) {
      final proceed = _logger.confirm('Proceed?');
      if (!proceed) {
        _logger.info('Aborted');
        return ExitCode.success.code;
      }
    }

    for (final set in setsToGenerate) {
      // 1. Start the progress notifier. This makes the output pretty
      final progress = _logger.progress('Generating ${set.name}');

      // 2. Fetch the icon set data
      final iconSetData = await getIconSetData(
        set.downloadUrl,
        globalResults?.option('token') ?? '',
      );
      final usesParted = iconSetData.icons.length > partedThreshold;
      if (usesParted) {
        _logger.info(
            '${set.name} has more than $partedThreshold icons (${iconSetData.icons.length}). Using parted template');
      }
      final thisTemplatePath = usesParted ? templatePartedPath : templatePath;

      // 2.1 If the iconset data lastModified and the local
      // lastModified are the same, skip
      final localLastModified = await getPackageLastModifiedOrNull(
        'packages/dcubo_iconify_${iconSetData.fileName}',
      );
      if (localLastModified != null &&
          localLastModified == iconSetData.lastModified) {
        if (argResults?.flag('force') != true) {
          progress.fail('Skipping ${set.name}, already up to date');
          continue;
        } else {
          _logger.warn('Forcing generation of ${set.name}');
        }
      }

      // 2.2 If there are no icons, skip
      if (iconSetData.icons.isEmpty) {
        progress.fail('Skipping ${set.name}, no icons found');
        continue;
      }

      // 3. Get the files and folders to process
      final templateUri = Uri.file(thisTemplatePath);
      final newFolder = await render(thisTemplatePath, iconSetData);
      final templateFolders = getAllFolders(templateUri);
      final templateFiles = getTemplateFiles(templateUri);

      // 4. Iterate over the folders
      for (final folder in templateFolders) {
        final templatePath = folder.pathSegments.join('/');
        // 4.1 Replace all variables in the folder name
        final newFolderPath = await render(templatePath, iconSetData);

        progress.update('Creating $newFolderPath');
        await Directory(newFolderPath).create(recursive: true);

        // 4.2 Copy all non template files to the new folder
        final nonTemplateFiles = getNonTemplateFiles(folder);

        for (final file in nonTemplateFiles) {
          final newFilePath = newFolderPath +
              file.pathSegments.join('/').replaceFirst(templatePath, '');
          progress.update('Creating $newFilePath');
          await File(file.pathSegments.join('/')).copy(newFilePath);
        }
      }

      // 5. Iterate over the template files
      for (final file in templateFiles) {
        final templatePath = file.pathSegments.join('/');
        final newFilePath =
            (await render(templatePath, iconSetData)).replaceAll('.tem', '');
        progress.update('Creating $newFilePath');
        // 5.1 Write the files after rendering the template
        final templateFileContent = await File(templatePath).readAsString();
        final newFileContent = await render(templateFileContent, iconSetData);
        final newFile = await File(newFilePath).create(recursive: true);
        await newFile.writeAsString(newFileContent);
      }

      // 6. Run `dart fix --apply`
      progress.update('Running dart format');
      await Process.run(
        'dart',
        ['format', '.'],
        workingDirectory: newFolder,
      );

      // 7. Move the folder to the target path
      final targetPath = await render(templateTargetPath, iconSetData);
      progress.update('Moving to $targetPath');
      // Delete the target path if it exists
      if (Directory(targetPath).existsSync()) {
        await Directory(targetPath).delete(recursive: true);
      }
      await Directory(newFolder).rename(targetPath);

      // 8. If the release flag is set, run `pub publish`
      if (argResults?.flag('release') ?? false) {
        // 8.1 Updating the workspace pubspec is required before publishing
        progress.update('Updating workspace pubspec');
        await updateWorkspace();
        progress.update('Publishing');
        await Process.run(
          'flutter',
          ['pub', 'publish', '-f'],
          workingDirectory: targetPath,
        );
      }

      progress.complete('${set.name} generated');

      if (int.parse(argResults?['throttle'] as String? ?? '0') > 0) {
        _logger.info('Throttling for ${argResults?['throttle']} seconds');
        await Future.delayed(
          Duration(
            seconds: int.parse(argResults?['throttle'] as String? ?? '0'),
          ),
        );
      }
    }

    // Finally, update the workspace pubspec
    await updateWorkspace();

    return ExitCode.success.code;
  }
}
