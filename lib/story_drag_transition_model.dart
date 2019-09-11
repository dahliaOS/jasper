// Copyright 2017 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:sysui_widgets/rk4_spring_simulation.dart';

import 'ticking_model.dart';

export 'package:lib.widgets/model.dart'
    show ScopedModel, Model, ScopedModelDescendant;

const RK4SpringDescription _kSimulationDesc =
    const RK4SpringDescription(tension: 750.0, friction: 50.0);

/// Acts as the coordinating animation for all the transitions that take place
/// when story clusters are being dragged.  These include:
/// 1) Fading out Now.
/// 2) Fading all Story Titles slightly.
/// 3) Increasing the size and bottom padding of the Story List.
class StoryDragTransitionModel extends TickingModel {
  final RK4SpringSimulation _transitionSimulation = new RK4SpringSimulation(
    initValue: 0.0,
    desc: _kSimulationDesc,
  );

  /// Sets the dragging state to [isDragging].  This triggers the transition
  /// animation.
  void onDragStateChanged(bool isDragging) {
    _transitionSimulation.target = isDragging ? 1.0 : 0.0;
    startTicking();
  }

  /// The progress of the story drag transition animation.
  double get progress => _transitionSimulation.value;

  @override
  bool handleTick(double elapsedSeconds) {
    _transitionSimulation.elapseTime(elapsedSeconds);
    return !_transitionSimulation.isDone;
  }
}
