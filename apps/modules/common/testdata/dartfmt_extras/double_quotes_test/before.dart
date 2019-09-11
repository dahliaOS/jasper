// Copyright 2017 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

void foo() {
  print("This should be fixed to single quotes.");
  print('This should be kept unchanged.');
  print("A double-quoted string containing 'single quotes' should be allowed.");

  print("");

  String bar = '{}';
  print("Interpolated string $bar");
  print("""Another interpolated string $baz""");
}

const String multiline1 = """
This should also be fixed to triple single-quotes.
""";

const String multiline2 = """
But this should not be,
because it has triple single quotes in the contents.'''
""";

const String multiline3 = '''
This should not be changed.
''';
