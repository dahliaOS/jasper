// Copyright 2017 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io';

import 'package:mod/commands.dart';
import 'package:path/path.dart' as path;
import 'package:test/test.dart';

import '../util.dart';

void main() {
  // Common template values to be used in all tests.
  const Map<String, String> templateValues = const <String, String>{
    'ProjectName': 'HelloWorld',
    'projectName': 'helloWorld',
    'project_name': 'hello_world',
  };

  test('renderTemplateString() should render the template variables correctly.',
      () {
    const String template = r'''This is a test string.
ProjectName: __ProjectName__
projectName: __projectName__
project_name: __project_name__
''';

    const String expected = r'''This is a test string.
ProjectName: HelloWorld
projectName: helloWorld
project_name: hello_world
''';

    expect(
      CreateCommand.renderTemplateString(template, templateValues),
      equals(expected),
    );
  });

  test(
      'copyTemplateFile() should copy the file with the template variables '
      'correctly rendered.', () async {
    // Create a temp directory.
    Directory tempDir = Directory.systemTemp.createTempSync('copyTemplateFile');

    const String filename = 'template_file.txt';
    File src = new File(path.join(getTestDataPath(), 'create', filename));
    File dest = new File(path.join(tempDir.path, filename));

    await CreateCommand.copyTemplateFile(src, dest, templateValues);

    const String expected = r'''This is a template file.

ProjectName: HelloWorld
projectName: helloWorld
project_name: hello_world
''';

    expect(dest.existsSync(), isTrue);
    expect(dest.readAsStringSync(), equals(expected));

    // Clean up the temp directory.
    tempDir.deleteSync(recursive: true);
  });

  test(
      'copyTemplateDir() should copy the directory contents recursively, '
      'with template variables in file names and contents rendered corectly.',
      () async {
    // Create a temp directory.
    Directory tempDir = Directory.systemTemp.createTempSync('copyTemplateDir');

    Directory src = new Directory(path.join(
      getTestDataPath(),
      'create',
      'templates',
      'mod',
    ));
    Directory dest = new Directory(path.join(tempDir.path, 'hello_world'));
    Directory expected = new Directory(path.join(
      getTestDataPath(),
      'create',
      'hello_world',
    ));

    await CreateCommand.copyTemplateDir(src, dest, templateValues);

    compareDirs(dest, expected);

    // Clean up the temp directory.
    tempDir.deleteSync(recursive: true);
  });

  test('create command should be correctly invoked with "mod create" arguments',
      () async {
    // Create a temp directory.
    Directory tempDir = Directory.systemTemp.createTempSync('mod_create');

    ModCommandRunner runner = new ModCommandRunner(
      workingDir: tempDir,
      statusPrinter: (String msg) => null, // Do not print the status messages.
    )..addCommand(new CreateCommand(
        templatesDir: new Directory(path.join(
          getTestDataPath(),
          'create',
          'templates',
        )),
      ));
    await runner.run(const <String>['create', 'hello_world']);

    Directory dest = new Directory(path.join(tempDir.path, 'hello_world'));
    Directory expected = new Directory(path.join(
      getTestDataPath(),
      'create',
      'hello_world',
    ));

    compareDirs(dest, expected);

    // Clean up the temp directory.
    tempDir.deleteSync(recursive: true);
  });

  test('create command should fail with non-standard project names', () async {
    // Create a temp directory.
    Directory tempDir = Directory.systemTemp.createTempSync('mod_create');

    ModCommandRunner runner = new ModCommandRunner(
      workingDir: tempDir,
      statusPrinter: (String msg) => null, // Do not print the status messages.
    )..addCommand(new CreateCommand(
        templatesDir: new Directory(path.join(
          getTestDataPath(),
          'create',
          'templates',
        )),
      ));

    await expectLater(
      runner.run(const <String>['create']),
      throwsA(const TypeMatcher<UsageException>()),
    );

    expect(tempDir.listSync(), isEmpty);

    await expectLater(
      runner.run(const <String>['create', 'WRONG_NAME']),
      throwsA(const TypeMatcher<UsageException>()),
    );

    expect(tempDir.listSync(), isEmpty);

    // Clean up the temp directory.
    tempDir.deleteSync(recursive: true);
  });

  test('isValidProjectName() should accept normal package names', () {
    for (String projectName in <String>[
      'hello_world',
      'lowercase_with_underscore',
    ]) {
      expect(CreateCommand.isValidProjectName(projectName), isTrue);
    }
  });

  test('isValidProjectName() should not accept non-standard package names', () {
    for (String projectName in <String>[
      '123_abc',
      'something_with_exclamation!',
      'camelCase',
      'UPPER_CASE',
    ]) {
      expect(CreateCommand.isValidProjectName(projectName), isFalse);
    }
  });
}

/// Compares two directories. Fails when the directory names don't match, or
/// their contents are different. Recursively compares any child directories and
/// files.
void compareDirs(Directory actual, Directory expected) {
  expect(path.basename(actual.path), equals(path.basename(expected.path)));
  expect(actual.existsSync(), isTrue);

  List<FileSystemEntity> actualList = actual.listSync();
  List<FileSystemEntity> expectedList = expected.listSync();
  expect(actualList.length, equals(expectedList.length));

  for (FileSystemEntity entity in actualList) {
    String basename = path.basename(entity.path);
    if (entity is File) {
      compareFiles(entity, new File(path.join(expected.path, basename)));
    } else if (entity is Directory) {
      compareDirs(entity, new Directory(path.join(expected.path, basename)));
    } else {
      throw new Exception('Unexpected entity type.');
    }
  }
}

/// Compares two files. Fails when the files names don't match, or their file
/// contents are different.
void compareFiles(File actual, File expected) {
  expect(path.basename(actual.path), equals(path.basename(expected.path)));
  expect(actual.existsSync(), isTrue);
  expect(actual.readAsStringSync(), equals(expected.readAsStringSync()));
}
