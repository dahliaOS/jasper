// Copyright 2016 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:math' as math;

import 'package:armadillo/panel.dart';
import 'package:flutter/widgets.dart';
import 'package:test/test.dart';

void main() {
  test('split horizontally', () {
    new Panel.fromLTRB(0.0, 0.0, 0.5, 1.0).split((Panel a, Panel b) {
      expect(a.sizeFactor, 0.25);
      expect(b.sizeFactor, 0.25);
      expect(a.left, 0.0);
      expect(a.top, 0.0);
      expect(a.height, 0.5);
      expect(a.width, 0.5);
      expect(b.left, 0.0);
      expect(b.top, 0.5);
      expect(b.height, 0.5);
      expect(b.width, 0.5);
    });
  });
  test('split vertically', () {
    new Panel.fromLTRB(0.0, 0.0, 1.0, 0.5).split((Panel a, Panel b) {
      expect(a.sizeFactor, 0.25);
      expect(b.sizeFactor, 0.25);
      expect(a.left, 0.0);
      expect(a.top, 0.0);
      expect(a.height, 0.5);
      expect(a.width, 0.5);
      expect(b.left, 0.5);
      expect(b.top, 0.0);
      expect(b.height, 0.5);
      expect(b.width, 0.5);
    });
  });
  test('absorb - full absorbtion', () {
    Panel a = new Panel.fromLTRB(0.0, 0.0, 0.5, 0.5);
    Panel b = new Panel.fromLTRB(0.5, 0.0, 1.0, 0.5);
    a.absorb(b, (Panel result, Panel remainder) {
      expect(remainder.sizeFactor, 0.0);
      expect(result.sizeFactor, 0.5);
      expect(result.left, 0.0);
      expect(result.top, 0.0);
      expect(result.height, 0.5);
      expect(result.width, 1.0);
    });
  });
  test('absorb - partial absorbtion', () {
    Panel a = new Panel.fromLTRB(0.5, 0.0, 1.0, 0.5);
    Panel b = new Panel.fromLTRB(0.0, 0.0, 0.5, 1.0);
    a.absorb(b, (Panel result, Panel remainder) {
      expect(remainder.sizeFactor, 0.25);
      expect(remainder.left, 0.0);
      expect(remainder.top, 0.5);
      expect(remainder.height, 0.5);
      expect(remainder.width, 0.5);
      expect(result.sizeFactor, 0.5);
      expect(result.left, 0.0);
      expect(result.top, 0.0);
      expect(result.height, 0.5);
      expect(result.width, 1.0);
    });
  });
  test('absorb - no absorbtion', () {
    Panel a = new Panel.fromLTRB(0.5, 0.0, 1.0, 0.5);
    Panel b = new Panel.fromLTRB(0.0, 0.0, 0.4, 1.0);
    a.absorb(b, (Panel result, Panel remainder) {
      expect(remainder, equals(b));
      expect(result, equals(a));
    });
  });
  test('maxRows', () {
    expect(maxRows(new Size(0.0, 0.0)), 1);
    expect(maxRows(new Size(1600.0, 900.0)), 2);
    expect(maxRows(new Size(1600.0, 450.0)), 1);
    expect(maxRows(new Size(1600.0, 9000.0)), 3);
    expect(maxRows(new Size(16000.0, 9000.0)), 2);
  });
  test('maxColumns', () {
    expect(maxColumns(new Size(0.0, 0.0)), 1);
    expect(maxColumns(new Size(1600.0, 900.0)), 3);
    expect(maxColumns(new Size(800.0, 600.0)), 2);
    expect(maxColumns(new Size(1600.0, 9000.0)), 2);
    expect(maxColumns(new Size(16000.0, 9000.0)), 3);
  });
  test('toGridValue', () {
    expect(toGridValue(1.0), 1.0);
    expect(toGridValue(0.567), 0.567);
    expect(toGridValue(0.56734566645), 0.5673);
    expect(toGridValue(0.7899988866), 0.790);
    expect(toGridValue(0.0), 0.0);
  });
  test('canBeSplitVertically and smallestWidthFactor', () {
    Size size = new Size(1000.0, 1000.0);
    double smallest = smallestWidthFactor(size.width);

    expect(
      new Panel.fromLTRB(0.0, 0.0, 1.0, 1.0).canBeSplitVertically(size.width),
      isTrue,
    );
    expect(
      new Panel.fromLTRB(0.0, 0.0, smallest * 2.0, 1.0)
          .canBeSplitVertically(size.width),
      isTrue,
    );
    expect(
      new Panel.fromLTRB(0.0, 0.0, (smallest * 2.0) - 0.001, 1.0)
          .canBeSplitVertically(size.width),
      isFalse,
    );
  });
  test('canBeSplitHorizontally and smallestHeightFactor', () {
    Size size = new Size(1000.0, 1000.0);
    double smallest = smallestHeightFactor(size.width);

    expect(
      new Panel.fromLTRB(0.0, 0.0, 1.0, 1.0)
          .canBeSplitHorizontally(size.height),
      isTrue,
    );
    expect(
      new Panel.fromLTRB(0.0, 0.0, 1.0, smallest * 2.0)
          .canBeSplitHorizontally(size.height),
      isTrue,
    );
    expect(
      new Panel.fromLTRB(0.0, 0.0, 1.0, (smallest * 2.0) - 0.001)
          .canBeSplitHorizontally(size.height),
      isFalse,
    );
  });
  test('isOriginAligned returns true when origin aligned', () {
    Panel a = new Panel.fromLTRB(0.25, 0.25, 0.75, 0.75);
    Panel b = new Panel.fromLTRB(0.25, 0.25, 0.25, 1.0);
    Panel c = new Panel.fromLTRB(0.75, 0.25, 1.0, 1.0);
    Panel d = new Panel.fromLTRB(0.0, 0.25, 0.5, 0.25);
    Panel e = new Panel.fromLTRB(0.25, 0.0, 1.0, 0.25);

    expect(a.isOriginAligned(b), isTrue);
    expect(a.isOriginAligned(c), isTrue);
    expect(a.isOriginAligned(d), isTrue);
    expect(a.isOriginAligned(e), isTrue);
    expect(b.isOriginAligned(a), isTrue);
    expect(c.isOriginAligned(a), isTrue);
    expect(d.isOriginAligned(a), isTrue);
    expect(e.isOriginAligned(a), isTrue);
  });
  test('isOriginAligned returns false when not origin aligned', () {
    Panel a = new Panel.fromLTRB(0.3, 0.3, 1.0, 1.0);
    Panel b = new Panel.fromLTRB(0.0, 0.0, 0.25, 1.0);
    Panel c = new Panel.fromLTRB(0.75, 0.0, 1.0, 1.0);
    Panel d = new Panel.fromLTRB(0.0, 0.0, 0.5, 0.25);
    Panel e = new Panel.fromLTRB(0.5, 0.0, 1.0, 0.25);

    expect(a.isOriginAligned(b), isFalse);
    expect(a.isOriginAligned(c), isFalse);
    expect(a.isOriginAligned(d), isFalse);
    expect(a.isOriginAligned(e), isFalse);
    expect(b.isOriginAligned(a), isFalse);
    expect(c.isOriginAligned(a), isFalse);
    expect(d.isOriginAligned(a), isFalse);
    expect(e.isOriginAligned(a), isFalse);
  });
  test(
    'isAdjacentWithOriginAligned returns true when adjacent with origin aligned',
    () {
      Panel a = new Panel.fromLTRB(0.25, 0.25, 0.75, 0.75);
      Panel b = new Panel.fromLTRB(0.0, 0.25, 0.25, 1.0);
      Panel c = new Panel.fromLTRB(0.75, 0.25, 1.0, 1.0);
      Panel d = new Panel.fromLTRB(0.25, 0.0, 0.5, 0.25);
      Panel e = new Panel.fromLTRB(0.25, 0.0, 1.0, 0.25);

      expect(a.isAdjacentWithOriginAligned(b), isTrue);
      expect(a.isAdjacentWithOriginAligned(c), isTrue);
      expect(a.isAdjacentWithOriginAligned(d), isTrue);
      expect(a.isAdjacentWithOriginAligned(e), isTrue);
      expect(b.isAdjacentWithOriginAligned(a), isTrue);
      expect(c.isAdjacentWithOriginAligned(a), isTrue);
      expect(d.isAdjacentWithOriginAligned(a), isTrue);
      expect(e.isAdjacentWithOriginAligned(a), isTrue);
    },
  );
  test(
    'isAdjacentWithOriginAligned returns false when not adjacent with origin aligned',
    () {
      Panel a = new Panel.fromLTRB(0.25, 0.25, 1.0, 1.0);
      Panel b = new Panel.fromLTRB(0.25, 0.0, 0.35, 0.15);
      Panel c = new Panel.fromLTRB(0.75, 0.25, 1.0, 1.0);
      Panel d = new Panel.fromLTRB(0.0, 0.25, 0.1, 0.5);
      Panel e = new Panel.fromLTRB(0.25, 0.0, 1.0, 0.15);

      expect(a.isAdjacentWithOriginAligned(b), isFalse);
      expect(a.isAdjacentWithOriginAligned(c), isFalse);
      expect(a.isAdjacentWithOriginAligned(d), isFalse);
      expect(a.isAdjacentWithOriginAligned(e), isFalse);
      expect(b.isAdjacentWithOriginAligned(a), isFalse);
      expect(c.isAdjacentWithOriginAligned(a), isFalse);
      expect(d.isAdjacentWithOriginAligned(a), isFalse);
      expect(e.isAdjacentWithOriginAligned(a), isFalse);
    },
  );
  test('getSpanSpan returns proper values for single span', () {
    expect(getSpanSpan(1.0, 0, 1), 1.0);
  });
  test('getSpanSpan returns proper values for double span', () {
    expect(getSpanSpan(1.0, 0, 2), 0.5);
    expect(getSpanSpan(1.0, 1, 2), 0.5);
  });
  test('getSpanSpan returns proper values for triple span', () {
    expect(getSpanSpan(1.0, 0, 3), 0.3334);
    expect(getSpanSpan(1.0, 1, 3), 0.3333);
    expect(getSpanSpan(1.0, 2, 3), 0.3333);
  });
  test('getSpanSpan returns proper values for 4 span', () {
    expect(getSpanSpan(1.0, 0, 4), 0.25);
    expect(getSpanSpan(1.0, 1, 4), 0.25);
    expect(getSpanSpan(1.0, 2, 4), 0.25);
    expect(getSpanSpan(1.0, 3, 4), 0.25);
  });
  test('getSpanSpan returns proper values for 5 span', () {
    expect(getSpanSpan(1.0, 0, 5), 0.2);
    expect(getSpanSpan(1.0, 1, 5), 0.2);
    expect(getSpanSpan(1.0, 2, 5), 0.2);
    expect(getSpanSpan(1.0, 3, 5), 0.2);
    expect(getSpanSpan(1.0, 4, 5), 0.2);
  });
  test('getSpanSpan returns proper values for 6 span', () {
    expect(getSpanSpan(1.0, 0, 6), 0.1666);
    expect(getSpanSpan(1.0, 1, 6), 0.1666);
    expect(getSpanSpan(1.0, 2, 6), 0.1667);
    expect(getSpanSpan(1.0, 3, 6), 0.1667);
    expect(getSpanSpan(1.0, 4, 6), 0.1667);
    expect(getSpanSpan(1.0, 5, 6), 0.1667);
  });
  test('getSpanSpan returns proper values for 7 span', () {
    expect(getSpanSpan(1.0, 0, 7), 0.1428);
    expect(getSpanSpan(1.0, 1, 7), 0.1428);
    expect(getSpanSpan(1.0, 2, 7), 0.1428);
    expect(getSpanSpan(1.0, 3, 7), 0.1429);
    expect(getSpanSpan(1.0, 4, 7), 0.1429);
    expect(getSpanSpan(1.0, 5, 7), 0.1429);
    expect(getSpanSpan(1.0, 6, 7), 0.1429);
  });
  test('getSpanSpan returns proper values for 8 span', () {
    expect(getSpanSpan(1.0, 0, 8), 0.125);
    expect(getSpanSpan(1.0, 1, 8), 0.125);
    expect(getSpanSpan(1.0, 2, 8), 0.125);
    expect(getSpanSpan(1.0, 3, 8), 0.125);
    expect(getSpanSpan(1.0, 4, 8), 0.125);
    expect(getSpanSpan(1.0, 5, 8), 0.125);
    expect(getSpanSpan(1.0, 6, 8), 0.125);
    expect(getSpanSpan(1.0, 7, 8), 0.125);
  });
  test('getSpanSpan returns proper values for 9 span', () {
    expect(getSpanSpan(1.0, 0, 9), 0.1112);
    expect(getSpanSpan(1.0, 1, 9), 0.1111);
    expect(getSpanSpan(1.0, 2, 9), 0.1111);
    expect(getSpanSpan(1.0, 3, 9), 0.1111);
    expect(getSpanSpan(1.0, 4, 9), 0.1111);
    expect(getSpanSpan(1.0, 5, 9), 0.1111);
    expect(getSpanSpan(1.0, 8, 9), 0.1111);
    expect(getSpanSpan(1.0, 6, 9), 0.1111);
    expect(getSpanSpan(1.0, 7, 9), 0.1111);
  });
  test('getSpanSpan returns proper values for 10 span', () {
    expect(getSpanSpan(1.0, 0, 10), 0.1);
    expect(getSpanSpan(1.0, 1, 10), 0.1);
    expect(getSpanSpan(1.0, 2, 10), 0.1);
    expect(getSpanSpan(1.0, 3, 10), 0.1);
    expect(getSpanSpan(1.0, 4, 10), 0.1);
    expect(getSpanSpan(1.0, 5, 10), 0.1);
    expect(getSpanSpan(1.0, 6, 10), 0.1);
    expect(getSpanSpan(1.0, 7, 10), 0.1);
    expect(getSpanSpan(1.0, 8, 10), 0.1);
    expect(getSpanSpan(1.0, 9, 10), 0.1);
  });
  test('getSpanSpan returns proper values for more spans', () {
    for (int spans = 1; spans <= 1000; spans++) {
      double minSpan = 1.0;
      double maxSpan = 0.0;
      double spanSum = 0.0;
      for (int i = 0; i < spans; i++) {
        double span = getSpanSpan(1.0, i, spans);
        minSpan = math.min(minSpan, span);
        maxSpan = math.max(maxSpan, span);
        spanSum = toGridValue(spanSum + span);
      }
      expect(toGridValue(maxSpan - minSpan), greaterThanOrEqualTo(0.000));
      expect(toGridValue(maxSpan - minSpan), lessThanOrEqualTo(0.001));
      expect(spanSum, 1.0);
    }
  });
}
