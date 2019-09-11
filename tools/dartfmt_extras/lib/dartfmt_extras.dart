// Copyright 2017 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:io';

import 'package:analyzer/analyzer.dart';
import 'package:source_span/source_span.dart';

/// Commands supported in this util.
enum Command {
  /// Check the provided files and exit with 0 if they conform to the formatting
  /// guidelines. Exit with 1 otherwise.
  check,

  /// Fix the formatting issues.
  fix,
}

/// Check or fix the double quote issues.
Future<bool> processDoubleQuotes(
  Command cmd,
  File file,
  SourceFile src,
  CompilationUnit cu,
) async {
  _DoubleQuoteVisitor visitor = new _DoubleQuoteVisitor(src);
  cu.accept(visitor);

  if (visitor.invalidNodes.isEmpty) {
    return false;
  }

  switch (cmd) {
    case Command.check:
      reportDoubleQuotes(src, visitor.invalidNodes);
      return true;

    case Command.fix:
      await fixDoubleQuotes(file, src, visitor.invalidNodes);
      break;
  }

  return false;
}

/// Report double quote issues.
void reportDoubleQuotes(
    SourceFile src, List<SingleStringLiteral> invalidNodes) {
  for (SingleStringLiteral node in invalidNodes) {
    print('${src.url}:${src.getLine(node.offset)}: '
        'Prefer single quotes over double quotes: $node');
  }
}

/// Fix double quote issues.
Future<Null> fixDoubleQuotes(
  File file,
  SourceFile src,
  List<SingleStringLiteral> invalidNodes,
) async {
  // Get the original code as a String.
  String code = src.getText(0);

  // Replace the double quotes into single quotes.
  for (SingleStringLiteral node in invalidNodes) {
    int openingOffset = node.offset + (node.isRaw ? 1 : 0);
    code = code.replaceRange(
      openingOffset,
      openingOffset + (node.isMultiline ? 3 : 1),
      node.isMultiline ? "'''" : "'",
    );

    // NOTE: node.contentsEnd value cannot be used reliably, because it returns
    // an incorrect value when the string is a `StringInterpolation` and the
    // contents ends with an `InterpolationExpression`.
    int closingOffset = node.end - (node.isMultiline ? 3 : 1);
    code = code.replaceRange(
      closingOffset,
      closingOffset + (node.isMultiline ? 3 : 1),
      node.isMultiline ? "'''" : "'",
    );
  }

  // Overwrite the source file.
  await file.writeAsString(code);
}

class _DoubleQuoteVisitor extends GeneralizingAstVisitor<bool> {
  _DoubleQuoteVisitor(this.src);

  final SourceFile src;
  final List<SingleStringLiteral> invalidNodes = <SingleStringLiteral>[];

  @override
  bool visitSingleStringLiteral(SingleStringLiteral node) {
    super.visitSingleStringLiteral(node);

    if (!isValidSingleStringLiteral(node)) {
      invalidNodes.add(node);
    }

    return true;
  }

  bool isValidSingleStringLiteral(SingleStringLiteral node) {
    return node.isSingleQuoted ||
        src.getText(node.contentsOffset, node.contentsEnd).contains("'");
  }
}

/// Check or fix the ordering of import and export directives.
Future<bool> processDirectives(
  Command cmd,
  File file,
  SourceFile src,
  CompilationUnit cu,
) async {
  _DirectiveVisitor visitor = new _DirectiveVisitor(src);
  cu.accept(visitor);

  List<UriBasedDirective> directives = visitor.directives;
  if (directives.isEmpty) {
    return false;
  }

  directives.sort(
      (UriBasedDirective i1, UriBasedDirective i2) => i1.offset - i2.offset);

  // Start, end indices of the entire import block.
  int startIndex = directives.first.offset;
  int endIndex = directives.last.end;

  String actual = src.getText(startIndex, endIndex);
  String expected = _getOrderedDirectives(directives, src);

  if (actual == expected) {
    return false;
  }

  switch (cmd) {
    case Command.check:
      reportDirectives(src, startIndex, endIndex, actual, expected);
      return true;

    case Command.fix:
      await fixDirectives(file, src, startIndex, endIndex, expected);
      break;
  }

  return false;
}

/// Report import / export ordering issues.
void reportDirectives(
  SourceFile src,
  int startIndex,
  int endIndex,
  String actual,
  String expected,
) {
  print('${src.url}:${src.getLine(startIndex)}-${src.getLine(endIndex - 1)}: '
      'Order import directives properly.');
  print('== Actual ==');
  print(actual);
  print('== Expected ==');
  print(expected);
  print('==');
  print('');
}

/// Fix the import ordering issues.
Future<Null> fixDirectives(
  File file,
  SourceFile src,
  int startIndex,
  int endIndex,
  String expected,
) async {
  // Get the original code as a String.
  String code = src.getText(0);

  // Replace the import statements with the expected.
  code = code.replaceRange(startIndex, endIndex, expected);

  // Overwrite the source file.
  await file.writeAsString(code);
}

typedef _ConditionFn = bool Function(UriBasedDirective directive);

class _Condition<T extends UriBasedDirective> {
  final String prefix;
  _Condition(this.prefix);

  bool func(UriBasedDirective directive) {
    return directive is T && directive.uri.stringValue.startsWith(prefix);
  }
}

String _getOrderedDirectives(
  List<UriBasedDirective> directives,
  SourceFile src,
) {
  Set<UriBasedDirective> directiveSet = directives.toSet();

  List<_ConditionFn> conditions = <_ConditionFn>[
    new _Condition<ImportDirective>('dart:').func,
    new _Condition<ImportDirective>('package:').func,
    new _Condition<ImportDirective>('').func,
    new _Condition<ExportDirective>('package:').func,
    new _Condition<ExportDirective>('src/').func,
    new _Condition<ExportDirective>('').func,
  ];

  return conditions
      .map((_ConditionFn condition) {
        // Get the group of directives with the given condition prefix, and sort
        // them by their uri.
        List<UriBasedDirective> group = directiveSet.where(condition).toList()
          ..sort((UriBasedDirective i1, UriBasedDirective i2) =>
              i1.uri.stringValue.compareTo(i2.uri.stringValue));

        // Remove this group from the set to avoid any duplicates.
        directiveSet.removeAll(group);

        // Join the import directives with a newline character.
        // Use the text as appears in the original file, in order to respect the
        // formatting done by dartfmt.
        return group
            .map((UriBasedDirective directive) =>
                src.getText(directive.offset, directive.end))
            .join('\n');
      })
      // Remove any empty groups.
      .where((String s) => s.isNotEmpty)
      // There should be one empty line between two import groups.
      .join('\n\n');
}

class _DirectiveVisitor extends GeneralizingAstVisitor<bool> {
  _DirectiveVisitor(this.src);

  final SourceFile src;
  final List<UriBasedDirective> directives = <UriBasedDirective>[];

  @override
  bool visitImportDirective(ImportDirective node) {
    super.visitImportDirective(node);

    directives.add(node);
    return true;
  }

  @override
  bool visitExportDirective(ExportDirective node) {
    super.visitExportDirective(node);

    directives.add(node);
    return true;
  }
}
