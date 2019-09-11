// Copyright 2016 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:io';

import 'package:analyzer/analyzer.dart';
import 'package:dartfmt_extras/dartfmt_extras.dart';
import 'package:path/path.dart' as path;
import 'package:source_span/source_span.dart';

Future<Null> main(List<String> args) async {
  // Expect to get exactly one argument.
  if (args.length < 3) {
    stderr.writeln('Usage: pub run bin/main.dart '
        '<check|fix> <base_path> <list of dart files...>');
    exit(1);
  }

  // Command name check.
  if (!<String>['check', 'fix'].contains(args[0])) {
    stderr.writeln('The first argument should be either "check" or "fix".');
    exit(1);
  }
  Command cmd = args[0] == 'check' ? Command.check : Command.fix;

  bool error = false;
  String basePath = args[1];

  await Future.forEach(args.skip(2), (String relativePath) async {
    // Existence check.
    String fullPath = path.join(basePath, relativePath);
    File dartFile = new File(fullPath);
    if (!await dartFile.exists()) {
      stderr.writeln('The file ${args[0]} does not exist.');
      exit(1);
    }

    SourceFile src = new SourceFile(
      await dartFile.readAsString(),
      url: relativePath,
    );
    try {
      CompilationUnit cu = parseCompilationUnit(src.getText(0));
      error = await processDoubleQuotes(cmd, dartFile, src, cu) || error;
      error = await processDirectives(cmd, dartFile, src, cu) || error;
    } on AnalyzerErrorGroup catch (e) {
      stderr.writeln('Unable to parse file "$relativePath".');
      for (AnalyzerError e in e.errors) {
        stderr.writeln(e.toString());
      }
      exit(1);
    }
  });

  exitCode = error ? 1 : 0;
}
