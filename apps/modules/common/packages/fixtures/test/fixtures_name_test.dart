// Copyright 2016 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:fixtures/fixtures.dart';
import 'package:test/test.dart';

const int _kNameThreshold = 1000;

void main() {
  Fixtures fixtures;

  setUp(() {
    fixtures = new Fixtures();
  });

  group('fixtures.name()', () {
    test('generates random names.', () {
      String first = fixtures.name();
      String second = fixtures.name();

      expect(first, isNot(second),
          reason: 'Generated names should not be the same.');
    });

    test('can generate up to $_kNameThreshold unique names', () {
      Fixtures fixtures = new Fixtures(nameThreshold: _kNameThreshold);
      Set<String> names = new Set<String>();

      for (int i = 0; i < fixtures.nameThreshold; i++) {
        String name = fixtures.name();

        if (!names.add(name)) {
          fail('Non unique name $name generated at index $i');
        }
      }
    });

    test('create a specific name', () {
      String value = 'Jason Campbell';
      String jason = fixtures.name(value);

      expect('$jason', equals(value));
    });

    test('threshold limit on unique Names', () {
      Fixtures fixtures = new Fixtures(nameThreshold: 1);
      String name = fixtures.name();

      expect(() => fixtures.name(), throwsA(new isInstanceOf<FixturesError>()));
      expect(() => fixtures.name(), throwsA(new isInstanceOf<FixturesError>()),
          reason: 'should fail on subsequent calls');
      expect(fixtures.name(name), name,
          reason: 'allows generating a previously defined name');
    });
  });
}
