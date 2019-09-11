// Copyright 2016 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/widgets.dart';
import 'package:sysui_widgets/rk4_spring_simulation.dart';
import 'package:sysui_widgets/ticking_state.dart';

/// Constants for the simulation.
const RK4SpringDescription _kSimulationDesc =
    const RK4SpringDescription(tension: 450.0, friction: 50.0);

/// Called each time the simulation ticks.
typedef void ProgressListener(double progress, bool isDone);

/// Called each time the simulation ticks to build a child for
/// [SimulationBuilder].
typedef Widget ProgressBuilder(BuildContext context, double progress);

/// Manages a simulation for the [Widget] built via [builder] allowing it to be
/// stateless.
class SimulationBuilder extends StatefulWidget {
  /// Called each time the simulation ticks.
  final ProgressListener onSimulationChanged;

  /// The initial simulation value.
  final double initValue;

  /// The target simulation value.
  final double targetValue;

  /// Builds the child for this [Widget] each time the simulation ticks.
  final ProgressBuilder builder;

  /// The description of the spring to do the simulation with.
  final RK4SpringDescription springDescription;

  /// Constructor.
  SimulationBuilder({
    Key key,
    this.onSimulationChanged,
    this.initValue: 0.0,
    this.targetValue: 0.0,
    this.springDescription: _kSimulationDesc,
    this.builder,
  })
      : super(key: key);

  @override
  SimulationBuilderState createState() => new SimulationBuilderState();
}

/// Holds the simulation state for [SimulationBuilder].
class SimulationBuilderState extends TickingState<SimulationBuilder> {
  RK4SpringSimulation _simulation;

  @override
  void initState() {
    super.initState();
    _simulation = new RK4SpringSimulation(
      initValue: widget.initValue,
      desc: widget.springDescription,
    );
    _simulation.target = widget.targetValue;
    startTicking();
  }

  @override
  void didUpdateWidget(SimulationBuilder oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.targetValue != widget.targetValue) {
      _simulation.target = widget.targetValue;
      startTicking();
    }
  }

  /// Jumps the simulation to [value].
  void jump(double value) {
    setState(() {
      _simulation = new RK4SpringSimulation(
        initValue: value,
        desc: widget.springDescription,
      );
    });
    widget.onSimulationChanged?.call(progress, _simulation.isDone);
  }

  /// Sets the new target for the simulation to [target].
  set target(double target) {
    if (_simulation.target != target) {
      _simulation.target = target;
      startTicking();
    }
  }

  /// THe current value of the simulation.
  double get progress => _simulation.value;

  @override
  bool handleTick(double elapsedSeconds) {
    bool wasDone = _simulation.isDone;
    if (wasDone) {
      return false;
    }

    // Tick the simulation.
    _simulation.elapseTime(elapsedSeconds);

    // Notify listeners of progress change.
    widget.onSimulationChanged?.call(progress, _simulation.isDone);

    return !_simulation.isDone;
  }

  @override
  Widget build(BuildContext context) => widget.builder(context, progress);
}
