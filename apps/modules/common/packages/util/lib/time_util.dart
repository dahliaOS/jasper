// Copyright 2016 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:intl/intl.dart';

/// [TimeUtil] is a utility class that provides human-readable formating for
/// [DateTime] objects.
class TimeUtil {
  /// Return true if two given [DateTime] objects are within the same day
  ///
  /// Ex: isSameDay(DateTime.parse(1969-07-20 20:18:00), DateTime.parse(1969-07-20 21:18:00)) => True
  ///    isSameDay(DateTime.parse(1969-07-20 20:18:00), DateTime.parse(1969-07-21 21:18:00)) => False
  static bool isSameDay(DateTime time1, DateTime time2) {
    return time1.year == time2.year &&
        time1.month == time2.month &&
        time1.day == time2.day;
  }

  static final DateFormat _timeFormat = new DateFormat.jm();
  static final DateFormat _dateFormat = new DateFormat.MMMd();

  /// Relative user-readable display date
  ///
  /// Rules for Display Date:
  /// 1. Show minutes/hour/am-pm for timestamps in the same day.
  ///    Ex: 10:44 pm
  /// 2. Show month abbreviation + day for timestamps not in the same day.
  ///    Ex: Aug 15
  ///
  /// If [alwaysIncludeTime] is set to [true], the time information is also
  /// shown even when the timestamps are not in the same day.
  ///    Ex: Aut 15, 10:44pm
  static String relativeDisplayDate({
    /// The date to render
    DateTime date,

    /// The relative date (current time) to base the display date off of
    /// Defaults to DateTime.now()
    DateTime relativeTo,

    /// Indicates whether the time information should always be displayed.
    bool alwaysIncludeTime,
  }) {
    assert(date != null);
    if (relativeTo == null) {
      relativeTo = new DateTime.now();
    }
    if (TimeUtil.isSameDay(relativeTo, date)) {
      return _timeFormat.format(date);
    } else {
      String result = _dateFormat.format(date);
      if (alwaysIncludeTime ?? false) {
        result += ', ${_timeFormat.format(date)}';
      }
      return result;
    }
  }
}
