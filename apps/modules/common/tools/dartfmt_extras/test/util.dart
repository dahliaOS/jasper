// Copyright 2017 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io';

import 'package:path/path.dart' as path;

/// Workaround for getting the test data path for the calling test script.
///
/// When running tests via 'flutter test', a temporary listener script is
/// created by the test runner, which includes the real test script.
///
/// See: https://github.com/dart-lang/test/issues/110
String getTestDataPath({String basename}) {
  String scriptPath = getTestScriptPath();

  basename ??= path.basenameWithoutExtension(scriptPath);

  return path.normalize(
    path.join(
      path.dirname(scriptPath),
      '..',
      '..',
      '..',
      'testdata',
      'dartfmt_extras',
      basename,
    ),
  );
}

/// Gets the test script path.
String getTestScriptPath() {
  String scriptPath = Platform.script.path;

  if (!scriptPath.endsWith('_test.dart')) {
    // This file is a test runner script. We assume that this test runner script
    // contains the following line:
    //
    //     import 'file://path_to_my_test/my_test.dart' as test;
    //
    String scriptContent = new File.fromUri(Platform.script).readAsStringSync();
    RegExp pattern = new RegExp(r"import 'file://(.+_test.dart)' as test;");
    Match match = pattern.firstMatch(scriptContent);
    if (match != null) {
      scriptPath = match.group(1);
    }
  }

  return scriptPath;
}
