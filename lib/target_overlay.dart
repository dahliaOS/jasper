// Copyright 2017 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/widgets.dart';

import 'panel_drag_target.dart';

/// When [enabled] is true, this widget draws the given [targets]
/// that will accept [candidatePoints] overlaid on top of [child].  The
/// current [Offset]s of the [candidatePoints] along with those of the
/// [closestTargetLockPoints] are also drawn on top of [child].
class TargetOverlay extends StatelessWidget {
  /// Widget to display behind the overlay.
  final Widget child;

  /// The targets the candidates can lock to.
  final List<PanelDragTarget> targets;

  /// The locations the candidates last chose their targets.
  final List<Offset> closestTargetLockPoints;

  /// The locations of the candidates.
  final List<Offset> candidatePoints;

  /// Set to true to draw targets.
  final bool enabled;

  /// Constructor.
  TargetOverlay({
    this.enabled,
    this.targets,
    this.closestTargetLockPoints,
    this.candidatePoints,
    this.child,
  });

  @override
  Widget build(BuildContext context) {
    List<Widget> stackChildren = <Widget>[new Positioned.fill(child: child)];

    // When we have a candidate, show the targets.
    if (enabled && candidatePoints.isNotEmpty) {
      // Add all the targets.
      targets.forEach(
        (PanelDragTarget target) => stackChildren.add(target.build()),
      );

      // Add candidate points
      stackChildren.addAll(
        candidatePoints.map(
          (Offset point) => new Positioned(
                left: point.dx - 5.0,
                top: point.dy - 5.0,
                width: 10.0,
                height: 10.0,
                child: new Container(
                  color: new Color(0xFFFFFF00),
                ),
              ),
        ),
      );
      // Add candidate lockpoints
      stackChildren.addAll(
        closestTargetLockPoints.map(
          (Offset point) => new Positioned(
                left: point.dx - 5.0,
                top: point.dy - 5.0,
                width: 10.0,
                height: 10.0,
                child: new Container(
                  color: new Color(0xFFFF00FF),
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
