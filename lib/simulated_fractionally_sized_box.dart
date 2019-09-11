// Copyright 2016 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/widgets.dart';
import 'package:sysui_widgets/rk4_spring_simulation.dart';
import 'package:sysui_widgets/ticking_state.dart';

const RK4SpringDescription _kDefaultSimulationDesc =
    const RK4SpringDescription(tension: 450.0, friction: 50.0);

/// Animates a [FractionallySizedBox]'s [heightFactor] with a spring simulation.
class SimulatedFractionallySizedBox extends StatefulWidget {
  /// See [FractionallySizedBox.heightFactor].
  final double heightFactor;

  /// See [FractionallySizedBox.alignment].
  final FractionalOffset alignment;

  /// The description of the spring used to transition the box's size.
  final RK4SpringDescription springDescription;

  /// The widget to be sized by this box.
  final Widget child;

  /// Construuctor.
  SimulatedFractionallySizedBox({
    Key key,
    this.alignment,
    this.heightFactor,
    this.springDescription: _kDefaultSimulationDesc,
    this.child,
  })
      : super(key: key);

  @override
  SimulatedFractionallySizedBoxState createState() =>
      new SimulatedFractionallySizedBoxState();
}

/// Tracks the simulation of the [SimulatedFractionallySizedBox]'s size.
class SimulatedFractionallySizedBoxState
    extends TickingState<SimulatedFractionallySizedBox> {
  RK4SpringSimulation _heightFactorSimulation;

  @override
  void initState() {
    super.initState();
    _heightFactorSimulation = new RK4SpringSimulation(
      initValue: widget.heightFactor,
      desc: widget.springDescription,
    );
  }

  @override
  void didUpdateWidget(SimulatedFractionallySizedBox oldWidget) {
    super.didUpdateWidget(oldWidget);
    _heightFactorSimulation.target = widget.heightFactor;
    startTicking();
  }

  @override
  Widget build(BuildContext context) => new FractionallySizedBox(
        alignment: widget.alignment,
        heightFactor: _heightFactorSimulation.value,
        widthFactor: 1.0,
        child: widget.child,
      );

  @override
  bool handleTick(double elapsedSeconds) {
    _heightFactorSimulation.elapseTime(elapsedSeconds);
    return !_heightFactorSimulation.isDone;
  }

  /// Jumps the height of the box relative to its parent to [heightFactor].
  void jump({double heightFactor}) {
    _heightFactorSimulation = new RK4SpringSimulation(
      initValue: heightFactor,
      desc: widget.springDescription,
    );
  }
}
