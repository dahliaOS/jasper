// Copyright 2016 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/widgets.dart';
import 'package:sysui_widgets/rk4_spring_simulation.dart';
import 'package:sysui_widgets/ticking_state.dart';

const RK4SpringDescription _kDefaultSimulationDesc =
    const RK4SpringDescription(tension: 750.0, friction: 50.0);

/// Animates a [Transform]'s translation x, y, scale and opacity
/// with a spring simulation.
///
/// When first built this widget's opacity will start with [initOpacity] and
/// will animate to [targetOpacity].  Rebuilds of this widget will animate from
/// the current opacity value to [targetOpacity] instead of animating from
/// [initOpacity].
///
/// When first built this widget's scale will start with [initScale] and will
/// animate to [targetScale].  Rebuilds of this widget will animate from the
/// current scale value to [targetScale] instead of animating from [initScale].
class SimulatedTransform extends StatefulWidget {
  /// The initial X offset of the [child].
  final double initDx;

  /// The target X offset of the [child].
  final double targetDx;

  /// The initial Y offset of the [child].
  final double initDy;

  /// The target Y offset of the [child].
  final double targetDy;

  /// The initial scale of the [child].
  final double initScale;

  /// The target scale of the [child].
  final double targetScale;

  /// The initial opacity of the [child].
  final double initOpacity;

  /// The target opacity of the [child].
  final double targetOpacity;

  /// The spring description to use for simulating from inits to targets.
  final RK4SpringDescription springDescription;

  /// The child to apply all the transforms to.
  final Widget child;

  /// Constructor.
  SimulatedTransform({
    Key key,
    this.initDx: 0.0,
    this.initDy: 0.0,
    this.targetDx: 0.0,
    this.targetDy: 0.0,
    this.initScale: 1.0,
    this.targetScale: 1.0,
    this.initOpacity: 1.0,
    this.targetOpacity: 1.0,
    this.springDescription: _kDefaultSimulationDesc,
    this.child,
  })
      : super(key: key);

  @override
  _SimulatedTranslationTransformState createState() =>
      new _SimulatedTranslationTransformState();
}

class _SimulatedTranslationTransformState
    extends TickingState<SimulatedTransform> {
  RK4SpringSimulation _dxSimulation;
  RK4SpringSimulation _dySimulation;
  RK4SpringSimulation _scaleSimulation;
  RK4SpringSimulation _opacitySimulation;

  @override
  void initState() {
    super.initState();
    _dxSimulation = new RK4SpringSimulation(
      initValue: widget.initDx,
      desc: widget.springDescription,
    );
    _dxSimulation.target = widget.targetDx;
    _dySimulation = new RK4SpringSimulation(
      initValue: widget.initDy,
      desc: widget.springDescription,
    );
    _dySimulation.target = widget.targetDy;
    _scaleSimulation = new RK4SpringSimulation(
      initValue: widget.initScale,
      desc: widget.springDescription,
    );
    _scaleSimulation.target = widget.targetScale;
    _opacitySimulation = new RK4SpringSimulation(
      initValue: widget.initOpacity,
      desc: widget.springDescription,
    );
    _opacitySimulation.target = widget.targetOpacity;
    startTicking();
  }

  @override
  void didUpdateWidget(SimulatedTransform oldWidget) {
    super.didUpdateWidget(oldWidget);
    _dxSimulation.target = widget.targetDx;
    _dySimulation.target = widget.targetDy;
    _scaleSimulation.target = widget.targetScale;
    _opacitySimulation.target = widget.targetOpacity;
    startTicking();
  }

  @override
  Widget build(BuildContext context) => new Transform(
      transform: new Matrix4.translationValues(
        _dxSimulation.value,
        _dySimulation.value,
        0.0,
      ),
      child: new Transform(
        transform: new Matrix4.identity().scaled(
          _scaleSimulation.value,
          _scaleSimulation.value,
        ),
        alignment: FractionalOffset.center,
        child: new Opacity(
          opacity: _opacitySimulation.value.clamp(0.0, 1.0),
          child: widget.child,
        ),
      ));

  @override
  bool handleTick(double elapsedSeconds) {
    _dxSimulation.elapseTime(elapsedSeconds);
    _dySimulation.elapseTime(elapsedSeconds);
    _scaleSimulation.elapseTime(elapsedSeconds);
    _opacitySimulation.elapseTime(elapsedSeconds);
    return !_dxSimulation.isDone ||
        !_dySimulation.isDone ||
        !_scaleSimulation.isDone ||
        !_opacitySimulation.isDone;
  }
}
