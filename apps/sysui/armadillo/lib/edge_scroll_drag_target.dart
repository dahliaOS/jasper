// Copyright 2017 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:math' as math;

import 'package:flutter/widgets.dart';
import 'package:sysui_widgets/ticking_state.dart';

import 'armadillo_drag_target.dart';
import 'kenichi_edge_scrolling.dart';
import 'nothing.dart';
import 'story_cluster_drag_data.dart';
import 'story_cluster_drag_state_model.dart';

const Color _kDraggableHoverColor = const Color(0x00FFFF00);
const Color _kNoDraggableHoverColor = const Color(0x00FFFF00);

/// Called whenever an [ArmadilloDragTarget] child of [EdgeScrollDragTarget] is
/// built.
typedef void _BuildCallback(bool hasDraggableAbove, List<Offset> points);

/// Creates disablable drag targets which cause the given [ScrollController] to
/// scroll when a draggable hovers over them.  The drag targets are placed
/// at the top and bottom of this widget's parent such that dragging a candidate
/// to the top or bottom 'edge' of the parent will trigger scrolling.
class EdgeScrollDragTarget extends StatefulWidget {
  /// The [ScrollController] that will have its scroll offset change due to
  /// dragging a candidate to the edge of this [EdgeScrollDragTarget].
  final ScrollController scrollController;

  /// Constructor.
  EdgeScrollDragTarget({Key key, this.scrollController}) : super(key: key);

  @override
  EdgeScrollDragTargetState createState() => new EdgeScrollDragTargetState();
}

/// [State] of [EdgeScrollDragTarget].
class EdgeScrollDragTargetState extends TickingState<EdgeScrollDragTarget> {
  final KenichiEdgeScrolling _kenichiEdgeScrolling = new KenichiEdgeScrolling();
  bool _enabled = true;

  /// Disables detection of candidates over the top and bottom edges of its
  /// parent.
  void disable() {
    if (_enabled) {
      setState(() {
        _enabled = false;
      });
    }
  }

  /// Enables detection of candidates over the top and bottom edges of its
  /// parent.
  void enable() {
    if (!_enabled) {
      setState(() {
        _enabled = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) =>
      new ScopedModelDescendant<StoryClusterDragStateModel>(
        builder: (
          BuildContext context,
          Widget child,
          StoryClusterDragStateModel storyClusterDragStateModel,
        ) {
          bool isNotDragging =
              !_enabled || !storyClusterDragStateModel.isDragging;
          if (isNotDragging) {
            _kenichiEdgeScrolling.onNoDrag();
          }
          return isNotDragging ? Nothing.widget : child;
        },
        child: new Stack(
          fit: StackFit.passthrough,
          children: <Widget>[
            new Positioned(
              top: 0.0,
              left: 0.0,
              right: 0.0,
              bottom: 0.0,
              child: _buildDragTarget(
                onBuild: (bool hasDraggableAbove, List<Offset> points) {
                  RenderBox box = context.findRenderObject();
                  double height = box.size.height;
                  double y = height;
                  points.forEach((Offset point) {
                    y = math.min(y, point.dy);
                  });
                  _kenichiEdgeScrolling.update(y, height);
                  if (!_kenichiEdgeScrolling.isDone) {
                    startTicking();
                  }
                },
              ),
            ),
          ],
        ),
      );

  @override
  bool handleTick(double seconds) {
    // Cancel callbacks if we've disabled the drag targets or we've settled.
    if (!_enabled || _kenichiEdgeScrolling.isDone) {
      return false;
    }

    ScrollPosition position = widget.scrollController.position;
    double minScrollExtent = position.minScrollExtent;
    double maxScrollExtent = position.maxScrollExtent;
    double currentScrollOffset = position.pixels;

    double cumulativeScrollDelta = 0.0;
    double secondsRemaining = seconds;
    final double _kMaxStepSize = 1 / 60;
    while (secondsRemaining > 0.0) {
      double stepSize =
          secondsRemaining > _kMaxStepSize ? _kMaxStepSize : secondsRemaining;
      cumulativeScrollDelta += _kenichiEdgeScrolling.getScrollDelta(stepSize);
      secondsRemaining -= _kMaxStepSize;
    }
    widget.scrollController.jumpTo(
      (currentScrollOffset + cumulativeScrollDelta).clamp(
        minScrollExtent,
        maxScrollExtent,
      ),
    );
    return true;
  }

  Widget _buildDragTarget({
    Key key,
    _BuildCallback onBuild,
  }) =>
      new ArmadilloDragTarget<StoryClusterDragData>(
        onWillAccept: (_, __) => false,
        onAccept: (_, __, ___) => null,
        builder: (_, __, Map<dynamic, Offset> rejectedData) {
          onBuild(rejectedData.isNotEmpty, rejectedData.values.toList());
          return new IgnorePointer(
            child: new Container(
              color: rejectedData.isEmpty
                  ? _kNoDraggableHoverColor
                  : _kDraggableHoverColor,
            ),
          );
        },
      );
}
