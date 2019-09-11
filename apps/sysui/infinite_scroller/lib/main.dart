// Copyright 2017 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

const double _kGoldenRatio = 1.61803398875;
const double _kMaxWidth = 400.0;

Future<Null> main() async {
  runApp(
    new LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        double cardHeight =
            16.0 + math.min(_kMaxWidth, constraints.maxWidth) / _kGoldenRatio;
        return new Material(
          color: Colors.grey[200],
          child: new Center(
            child: new ConstrainedBox(
              constraints: new BoxConstraints(
                maxWidth: _kMaxWidth,
                maxHeight: constraints.maxHeight,
              ),
              child: new ListView.builder(
                physics: new _FrictionlessScrollPhysics(),
                itemExtent: cardHeight,
                itemBuilder: (BuildContext context, int index) => new Container(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: new Material(
                        color: index % 2 == 0 ? Colors.blue : Colors.green,
                        elevation: 3.0,
                        borderRadius: new BorderRadius.circular(4.0),
                      ),
                    ),
              ),
            ),
          ),
        );
      },
    ),
  );
}

class _FrictionlessScrollPhysics extends ScrollPhysics {
  const _FrictionlessScrollPhysics({ScrollPhysics parent})
      : super(parent: parent);

  @override
  ScrollPhysics applyTo(ScrollPhysics ancestor) {
    return new _FrictionlessScrollPhysics();
  }

  @override
  Simulation createBallisticSimulation(
    ScrollMetrics position,
    double velocity,
  ) =>
      new _FrictionlessSimulation(
        initialPosition: position.pixels,
        velocity: velocity,
      );
}

class _FrictionlessSimulation extends Simulation {
  final double initialPosition;
  final double velocity;

  _FrictionlessSimulation({this.initialPosition, this.velocity});

  @override
  double x(double time) => math.max(
        math.min(initialPosition, 0.0),
        initialPosition + velocity * time,
      );

  @override
  double dx(double time) => velocity;

  @override
  bool isDone(double time) => false;
}
