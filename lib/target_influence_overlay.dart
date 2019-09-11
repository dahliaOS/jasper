// Copyright 2017 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/widgets.dart';

import 'drag_direction.dart';
import 'panel_drag_target.dart';

const double _kStepSize = 40.0;
const double _kTargetMargin = 1.0;

/// Returns the closest target to the given [point].
typedef PanelDragTarget ClosestTargetGetter(Offset point);

/// When [enabled] is true, this widget draws the influence of the given
/// [targets] by drawing a bunch of points that will accept
/// candidates overlaid on top of [child].
class TargetInfluenceOverlay extends StatelessWidget {
  /// Widget to display behind the overlay.
  final Widget child;

  /// The targets the candidates can lock to.
  final List<PanelDragTarget> targets;

  /// The current direction candidates are being dragged.
  final DragDirection dragDirection;

  /// Returns the closest target to a candidate.
  final ClosestTargetGetter closestTargetGetter;

  /// Set to true to draw influence.
  final bool enabled;

  /// Constructor.
  TargetInfluenceOverlay({
    this.enabled,
    this.targets,
    this.dragDirection,
    this.closestTargetGetter,
    this.child,
  });

  @override
  Widget build(BuildContext context) {
    List<Widget> stackChildren = <Widget>[new Positioned.fill(child: child)];

    // When enabled, show the influence.
    if (enabled) {
      // Add all the targets.
      stackChildren.add(
        new Positioned.fill(
          child: new RepaintBoundary(
            child: new CustomPaint(
              painter: new _InfluencePainter(
                dragDirection: dragDirection,
                targets: targets,
                closestTargetGetter: closestTargetGetter,
              ),
            ),
          ),
        ),
      );
    }
    return new Stack(
      fit: StackFit.passthrough,
      children: stackChildren,
    );
  }
}

class _InfluencePainter extends CustomPainter {
  final DragDirection dragDirection;
  final List<PanelDragTarget> targets;
  final ClosestTargetGetter closestTargetGetter;

  _InfluencePainter({
    this.dragDirection,
    this.targets,
    this.closestTargetGetter,
  });

  @override
  void paint(Canvas canvas, Size size) {
    int xSteps = (size.width / _kStepSize).round() - 1;
    int ySteps = (size.height / _kStepSize).round() - 1;
    List<List<PanelDragTarget>> targetMatrix =
        new List<List<PanelDragTarget>>.generate(
      xSteps,
      (int xStep) => new List<PanelDragTarget>.generate(
            ySteps,
            (int yStep) => closestTargetGetter(
                  new Offset((xStep + 1) * _kStepSize, (yStep + 1) * _kStepSize),
                ),
          ),
    );
    for (int i = 0; i < xSteps; i++) {
      for (int j = 0; j < ySteps; j++) {
        double leftShift = i > 0 && targetMatrix[i][j] != targetMatrix[i - 1][j]
            ? _kTargetMargin
            : 0.0;
        double rightShift =
            (i < (xSteps - 1)) && targetMatrix[i][j] != targetMatrix[i + 1][j]
                ? -_kTargetMargin
                : 0.0;
        double topShift = j > 0 && targetMatrix[i][j] != targetMatrix[i][j - 1]
            ? _kTargetMargin
            : 0.0;
        double bottomShift =
            (j < (ySteps - 1)) && targetMatrix[i][j] != targetMatrix[i][j + 1]
                ? -_kTargetMargin
                : 0.0;
        canvas.drawRect(
          new Rect.fromLTRB(
            ((i + 1) * _kStepSize) - _kStepSize / 2.0 + leftShift,
            ((j + 1) * _kStepSize) - _kStepSize / 2.0 + topShift,
            ((i + 1) * _kStepSize) + _kStepSize / 2.0 + rightShift,
            ((j + 1) * _kStepSize) + _kStepSize / 2.0 + bottomShift,
          ),
          new Paint()
            ..color = (targetMatrix[i][j]?.color ?? new Color(0x00000000))
                .withOpacity(
              0.75,
            ),
        );
      }
    }
  }

  @override
  bool shouldRepaint(_InfluencePainter oldDelegate) {
    if (oldDelegate.dragDirection != dragDirection) {
      return true;
    }
    if (oldDelegate.targets.length != targets.length) {
      return true;
    }
    for (int i = 0; i < targets.length; i++) {
      if (!targets[i].hasEqualInfluence(oldDelegate.targets[i])) {
        return true;
      }
    }

    return false;
  }

  @override
  bool hitTest(Offset position) => false;
}
