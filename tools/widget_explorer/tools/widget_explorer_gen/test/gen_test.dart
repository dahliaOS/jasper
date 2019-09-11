// Copyright 2017 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io';

import 'package:path/path.dart' as path;
import 'package:test/test.dart';

import 'util.dart';

void main() {
  test('widget_explorer_gen tool should correctly generate the expected files.',
      () async {
    String mockPackagePath =
        path.join(getTestDataPath('extract_test'), 'mock_package');
    String fuchsiaRoot = path.normalize(path.joinAll(<String>[
      mockPackagePath,
      '..',
      '..',
      '..',
      '..',
      '..',
      '..',
    ]));

    String flutterRoot = path.normalize(
        path.join(fuchsiaRoot, 'third_party', 'dart-pkg', 'git', 'flutter'));

    // Run 'flutter packages get'
    await Process.run(
      path.join(flutterRoot, 'bin', 'flutter'),
      <String>['packages', 'get'],
      workingDirectory: mockPackagePath,
    );

    String packagePath = path.normalize(path.join(
      Directory.current.path,
      '..',
    ));

    // Temp output dir.
    Directory tempDir = await Directory.systemTemp.createTemp();
    String outputPath = tempDir.path;
    print('Temp dir: $outputPath');

    String pubPath = path.normalize(path.joinAll(<String>[
      fuchsiaRoot,
      'third_party',
      'dart',
      'tools',
      'sdks',
      Platform.isMacOS ? 'mac' : 'linux',
      'dart-sdk',
      'bin',
      'pub',
    ]));

    // Run pub get.
    ProcessResult result = await Process.run(
      pubPath,
      <String>['get'],
      workingDirectory: packagePath,
      environment: <String, String>{'FLUTTER_ROOT': flutterRoot},
    );

    // Print out the error messages before the assert fails.
    if (result.exitCode != 0) {
      print(result.stdout);
      print(result.stderr);
    }

    // Run the gen script.
    result = await Process.run(
      pubPath,
      <String>['run', 'widget_explorer_gen.dart', outputPath, mockPackagePath],
      workingDirectory: packagePath,
      environment: <String, String>{'FLUTTER_ROOT': flutterRoot},
    );

    // Print out the error messages before the assert fails.
    if (result.exitCode != 0) {
      print(result.stdout);
      print(result.stderr);
    }

    expect(result.exitCode, equals(0));

    List<String> createdFiles = new Directory(outputPath)
        .listSync()
        .map((FileSystemEntity entity) => path.basename(entity.path))
        .toList();

    expect(
        createdFiles,
        unorderedEquals(<String>[
          'index.dart',
          'widget01.dart',
          'widget03.dart',
          'no_comment_widget.dart',
          'config_key_widget.dart',
          'generator_widget.dart',
          'size_param_widget.dart',
        ]));

    // Verify the generated file contents.
    List<String> filesToVerify = <String>[
      'config_key_widget.dart',
      'generator_widget.dart',
      'size_param_widget.dart',
      'widget01.dart',
      'widget03.dart',
    ];

    for (String filename in filesToVerify) {
      expect(
        new File(path.join(outputPath, filename)).readAsStringSync(),
        new File(path.join(getTestDataPath('gen_test'), filename))
            .readAsStringSync(),
      );
    }
  });
}
