import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:dcubo_iconify_generator/src/api.dart';
import 'package:dcubo_iconify_generator/src/generator.dart';
import 'package:mason_logger/mason_logger.dart';

/// This variable may change if the template path changes
const templatePath = 'packages/_/dcubo_iconify_{{ fileName }}/';

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
    argParser.addFlag(
      'yes',
      help: 'Skip confirmation prompt',
      abbr: 'y',
      negatable: false,
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

      // 3. Get the files and folders to process
      final templateUri = Uri.file(templatePath);
      final newFolder = render(templatePath, iconSetData);
      final templateFolders = getAllFolders(templateUri);
      final templateFiles = getTemplateFiles(templateUri);

      // 4. Iterate over the folders
      for (final folder in templateFolders) {
        final templatePath = folder.pathSegments.join('/');
        // 4.1 Replace all variables in the folder name
        final newFolderPath = render(templatePath, iconSetData);

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
            render(templatePath, iconSetData).replaceAll('.tem', '');
        progress.update('Creating $newFilePath');
        // 5.1 Write the files after rendering the template
        final templateFileContent = await File(templatePath).readAsString();
        final newFileContent = render(templateFileContent, iconSetData);
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
      final targetPath = render(templateTargetPath, iconSetData);
      progress.update('Moving to $targetPath');
      await Directory(targetPath).delete(recursive: true);
      await Directory(newFolder).rename(targetPath);

      progress.complete('${set.name} generated');
    }

    // Finally, update the workspace pubspec
    await updateWorkspace();

    return ExitCode.success.code;
  }
}
