// Copyright 2016 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:io';

import 'package:analyzer/analyzer.dart';
import 'package:analyzer/src/dart/scanner/reader.dart';
import 'package:analyzer/src/dart/scanner/scanner.dart';
import 'package:analyzer/src/generated/parser.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:analyzer/src/string_source.dart';
import 'package:dartfmt_extras/dartfmt_extras.dart';
import 'package:front_end/src/scanner/token.dart';
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
    if (!dartFile.existsSync()) {
      stderr.writeln('The file ${args[0]} does not exist.');
      exit(1);
    }

    SourceFile src = new SourceFile.fromString(
      await dartFile.readAsString(),
      url: relativePath,
    );
    try {
      CompilationUnit cu = _parseCompilationUnit(src.getText(0), relativePath);
      error = await processDoubleQuotes(cmd, dartFile, src, cu) || error;
      error = await processDirectives(cmd, dartFile, src, cu) || error;
    } on AnalyzerErrorGroup catch (e) {
      stderr.writeln('Unable to parse file "$relativePath".');
      for (AnalyzerError ae in e.errors) {
        int line = src.getLine(ae.error.offset);
        int col = src.getColumn(ae.error.offset);
        stderr.writeln('[$line, $col] ${ae.error.message}');
      }
      exit(1);
    }
  });

  exitCode = error ? 1 : 0;
}

/// Parse the compilation unit with the assert initializer feature enabled.
CompilationUnit _parseCompilationUnit(String contents, String name) {
  Source source = new StringSource(contents, name);
  CharSequenceReader reader = new CharSequenceReader(contents);
  _ErrorCollector errorCollector = new _ErrorCollector();
  Scanner scanner = new Scanner(source, reader, errorCollector);
  Token token = scanner.tokenize();
  Parser parser = new Parser(source, errorCollector)
    ..parseFunctionBodies = true;
  CompilationUnit unit = parser.parseCompilationUnit(token)
    ..lineInfo = new LineInfo(scanner.lineStarts);

  if (errorCollector.hasErrors) {
    throw errorCollector.group;
  }

  return unit;
}

/// A simple error listener that collects errors into an [AnalyzerErrorGroup].
class _ErrorCollector extends AnalysisErrorListener {
  final List<AnalysisError> _errors = <AnalysisError>[];

  _ErrorCollector();

  /// The group of errors collected.
  AnalyzerErrorGroup get group =>
      new AnalyzerErrorGroup.fromAnalysisErrors(_errors);

  bool get hasErrors => _errors.isNotEmpty;

  @override
  void onError(AnalysisError error) => _errors.add(error);
}
