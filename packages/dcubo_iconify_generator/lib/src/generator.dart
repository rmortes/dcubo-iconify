import 'dart:io';

import 'package:dcubo_iconify_generator/src/api.dart';
import 'package:jinja/jinja.dart';
import 'package:yaml/yaml.dart';
import 'package:yaml_writer/yaml_writer.dart';

/// Returns a list of all folders that must be processed as templates.
/// Folder processing involves processing just the folder name
///
/// This method recursively searches for all folders
///
/// You probably want to make sure the Uri ends in a slash `/` to make sure
/// the root folder name gets processed as well
List<Uri> getAllFolders(Uri path) {
  final dir = Directory.fromUri(path);
  final folders = <Uri>[path];
  for (final entity in dir.listSync()) {
    if (entity is Directory) {
      folders.addAll(getAllFolders(entity.uri));
    }
  }
  return folders;
}

/// Returns a list of all files that must be processed as templates.
/// File processing involves processing the file contents and the file name
///
/// This method recursively searches for files that end in `.tem`
/// in the given [path] and all recursive subdirectories that end in `.tem`
List<Uri> getTemplateFiles(Uri path) {
  final templateFolders = getAllFolders(path);
  final files = <Uri>[];
  for (final folder in templateFolders) {
    final dir = Directory.fromUri(folder);
    for (final entity in dir.listSync()) {
      if (entity is File && entity.path.endsWith('.tem')) {
        files.add(entity.uri);
      }
    }
  }
  return files;
}

/// Returns a list of all files that mustn't be processed as templates.
///
/// This method searches for all files in the given [path]
/// that don't end in `.tem` not including subdirectories
List<Uri> getNonTemplateFiles(Uri path) {
  final dir = Directory.fromUri(path);
  final files = <Uri>[];
  for (final entity in dir.listSync()) {
    if (entity is File && !entity.path.endsWith('.tem')) {
      files.add(entity.uri);
    }
  }
  return files;
}

String render(String source, IconSetData data) {
  final env = Environment();
  final template = env.fromString(source);
  return template.render(data.toMap());
}

Future<dynamic> updateWorkspace() async {
  final workspacePubspec = File('pubspec.yaml');
  final workspacePubspecContent = loadYaml(
    await workspacePubspec.readAsString(),
  );

  final allPackages = await Directory('packages').list();
  final workspacePackages = <String>{};
  await for (final entity in allPackages) {
    if (entity is Directory) {
      // Test if the directory is a package by checking for a pubspec.yaml file
      if (!File('${entity.path}/pubspec.yaml').existsSync()) {
        continue;
      }
      final pubspec = File('${entity.path}/pubspec.yaml');
      final pubspecContent = loadYaml(await pubspec.readAsString());
      // Check if the package has resolution: workspace in the pubspec
      if (pubspecContent['resolution'] == null ||
          pubspecContent['resolution'] != 'workspace') {
        continue;
      }
      workspacePackages.add(entity.path.split('/').last);
    }
  }

  await workspacePubspec.writeAsString(
    YamlWriter().write({
      ...workspacePubspecContent as Map,
      'workspace': workspacePackages.map((name) => 'packages/$name').toList(),
    }),
  );
}
