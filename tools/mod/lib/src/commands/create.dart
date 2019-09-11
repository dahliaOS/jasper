// Copyright 2017 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:path/path.dart' as path;
import 'package:strings/strings.dart' as strings;

import 'command_runner.dart';

/// Create command.
class CreateCommand extends ModCommand {
  final Directory _templatesDir;

  /// Creates a new instance of [CreateCommand].
  CreateCommand({Directory templatesDir}) : _templatesDir = templatesDir {
    argParser.addOption(
      'template',
      abbr: 't',
      allowed: const <String>['mod'],
      help: 'Specify the type of project to create',
      valueHelp: 'type',
      allowedHelp: const <String, String>{
        'mod': '(default) Generate a Fuchsia mod.',
      },
      defaultsTo: 'mod',
    );
  }

  @override
  String get description => '''Create a new Fuchsia mod project.

The project name must be lowercase_with_underscores.
''';

  @override
  String get name => 'create';

  @override
  String get invocation => '${runner.executableName} $name <project_name>';

  /// The templates directory.
  Directory get templatesDir =>
      _templatesDir ??
      new Directory(path.join(modPackageRoot.path, 'templates'));

  static final RegExp _projectNamePattern = new RegExp(r'^[a-z][a-z0-9_]*$');

  @override
  Future<Null> run() async {
    // Check if the argument is correct.
    if (argResults.rest.length != 1) {
      throw new UsageException('The project name must be provided.', usage);
    }

    // Check if the project name is valid.
    String projectName = argResults.rest[0];
    if (!isValidProjectName(projectName)) {
      throw new UsageException(
        'The project name must be lowercase_with_underscores',
        usage,
      );
    }

    Map<String, String> templateValues = new Map<String, String>.unmodifiable(
      <String, String>{
        'project_name': strings.underscore(projectName),
        'projectName': strings.camelize(projectName, true),
        'ProjectName': strings.camelize(projectName, false),
      },
    );

    String projectPath = path.join(
      runner.workingDir.path,
      templateValues['project_name'],
    );

    if (FileSystemEntity.typeSync(projectPath) !=
        FileSystemEntityType.notFound) {
      throw new UsageException('"$projectName" already exists.', usage);
    }

    // Copy the files over, and replace the template variables.
    await copyTemplateDir(
      new Directory(path.join(templatesDir.path, argResults['template'])),
      new Directory(projectPath),
      templateValues,
    );

    printStatus('''Project "$projectName" created successfully!

Be sure to add this project to your BUILD.gn package definition so that it
appears on the target device.
''');
  }

  /// Copies the src template directory into the dest directory recursively,
  /// while replacing all the template parameters with actual values.
  static Future<Null> copyTemplateDir(
    Directory src,
    Directory dest,
    Map<String, String> templateValues,
  ) async {
    await dest.create(recursive: true);
    await for (FileSystemEntity entity in src.list()) {
      String destName = path.join(
        dest.path,
        renderTemplateString(path.basename(entity.path), templateValues),
      );

      if (entity is File) {
        await copyTemplateFile(entity, new File(destName), templateValues);
      } else if (entity is Directory) {
        await copyTemplateDir(entity, new Directory(destName), templateValues);
      } else {
        throw new Exception('Unrecognized type: ${entity.runtimeType}');
      }
    }
  }

  /// Copies the src template file into the dest file, while replacing all the
  /// template parameters with actual values.
  static Future<Null> copyTemplateFile(
    File src,
    File dest,
    Map<String, String> templateValues,
  ) async {
    await dest.writeAsString(
      renderTemplateString(
        await src.readAsString(),
        templateValues,
      ),
    );
  }

  /// Replaces all the template parameters in the given template with the actual
  /// values provided in the map.
  static String renderTemplateString(
    String template,
    Map<String, String> templateValues,
  ) {
    String result = template;
    for (String key in templateValues.keys) {
      result = result.replaceAll('__${key}__', templateValues[key]);
    }
    return result;
  }

  /// Determines whether the given project name is valid.
  static bool isValidProjectName(String projectName) =>
      _projectNamePattern.hasMatch(projectName);
}
