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

Future<String> render(String source, IconSetData data) async {
  final env = Environment();
  final template = env.fromString(source);
  final dataMap = data.toMap();
  return template.render({
    ...dataMap,
    'version': data.info.version ??
        await bumpPackageSemverOrNull(
            'packages/dcubo_iconify_${data.fileName}/') ??
        '0.1.0',
  });
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

/// This function either returns a String with the semver of the package
/// or null if the package is not found
Future<String?> getPackageSemverOrNull(String path) async {
  final pubspec = File('$path/pubspec.yaml');
  if (!pubspec.existsSync()) {
    return null;
  }
  final pubspecContent = loadYaml(await pubspec.readAsString());
  return pubspecContent['version'] as String?;
}

/// This function either returns a String with the semver of the package
/// bumped by one minor version or null if the package is not found
/// or the version is not a valid semver
Future<String?> bumpPackageSemverOrNull(String path) async {
  final semver = await getPackageSemverOrNull(path);
  if (semver == null) {
    return null;
  }
  // Do not use Version.parse here because it throws an exception
  final parts = semver.split('.');
  if (parts.length != 3) {
    return null;
  }
  final major = int.tryParse(parts[0]);
  final minor = int.tryParse(parts[1]);
  final patch = int.tryParse(parts[2]);
  if (major == null || minor == null || patch == null) {
    return null;
  }
  return '$major.${minor + 1}.$patch';
}

/// This function either returns an int with the lastModified time of a
/// package or null if the package is not found
Future<int?> getPackageLastModifiedOrNull(String path) async {
  final pubspec = File('$path/pubspec.yaml');
  if (!pubspec.existsSync()) {
    return null;
  }
  final pubspecContent = loadYaml(await pubspec.readAsString());
  return pubspecContent['lastModified'] as int?;
}
