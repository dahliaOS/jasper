// Copyright 2017 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:lib.widgets/model.dart';
import 'package:sysui_widgets/rk4_spring_simulation.dart';

import 'story_cluster_drag_state_model.dart';
import 'ticking_model.dart';

export 'package:lib.widgets/model.dart'
    show ScopedModel, Model, ScopedModelDescendant;

const RK4SpringDescription _kSimulationDesc =
    const RK4SpringDescription(tension: 750.0, friction: 50.0);

/// Base class for [Model]s that depend on a Ticker.
class StoryRearrangementScrimModel extends TickingModel {
  final RK4SpringSimulation _opacitySimulation = new RK4SpringSimulation(
    initValue: 0.0,
    desc: _kSimulationDesc,
  );

  /// Starts the simulation of this [TickingModel].  If [isAcceptable] is true
  /// the opacity will be animated to non-transparent otherwise it will be
  /// animated to fully transparent.
  void onDragAcceptableStateChanged(bool isAcceptable) {
    _opacitySimulation.target = isAcceptable ? 0.6 : 0.0;
    startTicking();
  }

  /// The current color the story rearrangement scrim should be.
  Color get scrimColor => Colors.black.withOpacity(_opacitySimulation.value);

  /// The progress of the story rearrangement scrim animation.
  double get progress => _opacitySimulation.value / 0.6;

  @override
  bool handleTick(double elapsedSeconds) {
    _opacitySimulation.elapseTime(elapsedSeconds);
    return !_opacitySimulation.isDone;
  }
}
