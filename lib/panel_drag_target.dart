// Copyright 2017 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/widgets.dart';

import 'drag_direction.dart';
import 'panel_drag_targets.dart';
import 'story_cluster.dart';

/// Called when [storyCluster] has locked onto the [PanelDragTarget] by being
/// dragged over or near the target.
typedef void OnPanelEvent(BuildContext context, StoryCluster storyCluster);

/// Used by [PanelDragTargets] as a potential target.
abstract class PanelDragTarget {
  /// Called when the target has a candidate above it.
  final OnPanelEvent onHover;

  /// Called when the target has a candidate dropped on it.
  final OnPanelEvent onDrop;

  /// The color of the target. For debug purposes only.
  final Color color;

  /// Whether this target can be the initial target for a candidate or not.
  final bool initiallyTargetable;

  /// Constructor.
  PanelDragTarget({
    this.onHover,
    this.onDrop,
    this.color,
    this.initiallyTargetable,
  });

  /// Returns true if the target can accept [storyCount] stories.
  bool canAccept(int storyCount);

  /// Returns true if the target is valid for a candidate being dragged in
  /// [dragDirection].
  bool isValidInDirection(DragDirection dragDirection);

  /// Returns true if the target is in the [dragDirection] from [point].
  bool isInDirectionFromPoint(DragDirection dragDirection, Offset point);

  /// Returns the distance the target is from [p].
  double distanceFrom(Offset p);

  /// Returns a visual representation of the target. For debug purposes only.
  Widget build({bool highlighted: false});

  /// Returns true if the target has the same visual influence as [other].
  /// For debug purposes only.
  bool hasEqualInfluence(PanelDragTarget other);

  /// Returns true if the target is logically the same target as [other].
  bool isSameTarget(PanelDragTarget other);

  /// Returns true if [p] is within range of target.
  bool withinRange(Offset p);
}
