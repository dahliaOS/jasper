// Copyright 2016 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/widgets.dart';
import 'package:sysui_widgets/rk4_spring_simulation.dart';
import 'package:sysui_widgets/ticking_state.dart';

const RK4SpringDescription _kDefaultSimulationDesc =
    const RK4SpringDescription(tension: 750.0, friction: 50.0);

/// Animates a [Positioned]'s [Positioned.left], [Positioned.top],
/// [Positioned.width], and [Positioned.height] with a
/// spring simulation based on the given [size] and fractional coordinates
/// within that [size] specified by [fractionalTop], [fractionalLeft],
/// [fractionalWidth], and [fractionalHeight].
/// If [fractionalTop] and [fractionalLeft] are both null, a [SizedBox] will
/// be used instead of a [Positioned].
class SimulatedFractional extends StatefulWidget {
  /// The top of child relative to its parent from 0.0 to 1.0.
  final double fractionalTop;

  /// The left of child relative to its parent from 0.0 to 1.0.
  final double fractionalLeft;

  /// The width of child relative to its parent from 0.0 to 1.0.
  final double fractionalWidth;

  /// The height of child relative to its parent from 0.0 to 1.0.
  final double fractionalHeight;

  /// The parent's size.
  final Size size;

  /// The spring description for the transition to new fractional values.
  final RK4SpringDescription springDescription;

  /// The child to size relative to the [SimulatedFractional]'s parent.
  final Widget child;

  /// Constructor.
  SimulatedFractional({
    Key key,
    this.fractionalTop,
    this.fractionalLeft,
    this.fractionalWidth,
    this.fractionalHeight,
    this.size,
    this.springDescription: _kDefaultSimulationDesc,
    this.child,
  }) : super(key: key) {
    assert(fractionalWidth != null);
    assert(fractionalHeight != null);
    assert(size != null);
    assert(springDescription != null);
    assert(child != null);
    assert((fractionalTop == null && fractionalLeft == null) ||
        (fractionalTop != null && fractionalLeft != null));
  }

  @override
  SimulatedFractionalState createState() => new SimulatedFractionalState();
}

/// Holds the transition simulations for [SimulatedFractional].
class SimulatedFractionalState extends TickingState<SimulatedFractional> {
  RK4SpringSimulation _fractionalTopSimulation;
  RK4SpringSimulation _fractionalLeftSimulation;
  RK4SpringSimulation _fractionalWidthSimulation;
  RK4SpringSimulation _fractionalHeightSimulation;

  @override
  void initState() {
    super.initState();
    if (widget.fractionalTop != null) {
      _fractionalTopSimulation = new RK4SpringSimulation(
        initValue: widget.fractionalTop,
        desc: widget.springDescription,
      );
      _fractionalLeftSimulation = new RK4SpringSimulation(
        initValue: widget.fractionalLeft,
        desc: widget.springDescription,
      );
    }
    _fractionalWidthSimulation = new RK4SpringSimulation(
      initValue: widget.fractionalWidth,
      desc: widget.springDescription,
    );
    _fractionalHeightSimulation = new RK4SpringSimulation(
      initValue: widget.fractionalHeight,
      desc: widget.springDescription,
    );
  }

  @override
  void didUpdateWidget(SimulatedFractional oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.fractionalTop != null) {
      _fractionalTopSimulation.target = widget.fractionalTop;
      _fractionalLeftSimulation.target = widget.fractionalLeft;
    } else {
      _fractionalTopSimulation = null;
      _fractionalLeftSimulation = null;
    }
    _fractionalWidthSimulation.target = widget.fractionalWidth;
    _fractionalHeightSimulation.target = widget.fractionalHeight;
    startTicking();
  }

  @override
  Widget build(BuildContext context) => _fractionalTopSimulation == null
      ? new SizedBox(
          width: _fractionalWidthSimulation.value * widget.size.width,
          height: _fractionalHeightSimulation.value * widget.size.height,
          child: widget.child,
        )
      : new Positioned(
          top: _fractionalTopSimulation.value * widget.size.height,
          left: _fractionalLeftSimulation.value * widget.size.width,
          width: _fractionalWidthSimulation.value * widget.size.width,
          height: _fractionalHeightSimulation.value * widget.size.height,
          child: widget.child,
        );

  @override
  bool handleTick(double elapsedSeconds) {
    _fractionalTopSimulation?.elapseTime(elapsedSeconds);
    _fractionalLeftSimulation?.elapseTime(elapsedSeconds);
    _fractionalWidthSimulation.elapseTime(elapsedSeconds);
    _fractionalHeightSimulation.elapseTime(elapsedSeconds);
    return !((_fractionalTopSimulation?.isDone ?? true) &&
        (_fractionalLeftSimulation?.isDone ?? true) &&
        _fractionalWidthSimulation.isDone &&
        _fractionalHeightSimulation.isDone);
  }

  /// Jumps the fractional height of the child to [fractionalHeight].
  void jumpFractionalHeight(double fractionalHeight) {
    _fractionalHeightSimulation = new RK4SpringSimulation(
      initValue: fractionalHeight,
      desc: widget.springDescription,
    );
  }

  /// Jumps the fractional top, left, width and height of the child to
  /// what they should be if the child is positioned via [bounds] given a parent
  /// size of [newSize].
  void jump(Rect bounds, Size newSize) {
    _fractionalTopSimulation = new RK4SpringSimulation(
      initValue: bounds.topLeft.dy / newSize.height,
      desc: widget.springDescription,
    );
    _fractionalLeftSimulation = new RK4SpringSimulation(
      initValue: bounds.topLeft.dx / newSize.width,
      desc: widget.springDescription,
    );
    _fractionalWidthSimulation = new RK4SpringSimulation(
      initValue: bounds.width / newSize.width,
      desc: widget.springDescription,
    );
    _fractionalHeightSimulation = new RK4SpringSimulation(
      initValue: bounds.height / newSize.height,
      desc: widget.springDescription,
    );
  }

  /// Jumps the fractional top, left, width and height of the child to
  /// [fractionalTop], [fractionalLeft], [fractionalWidth], and
  /// [fractionalHeight], respectively.
  void jumpToValues({
    double fractionalTop,
    double fractionalLeft,
    double fractionalWidth,
    double fractionalHeight,
  }) {
    if (fractionalTop != null) {
      _fractionalTopSimulation = new RK4SpringSimulation(
        initValue: fractionalTop,
        desc: widget.springDescription,
      );
    }

    if (fractionalLeft != null) {
      _fractionalLeftSimulation = new RK4SpringSimulation(
        initValue: fractionalLeft,
        desc: widget.springDescription,
      );
    }

    if (fractionalWidth != null) {
      _fractionalWidthSimulation = new RK4SpringSimulation(
        initValue: fractionalWidth,
        desc: widget.springDescription,
      );
    }

    if (fractionalHeight != null) {
      _fractionalHeightSimulation = new RK4SpringSimulation(
        initValue: fractionalHeight,
        desc: widget.springDescription,
      );
    }
  }

  @override
  String toString({DiagnosticLevel minLevel = DiagnosticLevel.debug}) =>
      'SimulatedFractionalState(top: $_fractionalTopSimulation, '
      'left: $_fractionalLeftSimulation, '
      'width: $_fractionalWidthSimulation, '
      'height: $_fractionalHeightSimulation)';
}
