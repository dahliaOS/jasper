// Copyright 2016 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/widgets.dart';
import 'package:sysui_widgets/rk4_spring_simulation.dart';
import 'package:sysui_widgets/ticking_state.dart';

const RK4SpringDescription _kDefaultSimulationDesc =
    const RK4SpringDescription(tension: 750.0, friction: 50.0);

/// Animates a [SizedBox]'s [width] and [height] with a
/// spring simulation.
class SimulatedSizedBox extends StatefulWidget {
  /// The target width of the box.
  final double width;

  /// The target height of the box.
  final double height;

  /// The description of th espring to use for width and height transitions.
  final RK4SpringDescription springDescription;

  /// What's inside the box.
  final Widget child;

  /// Constructor.
  SimulatedSizedBox({
    Key key,
    this.width,
    this.height,
    this.springDescription: _kDefaultSimulationDesc,
    this.child,
  }) : super(key: key);

  @override
  SimulatedSizedBoxState createState() => new SimulatedSizedBoxState();
}

/// Holds the width and height transition simulations for [SimulatedSizedBox].
class SimulatedSizedBoxState extends TickingState<SimulatedSizedBox> {
  RK4SpringSimulation _widthSimulation;
  RK4SpringSimulation _heightSimulation;

  @override
  void initState() {
    super.initState();
    _widthSimulation = new RK4SpringSimulation(
      initValue: widget.width,
      desc: widget.springDescription,
    );
    _heightSimulation = new RK4SpringSimulation(
      initValue: widget.height,
      desc: widget.springDescription,
    );
  }

  @override
  void didUpdateWidget(SimulatedSizedBox oldWidget) {
    super.didUpdateWidget(oldWidget);
    _widthSimulation.target = widget.width;
    _heightSimulation.target = widget.height;
    startTicking();
  }

  @override
  Widget build(BuildContext context) => new SizedBox(
        width: _widthSimulation.value.clamp(0.0, double.infinity),
        height: _heightSimulation.value.clamp(0.0, double.infinity),
        child: widget.child,
      );

  @override
  bool handleTick(double elapsedSeconds) {
    _widthSimulation.elapseTime(elapsedSeconds);
    _heightSimulation.elapseTime(elapsedSeconds);
    return !(_heightSimulation.isDone && _widthSimulation.isDone);
  }

  /// Gets the current size of the box.
  Size get size => new Size(
        _widthSimulation.value.clamp(0.0, double.infinity),
        _heightSimulation.value.clamp(0.0, double.infinity),
      );
}
