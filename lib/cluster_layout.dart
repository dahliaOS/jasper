// Copyright 2017 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:meta/meta.dart';

import 'display_mode.dart';
import 'panel.dart';
import 'panel_drag_targets.dart';
import 'story.dart';
import 'story_cluster.dart';

/// Used by [PanelDragTargets] to take a snapshot of a [StoryCluster]'s layout
/// so it can be restored later.
class ClusterLayout {
  /// The id of the [StoryCluster]s focused [Story].
  final StoryId focusedStoryId;

  /// The layout of stories in the story cluster.
  final Map<StoryId, Panel> storyIdToPanelMap;

  /// The display mode of the story cluster.
  final DisplayMode displayMode;

  /// Constructor.
  ClusterLayout({
    @required this.focusedStoryId,
    @required this.storyIdToPanelMap,
    @required this.displayMode,
  });

  /// Creates a [ClusterLayout] from the current state of the given
  /// [storyCluster].
  factory ClusterLayout.from(StoryCluster storyCluster) {
    Map<StoryId, Panel> storyIdToPanelMap = <StoryId, Panel>{};

    storyCluster.stories.forEach((Story story) {
      storyIdToPanelMap[story.id] = new Panel.from(story.panel);
    });

    return new ClusterLayout(
      focusedStoryId: storyCluster.focusedStoryId,
      storyIdToPanelMap: storyIdToPanelMap,
      displayMode: storyCluster.displayMode,
    );
  }

  /// Restores [storyCluster]'s panels, display mode, and focused story to that
  /// saved by this [ClusterLayout].
  void restore(StoryCluster storyCluster) {
    storyIdToPanelMap.keys.forEach((StoryId storyId) {
      storyCluster.replaceStoryPanel(
        storyId: storyId,
        withPanel: storyIdToPanelMap[storyId],
      );
    });
    storyCluster.displayMode = displayMode;
    storyCluster.focusedStoryId = focusedStoryId;
  }

  /// Restores [storyCluster]'s focused story to that saved by this
  /// [ClusterLayout].
  void restoreFocus(StoryCluster storyCluster) {
    storyCluster.focusedStoryId = focusedStoryId;
  }

  /// The number of stories saved off.
  int get storyCount => storyIdToPanelMap.length;

  /// The list of panels saved off.
  List<Panel> get panels => storyIdToPanelMap.values.toList();

  /// Calls [storyCallback] for each story saved off.
  void visitStories(void storyCallback(StoryId storyId, Panel storyPanel)) =>
      storyIdToPanelMap.keys.forEach(
        (StoryId storyId) => storyCallback(storyId, storyIdToPanelMap[storyId]),
      );
}
