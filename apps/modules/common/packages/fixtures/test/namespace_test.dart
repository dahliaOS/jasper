// Copyright 2016 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:fixtures/fixtures.dart';
import 'package:test/test.dart';

void main() {
  group('namespace(<string>)', () {
    test('only allows unique namespaces to be declared', () {
      String ns = namespace('foo');

      expect(ns, contains('foo'));
      expect(() => namespace('foo'), throwsA(new isInstanceOf<StateError>()));
    });
  });
}
