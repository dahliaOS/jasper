// Copyright 2017 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:math' as math;

import 'package:flutter/material.dart' as material;
import 'package:flutter/widgets.dart';

import 'drag_direction.dart';
import 'panel_drag_target.dart';
import 'panel_drag_targets.dart';
import 'story_cluster.dart';

const double _kLineWidth = 4.0;

/// Details about a target used by [PanelDragTargets].
///
/// [LineSegment] specifies a line from [a] to [b].
/// When turned into a widget the [LineSegment] will have the color [color].
/// When the [LineSegment] is being targeted by a draggable [onHover] will be
/// called.
/// When the [LineSegment] is dropped upon with a draggable [onDrop] will be
/// called.
/// This [LineSegment] can only be targeted by [StoryCluster]s with a story
/// count of less than or equal to [maxStoriesCanAccept].
/// [LineSegment]s can only be vertical or horizontal.
class LineSegment extends PanelDragTarget {
  /// The beginning of the line.
  /// [a] always aligns with [b] in either vertically or horizontally.
  /// [a] is always 'less than' [b] in x or y direction.
  final Offset a;

  /// The end of the line.
  final Offset b;

  /// The number of stories this line will accept.  See [canAccept].
  final int maxStoriesCanAccept;

  /// The unique name of this line.  This is used to distinguish between
  /// [LineSegment]s.
  final String name;

  /// True if this [LineSegment] can only be a target if the user is dragging
  /// a candidate in this line's axis.
  final bool directionallyTargetable;

  /// A [LineSegment] is considered a valid target for accepting stories if
  /// the [distanceFrom] [Offset] of the stories in question is within the
  /// [validityDistance] of this [LineSegment].
  final double validityDistance;

  /// Constructor.
  LineSegment(
    Offset a,
    Offset b, {
    Color color: material.Colors.white,
    OnPanelEvent onHover,
    OnPanelEvent onDrop,
    this.maxStoriesCanAccept: 1,
    this.name,
    bool initiallyTargetable: true,
    this.directionallyTargetable: false,
    this.validityDistance: double.infinity,
  })  : this.a = (a.dx < b.dx || a.dy < b.dy) ? a : b,
        this.b = (a.dx < b.dx || a.dy < b.dy) ? b : a,
        super(
          onHover: onHover,
          onDrop: onDrop,
          color: color,
          initiallyTargetable: initiallyTargetable,
        ) {
    // Ensure the line is either vertical or horizontal.
    assert(a.dx == b.dx || a.dy == b.dy);
  }

  /// Creates a vertical [LineSegment] whose [a] and [b] have the same [x].
  factory LineSegment.vertical({
    double x,
    double top,
    double bottom,
    Color color: material.Colors.white,
    OnPanelEvent onHover,
    OnPanelEvent onDrop,
    int maxStoriesCanAccept: 1,
    String name,
    bool initiallyTargetable: true,
    bool directionallyTargetable: false,
    double validityDistance: double.infinity,
  }) =>
      new LineSegment(
        new Offset(x, top),
        new Offset(x, bottom),
        color: color,
        onHover: onHover,
        onDrop: onDrop,
        maxStoriesCanAccept: maxStoriesCanAccept,
        name: name,
        initiallyTargetable: initiallyTargetable,
        directionallyTargetable: directionallyTargetable,
        validityDistance: validityDistance,
      );

  /// Creates a horizontal [LineSegment] whose [a] and [b] have the same [y].
  factory LineSegment.horizontal({
    double y,
    double left,
    double right,
    Color color: material.Colors.white,
    OnPanelEvent onHover,
    OnPanelEvent onDrop,
    int maxStoriesCanAccept: 1,
    String name,
    bool initiallyTargetable: true,
    bool directionallyTargetable: false,
    double validityDistance: double.infinity,
  }) =>
      new LineSegment(
        new Offset(left, y),
        new Offset(right, y),
        color: color,
        onHover: onHover,
        onDrop: onDrop,
        maxStoriesCanAccept: maxStoriesCanAccept,
        name: name,
        initiallyTargetable: initiallyTargetable,
        directionallyTargetable: directionallyTargetable,
        validityDistance: validityDistance,
      );

  /// Returns true if the line is horizontal.
  bool get isHorizontal => a.dy == b.dy;

  /// Returns true if the line is vertical.
  bool get isVertical => !isHorizontal;

  @override
  bool canAccept(int storyCount) => storyCount <= maxStoriesCanAccept;

  @override
  bool withinRange(Offset p) => distanceFrom(p) < validityDistance;

  @override
  bool isValidInDirection(DragDirection dragDirection) {
    if (!directionallyTargetable) {
      return true;
    }
    switch (dragDirection) {
      case DragDirection.left:
      case DragDirection.right:
        if (isHorizontal) {
          return false;
        }
        break;
      case DragDirection.up:
      case DragDirection.down:
        if (isVertical) {
          return false;
        }
        break;
      case DragDirection.none:
      default:
        break;
    }
    return true;
  }

  @override
  bool isInDirectionFromPoint(DragDirection dragDirection, Offset point) {
    if (!directionallyTargetable) {
      return true;
    }
    switch (dragDirection) {
      case DragDirection.left:
        if (isHorizontal) {
          return false;
        } else if (a.dx > point.dx) {
          return false;
        }
        break;
      case DragDirection.right:
        // ignore: invariant_booleans
        if (isHorizontal) {
          return false;
        } else if (a.dx < point.dx) {
          return false;
        }
        break;
      case DragDirection.up:
        if (isVertical) {
          return false;
        } else if (a.dy > point.dy) {
          return false;
        }
        break;
      case DragDirection.down:
        // ignore: invariant_booleans
        if (isVertical) {
          return false;
        } else if (a.dy < point.dy) {
          return false;
        }
        break;
      case DragDirection.none:
      default:
        break;
    }
    return true;
  }

  @override
  double distanceFrom(Offset p) {
    if (isHorizontal) {
      if (p.dx < a.dx) {
        return math.sqrt(math.pow(p.dx - a.dx, 2) + math.pow(p.dy - a.dy, 2));
      } else if (p.dx > b.dx) {
        return math.sqrt(math.pow(p.dx - b.dx, 2) + math.pow(p.dy - b.dy, 2));
      } else {
        return (p.dy - a.dy).abs();
      }
    } else {
      if (p.dy < a.dy) {
        return math.sqrt(math.pow(p.dx - a.dx, 2) + math.pow(p.dy - a.dy, 2));
      } else if (p.dy > b.dy) {
        return math.sqrt(math.pow(p.dx - b.dx, 2) + math.pow(p.dy - b.dy, 2));
      } else {
        return (p.dx - a.dx).abs();
      }
    }
  }

  @override
  Widget build({bool highlighted: false}) => validityDistance != double.infinity
      ? new Stack(
          fit: StackFit.passthrough,
          children: <Widget>[
            _buildValidityDistanceWidget(highlighted: highlighted),
            _buildLineWidget(highlighted: highlighted),
          ],
        )
      : new Stack(
          fit: StackFit.passthrough,
          children: <Widget>[
            _buildLineWidget(highlighted: highlighted),
          ],
        );

  Positioned _buildLineWidget({bool highlighted: false}) => new Positioned(
        left: a.dx - _kLineWidth / 2.0,
        top: a.dy - _kLineWidth / 2.0,
        width: isHorizontal ? b.dx - a.dx + _kLineWidth : _kLineWidth,
        height: isVertical ? b.dy - a.dy + _kLineWidth : _kLineWidth,
        child: new Container(
          color: color.withOpacity(highlighted ? 1.0 : 0.3),
        ),
      );

  Positioned _buildValidityDistanceWidget({bool highlighted: false}) =>
      new Positioned(
        left: a.dx - _kLineWidth / 2.0 - validityDistance,
        top: a.dy - _kLineWidth / 2.0 - validityDistance,
        width: (isHorizontal ? b.dx - a.dx + _kLineWidth : _kLineWidth) +
            2 * validityDistance,
        height: (isVertical ? b.dy - a.dy + _kLineWidth : _kLineWidth) +
            2 * validityDistance,
        child: new Container(
          color: color.withOpacity(highlighted ? 0.3 : 0.1),
        ),
      );

  @override
  bool hasEqualInfluence(PanelDragTarget other) {
    if (other is LineSegment) {
      if (other.color != color) {
        return false;
      }
      if (other.a != a) {
        return false;
      }
      if (other.b != b) {
        return false;
      }
      return true;
    }
    return false;
  }

  @override
  bool isSameTarget(PanelDragTarget other) {
    if (other is LineSegment) {
      if (other.name != name) {
        return false;
      }
      return true;
    }
    return false;
  }

  @override
  String toString() =>
      'LineSegment(a: $a, b: $b, color: $color, maxStoriesCanAccept: $maxStoriesCanAccept)';
}
