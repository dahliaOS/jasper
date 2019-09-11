// Copyright 2017 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:math' as math;

/// Tunable parameters for how fast scrolling should occur as the user drags
/// a story cluster toward the top or bottom edges of the screen.
const double _kA = 1.0;
const double _kB = 0.5;
const double _kC = 1.5;
const double _kD = 0.02;
const double _kE = 2.0;
const double _kTh1Multiplier = 120.0 / 900.0;
const double _kTh2Multiplier = 40.0 / 900.0;

/// Manages the state of Kenichi's algorithm for a scrolling animation that
/// should occur when a user drags a story cluster toward the top or bottom
/// edges of the screen.
class KenichiEdgeScrolling {
  double _velocity = 0.0;
  double _screenH = 2.0 * 120.0;
  double _currentY = 120.0;

  /// [newY] is the y position of the finger on the screen.
  /// [screenH] the height of the screen.
  void update(double newY, double screenH) {
    _currentY = newY;
    _screenH = screenH;
  }

  /// Resets [_currentY] to a reasonable value for the algorithm.
  void onNoDrag() {
    _currentY = _screenH / 2.0;
  }

  /// [time] is elapsed time in seconds.
  /// Returns the distance to scroll.
  double getScrollDelta(double time) {
    // If we should scroll up, accelerate upward.
    if (shouldScrollUp) {
      double r = _smoothstep(_currentY);
      _velocity += math.pow(r, _kA) * _kB * time * 60;
    }

    // If we should scroll down, accelerate downward.
    if (shouldScrollDown) {
      double r = _smoothstep(_screenH - _currentY);
      _velocity -= math.pow(r, _kA) * _kB * time * 60;
    }

    // Apply friction.
    double friction;
    if (_currentY < _screenH / 2) {
      friction =
          math.pow(math.max(0.0, _currentY) / _startScrollDeltaY, _kC) * _kD;
    } else {
      friction = math.pow(
              math.max(0.0, (_screenH - _currentY)) / _startScrollDeltaY, _kC) *
          _kD;
    }
    _velocity -= _velocity * friction * time * 60;

    // Once we drop below a certian threshold, jump to 0.0.
    if (_velocity.abs() < 0.1) {
      _velocity = 0.0;
    }

    return _velocity * time * 60;
  }

  /// Returns true if the current position indicates scrolling up should happen.
  bool get shouldScrollUp => _currentY < _startScrollDeltaY;

  /// Returns true if the current position indicates scrolling down should
  /// happen.
  bool get shouldScrollDown => _currentY > _screenH - _startScrollDeltaY;

  /// Returns true no scrolling should happen and the current velocity is zero.
  bool get isDone => !shouldScrollUp && !shouldScrollDown && _velocity == 0.0;

  /// Returns the delta y from the top or bottom edge at which scrolling should
  /// start.
  double get _startScrollDeltaY => _kTh1Multiplier * _screenH;

  /// Returns the delta y from the top or bottom edge at which scrolling should
  /// increase in velocity.
  double get _increaseScrollDeltaY => _kTh2Multiplier * _screenH;

  double _smoothstep(double deltaYFromEdge) {
    double t = (deltaYFromEdge - _startScrollDeltaY) /
            (_increaseScrollDeltaY - _startScrollDeltaY) *
            12 -
        6;
    return 1 / (1 + math.pow(math.e, -t));
  }
}
