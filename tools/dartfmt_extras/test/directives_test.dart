// Copyright 2017 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io';

import 'package:analyzer/analyzer.dart';
import 'package:dartfmt_extras/dartfmt_extras.dart';
import 'package:path/path.dart' as path;
import 'package:source_span/source_span.dart';
import 'package:test/test.dart';

import 'util.dart';

void main() {
  test('Import / Export directives should be re-ordered correctly.', () async {
    // Get the paths of the test data.
    String testDataPath = getTestDataPath('directives_test');

    String beforePath = path.join(testDataPath, 'before.dart');
    File beforeFile = new File(beforePath);

    String afterPath = path.join(testDataPath, 'after.dart');
    File afterFile = new File(afterPath);

    // Get a temporary directory, and copy the `before.dart` file there.
    Directory tempDir = await Directory.systemTemp.createTemp();
    String targetPath = path.join(tempDir.path, 'before.dart');
    await beforeFile.copy(targetPath);

    File targetFile = new File(targetPath);
    SourceFile src = new SourceFile.fromString(await targetFile.readAsString());
    CompilationUnit cu = parseCompilationUnit(src.getText(0));

    // Run the process function and compare the results.
    await processDirectives(Command.fix, targetFile, src, cu);
    expect(
      await targetFile.readAsString(),
      equals(await afterFile.readAsString()),
    );
  });
}
