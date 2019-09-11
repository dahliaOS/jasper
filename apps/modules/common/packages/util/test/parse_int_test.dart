// Copyright 2017 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:test/test.dart';
import 'package:util/parse_int.dart';

void main() {
  test('parseInt() should return integer if input is already an integer', () {
    expect(parseInt(6), 6);
  });
  test('parseInt() should return integer for valid string input', () {
    expect(parseInt('6'), 6);
  });
}
