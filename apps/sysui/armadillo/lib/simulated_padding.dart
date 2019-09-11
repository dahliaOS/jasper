// Copyright 2016 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/widgets.dart';
import 'package:sysui_widgets/rk4_spring_simulation.dart';
import 'package:sysui_widgets/ticking_state.dart';

const RK4SpringDescription _kDefaultSimulationDesc =
    const RK4SpringDescription(tension: 750.0, friction: 50.0);

/// Animates a [Padding]'s [fractionalLeftPadding] and [fractionalRightPadding]
/// with a spring simulation.
class SimulatedPadding extends StatefulWidget {
  /// The description of the spring to use for simulating transitions.
  final RK4SpringDescription springDescription;

  /// The amount of left padding to apply to [child] given the parent's [width].
  final double fractionalLeftPadding;

  /// The amount of right padding to apply to [child] given the parent's
  /// [width].
  final double fractionalRightPadding;

  /// The parent's width.
  final double width;

  /// The widget to apply padding to.
  final Widget child;

  /// Constructor.
  SimulatedPadding({
    Key key,
    this.fractionalLeftPadding,
    this.fractionalRightPadding,
    this.width,
    this.springDescription: _kDefaultSimulationDesc,
    this.child,
  }) : super(key: key);

  @override
  _SimulatedPaddingState createState() => new _SimulatedPaddingState();
}

class _SimulatedPaddingState extends TickingState<SimulatedPadding> {
  RK4SpringSimulation _leftSimulation;
  RK4SpringSimulation _rightSimulation;

  @override
  void initState() {
    super.initState();
    _leftSimulation = new RK4SpringSimulation(
      initValue: widget.fractionalLeftPadding,
      desc: widget.springDescription,
    );
    _rightSimulation = new RK4SpringSimulation(
      initValue: widget.fractionalRightPadding,
      desc: widget.springDescription,
    );
  }

  @override
  void didUpdateWidget(SimulatedPadding oldWidget) {
    super.didUpdateWidget(oldWidget);
    _leftSimulation.target = widget.fractionalLeftPadding;
    _rightSimulation.target = widget.fractionalRightPadding;
    startTicking();
  }

  @override
  Widget build(BuildContext context) => new Padding(
        padding: new EdgeInsets.only(
          left:
              widget.width * _leftSimulation.value.clamp(0.0, double.infinity),
          right:
              widget.width * _rightSimulation.value.clamp(0.0, double.infinity),
        ),
        child: widget.child,
      );

  @override
  bool handleTick(double elapsedSeconds) {
    _leftSimulation.elapseTime(elapsedSeconds);
    _rightSimulation.elapseTime(elapsedSeconds);
    return !_leftSimulation.isDone || !_rightSimulation.isDone;
  }
}
