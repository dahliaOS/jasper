// Copyright 2017 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/widgets.dart';

import 'display_mode.dart';
import 'panel.dart';
import 'place_holder_story.dart';
import 'story.dart';
import 'story_cluster.dart';
import 'story_model.dart';

const double _kAddedStorySpan = 0.01;

/// Handles hover and drop events of candidates dragged over
/// [targetStoryCluster].
class PanelEventHandler {
  /// The [StoryCluster] all the events happen to.
  final StoryCluster targetStoryCluster;

  /// Constructor.
  PanelEventHandler(this.targetStoryCluster);

  /// Called when a candidate is not longer being dragged above
  /// [targetStoryCluster].
  void onCandidateRemoved() {
    targetStoryCluster.removePreviews();
    _normalizeSizes();
  }

  /// Called when [storyCluster] is being removed from [targetStoryCluster].
  void onLeaveCluster({
    BuildContext context,
    StoryCluster storyCluster,
    bool preview: false,
  }) {
    if (preview) {
      targetStoryCluster.removePreviews();
      _cleanup(context: context, preview: true);
      _updateDragFeedback(storyCluster);
    }
  }

  /// Called when [storyCluster] is hovering above [targetStoryCluster]'s
  /// story bar.
  void onStoryBarHover({
    BuildContext context,
    StoryCluster storyCluster,
    int targetIndex,
  }) {
    onAddClusterToRightOfPanels(
      context: context,
      storyCluster: storyCluster,
      preview: true,
      displayMode: DisplayMode.tabs,
    );

    // Update tab positions in target cluster.
    targetStoryCluster.movePlaceholderStoriesToIndex(
      storyCluster.realStories,
      targetIndex,
    );

    // Update tab positions in dragged candidate cluster.
    storyCluster.mirrorStoryOrder(targetStoryCluster.stories);
  }

  /// Called when [storyCluster] is dropped upon [targetStoryCluster]'s
  /// story bar.
  void onStoryBarDrop({
    BuildContext context,
    StoryCluster storyCluster,
    int targetIndex = -1,
  }) {
    int localTargetIndex =
        (targetIndex == -1) ? targetStoryCluster.stories.length : targetIndex;
    targetStoryCluster.removePreviews();
    storyCluster.removePreviews();
    _cleanup(context: context, preview: true);

    targetStoryCluster.displayMode = DisplayMode.tabs;
    targetStoryCluster.focusedStoryId = storyCluster.focusedStoryId;

    final List<Story> storiesToMove = storyCluster.realStories;

    StoryModel.of(context).combine(
          source: storyCluster,
          target: targetStoryCluster,
        );

    targetStoryCluster.maximizeStoryBars();

    targetStoryCluster.moveStoriesToIndex(storiesToMove, localTargetIndex);
  }

  /// Adds the stories of [storyCluster] to the left, spanning the full height.
  void onAddClusterToLeftOfPanels({
    BuildContext context,
    StoryCluster storyCluster,
    bool preview: false,
  }) {
    targetStoryCluster.displayMode = DisplayMode.panels;

    // 0) Remove any existing preview stories.
    Map<StoryId, PlaceHolderStory> placeholders =
        targetStoryCluster.removePreviews();

    List<Story> storiesToAdd = preview
        ? new List<Story>.generate(
            storyCluster.realStories.length,
            (int index) =>
                placeholders[storyCluster.realStories[index].id] ??
                new PlaceHolderStory(
                  associatedStoryId: storyCluster.realStories[index].id,
                ),
          )
        : _getHorizontallySortedStories(storyCluster);

    // 1) Make room for new stories.
    _makeRoom(
      panels: targetStoryCluster.panels
          .where((Panel panel) => panel.left == 0)
          .toList(),
      leftDelta: (_kAddedStorySpan * storiesToAdd.length),
      widthFactorDelta: -(_kAddedStorySpan * storiesToAdd.length),
    );

    // 2) Add new stories.
    _addStoriesHorizontally(
      stories: storiesToAdd,
      x: 0.0,
      top: 0.0,
      bottom: 1.0,
    );

    // 3) Clean up.
    _cleanup(context: context, storyCluster: storyCluster, preview: preview);

    // 4) If previewing, update the drag feedback.
    if (preview) {
      _updateDragFeedback(storyCluster);
    }
  }

  /// Adds the stories of [storyCluster] to the right, spanning the full height.
  void onAddClusterToRightOfPanels({
    BuildContext context,
    StoryCluster storyCluster,
    bool preview: false,
    DisplayMode displayMode: DisplayMode.panels,
  }) {
    targetStoryCluster.displayMode = displayMode;

    // 0) Remove any existing preview stories.
    Map<StoryId, PlaceHolderStory> placeholders =
        targetStoryCluster.removePreviews();

    List<Story> storiesToAdd = preview
        ? new List<Story>.generate(
            storyCluster.realStories.length,
            (int index) =>
                placeholders[storyCluster.realStories[index].id] ??
                new PlaceHolderStory(
                  associatedStoryId: storyCluster.realStories[index].id,
                ),
          )
        : _getHorizontallySortedStories(storyCluster);

    // 1) Make room for new stories.
    _makeRoom(
      panels: targetStoryCluster.panels
          .where((Panel panel) => panel.right == 1.0)
          .toList(),
      widthFactorDelta: -(_kAddedStorySpan * storiesToAdd.length),
    );

    // 2) Add new stories.
    _addStoriesHorizontally(
      stories: storiesToAdd,
      x: 1.0 - (_kAddedStorySpan * storiesToAdd.length),
      top: 0.0,
      bottom: 1.0,
    );

    // 3) Clean up.
    _cleanup(context: context, storyCluster: storyCluster, preview: preview);

    // 4) If previewing, update the drag feedback.
    if (preview) {
      _updateDragFeedback(storyCluster, displayMode);
    }
  }

  /// Adds the stories of [storyCluster] to the top, spanning the full width.
  void onAddClusterAbovePanels({
    BuildContext context,
    StoryCluster storyCluster,
    bool preview: false,
  }) {
    targetStoryCluster.displayMode = DisplayMode.panels;

    // 0) Remove any existing preview stories.
    Map<StoryId, PlaceHolderStory> placeholders =
        targetStoryCluster.removePreviews();

    List<Story> storiesToAdd = preview
        ? new List<Story>.generate(
            storyCluster.realStories.length,
            (int index) =>
                placeholders[storyCluster.realStories[index].id] ??
                new PlaceHolderStory(
                  associatedStoryId: storyCluster.realStories[index].id,
                ),
          )
        : _getVerticallySortedStories(storyCluster);

    // 1) Make room for new stories.
    _makeRoom(
      panels: targetStoryCluster.panels
          .where((Panel panel) => panel.top == 0.0)
          .toList(),
      topDelta: (_kAddedStorySpan * storiesToAdd.length),
      heightFactorDelta: -(_kAddedStorySpan * storiesToAdd.length),
    );

    // 2) Add new stories.
    _addStoriesVertically(
      stories: storiesToAdd,
      y: 0.0,
      left: 0.0,
      right: 1.0,
    );

    // 3) Clean up.
    _cleanup(context: context, storyCluster: storyCluster, preview: preview);

    // 4) If previewing, update the drag feedback.
    if (preview) {
      _updateDragFeedback(storyCluster);
    }
  }

  /// Adds the stories of [storyCluster] to the bottom, spanning the full width.
  void onAddClusterBelowPanels({
    BuildContext context,
    StoryCluster storyCluster,
    bool preview: false,
  }) {
    targetStoryCluster.displayMode = DisplayMode.panels;

    // 0) Remove any existing preview stories.
    Map<StoryId, PlaceHolderStory> placeholders =
        targetStoryCluster.removePreviews();

    List<Story> storiesToAdd = preview
        ? new List<Story>.generate(
            storyCluster.realStories.length,
            (int index) =>
                placeholders[storyCluster.realStories[index].id] ??
                new PlaceHolderStory(
                  associatedStoryId: storyCluster.realStories[index].id,
                ),
          )
        : _getVerticallySortedStories(storyCluster);

    // 1) Make room for new stories.
    _makeRoom(
      panels: targetStoryCluster.panels
          .where((Panel panel) => panel.bottom == 1.0)
          .toList(),
      heightFactorDelta: -(_kAddedStorySpan * storiesToAdd.length),
    );

    // 2) Add new stories.
    _addStoriesVertically(
      stories: storiesToAdd,
      y: 1.0 - (_kAddedStorySpan * storiesToAdd.length),
      left: 0.0,
      right: 1.0,
    );

    // 3) Clean up.
    _cleanup(context: context, storyCluster: storyCluster, preview: preview);

    // 4) If previewing, update the drag feedback.
    if (preview) {
      _updateDragFeedback(storyCluster);
    }
  }

  Panel _getPanelFromStoryId(Object storyId) => targetStoryCluster.stories
      .where((Story s) => storyId == s.id)
      .single
      .panel;

  /// Adds the stories of [storyCluster] to the left of [storyId]'s panel,
  /// spanning that panel's height.
  void onAddClusterToLeftOfPanel({
    BuildContext context,
    StoryCluster storyCluster,
    StoryId storyId,
    bool preview: false,
  }) {
    targetStoryCluster.displayMode = DisplayMode.panels;

    // 0) Remove any existing preview stories.
    Map<StoryId, PlaceHolderStory> placeholders =
        targetStoryCluster.removePreviews();

    List<Story> storiesToAdd = preview
        ? new List<Story>.generate(
            storyCluster.realStories.length,
            (int index) =>
                placeholders[storyCluster.realStories[index].id] ??
                new PlaceHolderStory(
                  associatedStoryId: storyCluster.realStories[index].id,
                ),
          )
        : _getHorizontallySortedStories(storyCluster);

    Panel panel = _getPanelFromStoryId(storyId);

    // 1) Add new stories.
    _addStoriesHorizontally(
      stories: storiesToAdd,
      x: panel.left,
      top: panel.top,
      bottom: panel.bottom,
    );

    // 2) Make room for new stories.
    _makeRoom(
      panels: <Panel>[panel],
      leftDelta: (_kAddedStorySpan * storiesToAdd.length),
      widthFactorDelta: -(_kAddedStorySpan * storiesToAdd.length),
    );

    // 3) Clean up.
    _cleanup(context: context, storyCluster: storyCluster, preview: preview);

    // 4) If previewing, update the drag feedback.
    if (preview) {
      _updateDragFeedback(storyCluster);
    }
  }

  /// Adds the stories of [storyCluster] to the right of [storyId]'s panel',
  /// spanning that panel's height.
  void onAddClusterToRightOfPanel({
    BuildContext context,
    StoryCluster storyCluster,
    StoryId storyId,
    bool preview: false,
  }) {
    targetStoryCluster.displayMode = DisplayMode.panels;

    // 0) Remove any existing preview stories.
    Map<StoryId, PlaceHolderStory> placeholders =
        targetStoryCluster.removePreviews();

    List<Story> storiesToAdd = preview
        ? new List<Story>.generate(
            storyCluster.realStories.length,
            (int index) =>
                placeholders[storyCluster.realStories[index].id] ??
                new PlaceHolderStory(
                  associatedStoryId: storyCluster.realStories[index].id,
                ),
          )
        : _getHorizontallySortedStories(storyCluster);

    Panel panel = _getPanelFromStoryId(storyId);

    // 1) Add new stories.
    _addStoriesHorizontally(
      stories: storiesToAdd,
      x: panel.right - storiesToAdd.length * _kAddedStorySpan,
      top: panel.top,
      bottom: panel.bottom,
    );

    // 2) Make room for new stories.
    _makeRoom(
      panels: <Panel>[panel],
      widthFactorDelta: -(_kAddedStorySpan * storiesToAdd.length),
    );

    // 3) Clean up.
    _cleanup(context: context, storyCluster: storyCluster, preview: preview);

    // 4) If previewing, update the drag feedback.
    if (preview) {
      _updateDragFeedback(storyCluster);
    }
  }

  /// Adds the stories of [storyCluster] to the top of [storyId]'s panel,
  /// spanning that panel's width.
  void onAddClusterAbovePanel({
    BuildContext context,
    StoryCluster storyCluster,
    StoryId storyId,
    bool preview: false,
  }) {
    targetStoryCluster.displayMode = DisplayMode.panels;

    // 0) Remove any existing preview stories.
    Map<StoryId, PlaceHolderStory> placeholders =
        targetStoryCluster.removePreviews();

    List<Story> storiesToAdd = preview
        ? new List<Story>.generate(
            storyCluster.realStories.length,
            (int index) =>
                placeholders[storyCluster.realStories[index].id] ??
                new PlaceHolderStory(
                  associatedStoryId: storyCluster.realStories[index].id,
                ),
          )
        : _getVerticallySortedStories(storyCluster);

    Panel panel = _getPanelFromStoryId(storyId);

    // 1) Add new stories.
    _addStoriesVertically(
      stories: storiesToAdd,
      y: panel.top,
      left: panel.left,
      right: panel.right,
    );

    // 2) Make room for new stories.
    _makeRoom(
      panels: <Panel>[panel],
      topDelta: (_kAddedStorySpan * storiesToAdd.length),
      heightFactorDelta: -(_kAddedStorySpan * storiesToAdd.length),
    );

    // 3) Clean up.
    _cleanup(context: context, storyCluster: storyCluster, preview: preview);

    // 4) If previewing, update the drag feedback.
    if (preview) {
      _updateDragFeedback(storyCluster);
    }
  }

  /// Adds the stories of [storyCluster] to the bottom of [storyId]'s panel,
  /// spanning that panel's width.
  void onAddClusterBelowPanel({
    BuildContext context,
    StoryCluster storyCluster,
    StoryId storyId,
    bool preview: false,
  }) {
    targetStoryCluster.displayMode = DisplayMode.panels;

    // 0) Remove any existing preview stories.
    Map<StoryId, PlaceHolderStory> placeholders =
        targetStoryCluster.removePreviews();

    List<Story> storiesToAdd = preview
        ? new List<Story>.generate(
            storyCluster.realStories.length,
            (int index) =>
                placeholders[storyCluster.realStories[index].id] ??
                new PlaceHolderStory(
                  associatedStoryId: storyCluster.realStories[index].id,
                ),
          )
        : _getVerticallySortedStories(storyCluster);

    Panel panel = _getPanelFromStoryId(storyId);

    // 1) Add new stories.
    _addStoriesVertically(
      stories: storiesToAdd,
      y: panel.bottom - storiesToAdd.length * _kAddedStorySpan,
      left: panel.left,
      right: panel.right,
    );

    // 2) Make room for new stories.
    _makeRoom(
      panels: <Panel>[panel],
      heightFactorDelta: -(_kAddedStorySpan * storiesToAdd.length),
    );

    // 3) Clean up.
    _cleanup(context: context, storyCluster: storyCluster, preview: preview);

    // 4) If previewing, update the drag feedback.
    if (preview) {
      _updateDragFeedback(storyCluster);
    }
  }

  void _cleanup({
    BuildContext context,
    StoryCluster storyCluster,
    bool preview,
  }) {
    // 1) Normalize sizes.
    _normalizeSizes();

    // 2) Remove dropped cluster from story model.
    if (!preview) {
      StoryModel.of(context).remove(storyCluster);
    }
  }

  void _updateDragFeedback(
    StoryCluster draggingStoryCluster, [
    DisplayMode displayMode = DisplayMode.panels,
  ]) {
    // 1. Remove existing PlaceHolders (and save them off).
    Map<StoryId, PlaceHolderStory> previews =
        draggingStoryCluster.removePreviews();

    // 2. Create and Add PlaceHolders for dragging story cluster for each story
    //    in this story cluster.
    if (targetStoryCluster.previewStories.isNotEmpty) {
      targetStoryCluster.realStories.forEach((Story story) {
        draggingStoryCluster.add(
          story: previews[story.id] ??
              new PlaceHolderStory(
                associatedStoryId: story.id,
                transparent: true,
              ),
          withPanel: story.panel,
          atIndex: 0,
        );
      });
    }

    // 3. Resize all panels in the dragging story cluster with the placeholders
    //    in this story cluster.
    targetStoryCluster.previewStories.forEach((Story story) {
      PlaceHolderStory placeHolderStory = story;
      draggingStoryCluster.replace(
          panel: draggingStoryCluster.stories
              .where((Story story) =>
                  story.id == placeHolderStory.associatedStoryId)
              .single
              .panel,
          withPanel: placeHolderStory.panel);
    });

    // 4. Update displaymode.
    draggingStoryCluster.displayMode = displayMode;

    // 5. Normalize sizes.
    draggingStoryCluster.normalizeSizes();
  }

  void _normalizeSizes() => targetStoryCluster.normalizeSizes();

  /// Resizes the existing panels just enough to add new ones.
  void _makeRoom({
    List<Panel> panels,
    double topDelta: 0.0,
    double leftDelta: 0.0,
    double widthFactorDelta: 0.0,
    double heightFactorDelta: 0.0,
  }) {
    panels.forEach((Panel panel) {
      targetStoryCluster.replace(
        panel: panel,
        withPanel: new Panel(
          origin: new FractionalOffset(
            panel.left + leftDelta,
            panel.top + topDelta,
          ),
          widthFactor: panel.width + widthFactorDelta,
          heightFactor: panel.height + heightFactorDelta,
        ),
      );
    });
  }

  /// Adds stories horizontally starting from [x] with vertical bounds of
  /// [top] to [bottom].
  void _addStoriesHorizontally({
    List<Story> stories,
    double x,
    double top,
    double bottom,
  }) {
    double dx = x;
    stories.forEach((Story story) {
      targetStoryCluster.add(
        story: story,
        withPanel: new Panel(
          origin: new FractionalOffset(dx, top),
          widthFactor: _kAddedStorySpan,
          heightFactor: bottom - top,
        ),
      );
      dx += _kAddedStorySpan;
      story.maximizeStoryBar();
    });
  }

  /// Adds stories vertically starting from [y] with horizontal bounds of
  /// [left] to [right].
  void _addStoriesVertically({
    List<Story> stories,
    double y,
    double left,
    double right,
  }) {
    double dy = y;
    stories.forEach((Story story) {
      targetStoryCluster.add(
        story: story,
        withPanel: new Panel(
          origin: new FractionalOffset(left, dy),
          widthFactor: right - left,
          heightFactor: _kAddedStorySpan,
        ),
      );
      dy += _kAddedStorySpan;
      story.maximizeStoryBar();
    });
  }

  static List<Story> _getVerticallySortedStories(StoryCluster storyCluster) {
    List<Story> sortedStories = new List<Story>.from(storyCluster.stories);
    sortedStories.sort(
      (Story a, Story b) => a.panel.top < b.panel.top
          ? -1
          : a.panel.top > b.panel.top
              ? 1
              : a.panel.left < b.panel.left
                  ? -1
                  : a.panel.left > b.panel.left ? 1 : 0,
    );
    return sortedStories;
  }

  static List<Story> _getHorizontallySortedStories(StoryCluster storyCluster) {
    List<Story> sortedStories = new List<Story>.from(storyCluster.stories);
    sortedStories.sort(
      (Story a, Story b) => a.panel.left < b.panel.left
          ? -1
          : a.panel.left > b.panel.left
              ? 1
              : a.panel.top < b.panel.top
                  ? -1
                  : a.panel.top > b.panel.top ? 1 : 0,
    );
    return sortedStories;
  }
}
