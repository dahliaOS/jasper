// Copyright 2016 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';

final DateFormat _kTimeOnlyDateFormat = new DateFormat('h:mm', 'en_US');
final DateFormat _kDateOnlyDateFormat = new DateFormat('EEEE MMM d', 'en_US');
final DateFormat _kShortStringDateFormat = new DateFormat('h:mm', 'en_US');
final DateFormat _kLongStringDateFormat = new DateFormat('EEEE h:mm', 'en_US');

/// Creates time strings and notifies when they change.
class TimeStringer extends Listenable {
  final Set<VoidCallback> _listeners = new Set<VoidCallback>();
  Timer _timer;

  /// [listener] will be called whenever [shortString] or [longString] have
  /// changed.
  @override
  void addListener(VoidCallback listener) {
    _listeners.add(listener);
    if (_listeners.length == 1) {
      _scheduleTimer();
    }
  }

  /// [listener] will no longer be called whenever [shortString] or [longString]
  /// have changed.
  @override
  void removeListener(VoidCallback listener) {
    _listeners.remove(listener);
    if (_listeners.length == 0) {
      _timer?.cancel();
      _timer = null;
    }
  }

  /// Returns the time only (eg. '10:34').
  String get timeOnly => _kTimeOnlyDateFormat
      .format(
        new DateTime.now().toLocal(),
      )
      .toUpperCase();

  /// Returns the date only (eg. 'MONDAY AUG 3').
  String get dateOnly => _kDateOnlyDateFormat
      .format(
        new DateTime.now().toLocal(),
      )
      .toUpperCase();

  /// Returns a short version of the time (eg. '10:34').
  String get shortString => _kShortStringDateFormat
      .format(new DateTime.now().toLocal())
      .toLowerCase();

  /// Returns a long version of the time including the day (eg. 'Monday 10:34').
  String get longString =>
      _kLongStringDateFormat.format(new DateTime.now().toLocal()).toLowerCase();

  void _scheduleTimer() {
    _timer?.cancel();
    _timer =
        new Timer(new Duration(seconds: 61 - new DateTime.now().second), () {
      _notifyListeners();
      _scheduleTimer();
    });
  }

  void _notifyListeners() {
    _listeners.toList().forEach((VoidCallback listener) => listener());
  }
}
