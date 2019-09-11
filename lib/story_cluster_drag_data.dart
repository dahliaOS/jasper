// Copyright 2017 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/widgets.dart';

import 'armadillo_drag_target.dart';
import 'panel_drag_targets.dart';
import 'story_cluster.dart';
import 'story_cluster_id.dart';

/// The data [StoryCluster]'s use with [ArmadilloLongPressDraggable]s and
/// [ArmadilloDragTarget]s.
class StoryClusterDragData {
  /// The id of the [StoryCluster] being dragged.
  final StoryClusterId id;

  /// The callback to call when the [StoryCluster] is first dragged over an
  /// [ArmadilloDragTarget].
  final VoidCallback onFirstHover;

  /// The callback to call when the [StoryCluster] was accepted without having
  /// a target in [PanelDragTargets] while not in the timeline.
  final VoidCallback onNoTarget;

  /// Constructor.
  StoryClusterDragData({this.id, this.onFirstHover, this.onNoTarget});
}
