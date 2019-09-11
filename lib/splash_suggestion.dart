// Copyright 2016 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:math' as math;

import 'package:flutter/widgets.dart';
import 'package:sysui_widgets/rk4_spring_simulation.dart';

import 'selected_suggestion_overlay.dart';
import 'splash_painter.dart';
import 'suggestion.dart';
import 'suggestion_widget.dart';

const RK4SpringDescription _kSweepSimulationDesc =
    const RK4SpringDescription(tension: 100.0, friction: 50.0);
const double _kSweepSimulationTarget = 100.0;
const RK4SpringDescription _kClearSimulationDesc =
    const RK4SpringDescription(tension: 100.0, friction: 50.0);
const double _kClearSimulationTarget = 100.0;

/// Holds the [suggestion] in place while splashing the [suggestion]'s color
/// over the screen.  Once fully expanded a hole will open up from the center
/// of the [suggestion] revealing what's behind.
class SplashSuggestion extends ExpansionBehavior {
  /// The [Suggestion] which should be expanded to fill the parent.
  final Suggestion suggestion;

  /// The global bounds of the [suggestion]'s widget when the splash begins.
  final Rect suggestionInitialGlobalBounds;

  /// Called when the splash assoicated with [suggestion] completes.
  final OnSuggestionExpanded onSuggestionExpanded;

  RK4SpringSimulation _sweepSimulation;
  RK4SpringSimulation _clearSimulation;
  bool _notified = false;

  /// Constructor.
  SplashSuggestion({
    this.suggestion,
    this.suggestionInitialGlobalBounds,
    this.onSuggestionExpanded,
  });

  @override
  void start() {
    _notified = false;
    _sweepSimulation =
        new RK4SpringSimulation(initValue: 0.0, desc: _kSweepSimulationDesc);
    _sweepSimulation.target = _kSweepSimulationTarget;
    _clearSimulation =
        new RK4SpringSimulation(initValue: 0.0, desc: _kClearSimulationDesc);
    _clearSimulation.target = 0.0;
  }

  @override
  bool handleTick(double elapsedSeconds) {
    bool isDone = true;
    _clearSimulation.elapseTime(elapsedSeconds);
    if (!_clearIsDone) {
      isDone = false;
    }

    _sweepSimulation?.elapseTime(elapsedSeconds);
    if (!_sweepIsDone) {
      isDone = false;
    } else {
      // Notify that we've swept the screen.
      if (onSuggestionExpanded != null && !_notified) {
        onSuggestionExpanded(suggestion);
        _notified = true;
      }
      _clearSimulation.target = _kClearSimulationTarget;
    }

    return !isDone;
  }

  @override
  Widget build(BuildContext context, BoxConstraints constraints) {
    if (_clearIsDone) {
      return new Offstage(offstage: true);
    }

    RenderBox box = context.findRenderObject();
    Offset topLeft = box.localToGlobal(Offset.zero);
    Rect shiftedBounds = suggestionInitialGlobalBounds
        .shift(new Offset(-topLeft.dx, -topLeft.dy));
    double splashRadius = math.sqrt(
        (constraints.maxWidth / 2.0 * constraints.maxWidth / 2.0) +
            (constraints.maxHeight * constraints.maxHeight));
    return new Stack(
      fit: StackFit.passthrough,
      children: <Widget>[
        new Positioned(
          left: shiftedBounds.left,
          top: shiftedBounds.top,
          width: shiftedBounds.width,
          height: shiftedBounds.height,
          child: new Offstage(
            offstage: _sweepIsDone,
            child: new SuggestionWidget(suggestion: suggestion),
          ),
        ),
        new Positioned(
          left: 0.0,
          right: 0.0,
          top: 0.0,
          bottom: 0.0,
          child: new CustomPaint(
            painter: new SplashPainter(
              innerSplashProgress: _clearProgress,
              outerSplashProgress: _sweepProgress,
              splashOrigin: shiftedBounds.center,
              splashColor: suggestion.themeColor,
              splashRadius: splashRadius / 0.7,
            ),
          ),
        ),
      ],
    );
  }

  double get _sweepProgress =>
      (_sweepSimulation?.value ?? 1.0) / _kSweepSimulationTarget;

  double get _clearProgress =>
      (_clearSimulation?.value ?? 1.0) / _kClearSimulationTarget;

  bool get _clearIsDone => _clearProgress > 0.7;

  bool get _sweepIsDone => _sweepProgress > 0.7;
}
