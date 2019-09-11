// Copyright 2016 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// A script for reading an lcov file and printing out the coverage information
// to the console, in a human-friendly table format.

import 'dart:async';
import 'dart:collection';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

Future<Null> main(List<String> args) async {
  // Expect to get exactly one argument.
  if (args.length != 1) {
    stderr.writeln('Usage: dart report_coverage.dart <path_to_lcov_info>');
    exit(1);
  }

  // Existence check.
  File reportFile = new File(args[0]);
  if (!await reportFile.exists()) {
    stderr.writeln('The file ${args[0]} does not exist.');
    exit(1);
  }

  // Process line by line.
  String currentFile;
  Set<String> files = new SplayTreeSet<String>();
  Map<String, int> totalLines = new HashMap<String, int>();
  Map<String, int> coveredLines = new HashMap<String, int>();

  await reportFile
      .openRead()
      .transform(utf8.decoder)
      .transform(const LineSplitter())
      .listen((String line) {
    if (line.startsWith('SF:')) {
      // Process a new source file.
      assert(currentFile == null);
      currentFile = line.substring(3);
      files.add(currentFile);
      totalLines[currentFile] = 0;
      coveredLines[currentFile] = 0;
    } else if (line.startsWith('DA:')) {
      // Add this line info to the map.
      List<String> tokens = line.substring(3).split(',');
      assert(tokens.length == 2);
      totalLines[currentFile]++;
      coveredLines[currentFile] += int.parse(tokens[1]) > 0 ? 1 : 0;
    } else if (line == 'end_of_record') {
      currentFile = null;
    } else {
      stderr.writeln('Unknown directive: $line');
      exit(1);
    }
  }).asFuture();

  // Report to console.
  TableWriter writer = new TableWriter(stdout)
    ..setHeaders(<Object>['Filepath', 'Covered', 'Total', 'Percentage'])
    ..setRightAlignment(<bool>[false, true, true, true]);
  for (String file in files) {
    writer.addRow(<Object>[
      file,
      coveredLines[file],
      totalLines[file],
      '${_getPercentage(coveredLines[file], totalLines[file])}%',
    ]);
  }

  // Last line for total.
  int totalCoveredLines = coveredLines.values.fold(0, (int a, int b) => a + b);
  int totalTotalLines = totalLines.values.fold(0, (int a, int b) => a + b);
  writer
    ..setFooters(<Object>[
      'Total',
      totalCoveredLines,
      totalTotalLines,
      '${_getPercentage(totalCoveredLines, totalTotalLines)}%',
    ])
    ..render();
}

double _getPercentage(int covered, int total) {
  return (covered * 1000 / total).roundToDouble() / 10;
}

/// A utility class for pretty-printing the data
class TableWriter {
  /// Creates a new [TableWriter] instance with the specified output target.
  TableWriter(Stdout out) : _out = out;

  final Stdout _out;
  final List<int> _colLen = <int>[];
  final List<List<String>> _rows = <List<String>>[];
  List<String> _headers;
  List<String> _footers;
  List<bool> _rightAlignments;

  /// Sets the header strings.
  void setHeaders(List<Object> headers) {
    assert(_headers == null);
    _headers = _processRow(headers);
  }

  /// Sets the footer strings.
  void setFooters(List<Object> footers) {
    assert(_footers == null);
    _footers = _processRow(footers);
  }

  // ignore: use_setters_to_change_properties
  /// Sets whether each column needs to be right aligned.
  void setRightAlignment(List<bool> rightAlignments) {
    _rightAlignments = rightAlignments;
  }

  /// Adds a new data row.
  void addRow(List<Object> row) {
    _rows.add(_processRow(row));
  }

  /// Render the table to the target provided to the constructor.
  void render() {
    if (_headers != null) {
      _renderRow(_headers);
      _renderSeparationLine();
    }

    _rows.forEach(_renderRow);

    if (_footers != null) {
      _renderSeparationLine();
      _renderRow(_footers);
    }
  }

  List<String> _processRow(List<Object> row) {
    while (row.length > _colLen.length) {
      _colLen.add(0);
    }

    List<String> stringRow = row.map((Object x) => x.toString()).toList();
    for (int i = 0; i < stringRow.length; ++i) {
      _colLen[i] = max(_colLen[i], stringRow[i].length);
    }

    return stringRow;
  }

  void _renderRow(List<String> row) {
    for (int i = 0; i < row.length; ++i) {
      if (i > 0) {
        _out.write(' ');
      }

      if (_shouldBeRightAligned(i)) {
        _out..write(' ' * (_colLen[i] - row[i].length))..write(row[i]);
      } else {
        _out..write(row[i])..write(' ' * (_colLen[i] - row[i].length));
      }
    }
    _out.writeln();
  }

  void _renderSeparationLine() {
    int count = _colLen.fold(_colLen.length - 1, (int x, int y) => x + y);
    _out.writeln('=' * count);
  }

  bool _shouldBeRightAligned(int colIndex) {
    if (_rightAlignments != null && colIndex < _rightAlignments.length) {
      return _rightAlignments[colIndex];
    }

    return false;
  }
}
