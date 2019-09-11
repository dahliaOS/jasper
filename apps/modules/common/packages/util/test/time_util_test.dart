// Copyright 2016 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:test/test.dart';
import 'package:util/time_util.dart';

void main() {
  test('isSameDay() should return true if two times occur in the same day', () {
    DateTime time1 = DateTime.parse('1969-07-20 20:18:00');
    DateTime time2 = DateTime.parse('1969-07-20 06:18:00');
    expect(TimeUtil.isSameDay(time1, time2), true);
  });

  test('isSameDay() should return false if two times occur in different days',
      () {
    DateTime time1 = DateTime.parse('1969-07-20 20:18:00');
    DateTime time2 = DateTime.parse('1969-07-21 06:18:00');
    expect(TimeUtil.isSameDay(time1, time2), false);
  });

  test(
      'relativeDisplayDate() should return minutes/hour/period '
      'format if the date is the same day as the reference date', () {
    DateTime date = DateTime.parse('1969-07-20 20:18:00');
    DateTime referenceDate = DateTime.parse('1969-07-20 23:18:00');
    String displayDate = TimeUtil.relativeDisplayDate(
      date: date,
      relativeTo: referenceDate,
    );
    expect(displayDate, '8:18 PM');
  });

  test(
      'relativeDisplayDate() should return Month/Day '
      'format if the date is not same day as the reference date', () {
    DateTime date = DateTime.parse('1969-07-19 20:18:00');
    DateTime referenceDate = DateTime.parse('1969-07-20 23:18:00');
    String displayDate = TimeUtil.relativeDisplayDate(
      date: date,
      relativeTo: referenceDate,
    );
    expect(displayDate, 'Jul 19');
  });

  test(
      'relativeDisplayDate() should return Month/Day, minutes/hour/period '
      'format if the date is not same day as the reference date and the '
      'alwaysIncludeTime is set to true', () {
    DateTime date = DateTime.parse('1969-07-19 20:18:00');
    DateTime referenceDate = DateTime.parse('1969-07-20 23:18:00');
    String displayDate = TimeUtil.relativeDisplayDate(
      date: date,
      relativeTo: referenceDate,
      alwaysIncludeTime: true,
    );
    expect(displayDate, 'Jul 19, 8:18 PM');
  });
}
