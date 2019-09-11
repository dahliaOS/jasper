// Copyright 2016 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';

import 'armadillo_drag_target.dart';
import 'armadillo_overlay.dart';
import 'display_mode.dart';
import 'elevation_constants.dart';
import 'nothing.dart';
import 'optional_wrapper.dart';
import 'panel.dart';
import 'place_holder_story.dart';
import 'simulated_fractionally_sized_box.dart';
import 'simulated_padding.dart';
import 'story.dart';
import 'story_bar.dart';
import 'story_cluster.dart';
import 'story_cluster_drag_data.dart';
import 'story_cluster_drag_feedback.dart';
import 'story_cluster_drag_state_model.dart';
import 'story_cluster_panels_model.dart';
import 'story_drag_transition_model.dart';
import 'story_full_size_simulated_sized_box.dart';
import 'story_model.dart';
import 'story_positioned.dart';

const double _kStoryBarMinimizedHeight = 4.0;
const double _kStoryBarMaximizedHeight = 32.0;
const double _kUnfocusedCornerRadius = 4.0;
const double _kFocusedCornerRadius = 8.0;

/// Set to true to give the focused tab twice the space as an unfocused tab.
const bool _kGrowFocusedTab = false;

/// Displays up to four stories in a grid-like layout.
class StoryPanels extends StatelessWidget {
  /// THe cluster whose stories will be displayed.
  final StoryCluster storyCluster;

  /// The progress of the cluster coming into focus.
  final double focusProgress;

  /// The overlay to use for this cluster's draggable.
  final GlobalKey<ArmadilloOverlayState> overlayKey;

  /// The widgets for this cluster's stories.
  final Map<StoryId, Widget> storyWidgets;

  /// If true, shadows will be painted behind each of the stories.
  final bool paintShadows;

  /// The size the cluster's widget should be.
  final Size currentSize;

  /// If true, this StoryPanel is currently being dragged
  final bool isBeingDragged;

  /// Constructor.
  StoryPanels({
    Key key,
    this.storyCluster,
    this.focusProgress,
    this.overlayKey,
    this.storyWidgets,
    this.paintShadows: false,
    this.currentSize,
    this.isBeingDragged: false,
  }) : super(key: key) {
    assert(() {
      Panel.haveFullCoverage(
        storyCluster.stories
            .map(
              (Story story) => story.panel,
            )
            .toList(),
      );
      return true;
    }());
  }

  /// Set elevation of this story cluster based on the state:
  /// * Dragged
  /// * Focused
  /// * InlinePreview
  /// * InlinePreviewHint
  /// * Nothing
  double _getElevation(double dragProgress) {
    if (isBeingDragged) {
      return Elevations.draggedStoryCluster * dragProgress;
    } else if (focusProgress > 0.0) {
      return Elevations.focusedStoryCluster * focusProgress;
    } else {
      // This will progressively animate the the elevation of a story cluster
      // when it goes from the inlinePreview hint state to the full blown inline
      // preview state.
      return ((storyCluster
                      .inlinePreviewScaleSimulationKey.currentState?.progress ??
                  0.0) +
              (storyCluster.inlinePreviewHintScaleSimulationKey.currentState
                      ?.progress ??
                  0.0)) *
          Elevations.storyClusterInlinePreview /
          2.0;
    }
  }

  @override
  Widget build(BuildContext context) =>
      new ScopedModelDescendant<StoryClusterPanelsModel>(
        builder: (
          BuildContext context,
          Widget child,
          StoryClusterPanelsModel storyClusterPanelsModel,
        ) =>
            _buildWidget(context),
      );

  Widget _buildWidget(BuildContext context) {
    /// Move placeholders to the beginning of the list when putting them in
    /// the stack to ensure they are behind the real stories in paint order.
    List<Story> sortedStories = new List<Story>.from(storyCluster.stories);
    sortedStories.sort(
      (Story a, Story b) => a.isPlaceHolder && !b.isPlaceHolder
          ? -1
          : !a.isPlaceHolder && b.isPlaceHolder ? 1 : 0,
    );

    List<Widget> stackChildren = <Widget>[];

    stackChildren.addAll(
      sortedStories.map(
        (Story story) {
          List<double> fractionalPadding = _getStoryBarPadding(
            story: story,
            width: currentSize.width,
          );

          return new StoryPositioned(
            storyBarMaximizedHeight: _kStoryBarMaximizedHeight,
            focusProgress: focusProgress,
            displayMode: storyCluster.displayMode,
            isFocused: (storyCluster.focusedStoryId == story.id),
            panel: story.panel,
            currentSize: currentSize,
            childContainerKey: story.positionedKey,
            child: new ScopedModelDescendant<StoryDragTransitionModel>(
              builder: (
                BuildContext context,
                Widget child,
                StoryDragTransitionModel storyDragTransitionModel,
              ) =>
                  _getStory(
                context,
                story,
                fractionalPadding[0],
                fractionalPadding[1],
                currentSize,
                storyDragTransitionModel.progress,
              ),
            ),
          );
        },
      ),
    );

    return new Stack(
      fit: StackFit.passthrough,
      overflow: Overflow.visible,
      children: stackChildren,
    );
  }

  Widget _getStoryBarDraggableWrapper({
    BuildContext context,
    Story story,
    Widget child,
  }) {
    final Widget storyWidget = storyWidgets[story.id];
    double initialDxOnDrag;
    bool onFirstHoverCalled = false;
    Map<StoryId, Panel> storyPanelsOnDrag = <StoryId, Panel>{};
    List<StoryId> storyListOrderOnDrag = <StoryId>[];
    DisplayMode displayModeOnDrag;
    return new OptionalWrapper(
      // Don't allow dragging if we're the only story.
      useWrapper: storyCluster.realStories.length > 1 && focusProgress == 1.0,
      builder: (BuildContext context, Widget child) =>
          new ArmadilloLongPressDraggable<StoryClusterDragData>(
        key: story.clusterDraggableKey,
        overlayKey: overlayKey,
        data: new StoryClusterDragData(
          id: story.clusterId,
          // If a story bar is dragged such that the story is split from the
          // cluster, we need to do some special work to make the drag
          // feedback act as if we've hovered over a location which causes
          // the original layout to be previewed.
          onFirstHover: () {
            if (!onFirstHoverCalled) {
              onFirstHoverCalled = true;

              // Reset cluster to original stories (using the saved off map
              // of story ids to panels in onDragStarted) with a place
              // holder for the split story.
              // Mirror drag feedback with this.

              // 1. Add a placeholder for the split story.
              storyCluster.add(
                story: new PlaceHolderStory(associatedStoryId: story.id),
                withPanel: storyPanelsOnDrag[story.id],
                atIndex: storyListOrderOnDrag.indexOf(story.id),
              );

              // 2. Resize all story panels to match original values.
              storyPanelsOnDrag.keys
                  .where((StoryId storyId) => storyId != story.id)
                  .forEach(
                    (StoryId storyId) => storyCluster.replaceStoryPanel(
                      storyId: storyId,
                      withPanel: storyPanelsOnDrag[storyId],
                    ),
                  );

              // 3. Add placeholders to feedback cluster.
              StoryCluster feedbackCluster =
                  StoryModel.of(context).getStoryCluster(story.clusterId);
              storyPanelsOnDrag.keys.forEach((StoryId storyId) {
                if (storyId != story.id) {
                  feedbackCluster.add(
                    story: new PlaceHolderStory(
                      associatedStoryId: storyId,
                      transparent: true,
                    ),
                    withPanel: storyPanelsOnDrag[storyId],
                  );
                }
              });

              // 4. Have feedback cluster mirror panels of cluster.
              feedbackCluster.replaceStoryPanel(
                storyId: story.id,
                withPanel: storyPanelsOnDrag[story.id],
              );

              // 5. Have feedback cluster mirror story order of cluster.
              feedbackCluster.mirrorStoryOrder(storyCluster.stories);

              // 6. Update feedback cluster display mode.
              feedbackCluster.displayMode = displayModeOnDrag;
            }
          },
          onNoTarget: () {
            // If we've no target we need to put everything back where it
            // was when we started dragging.

            // 1. Replace the place holder in this cluster with the original
            //    story.
            // 2. Restore story order.
            storyCluster.removePreviews();
            storyCluster.add(
              story: story,
              withPanel: storyPanelsOnDrag[story.id],
              atIndex: storyListOrderOnDrag.indexOf(story.id),
            );

            // 3. Restore panels.
            storyPanelsOnDrag.keys.forEach(
              (StoryId storyId) => storyCluster.replaceStoryPanel(
                storyId: storyId,
                withPanel: storyPanelsOnDrag[storyId],
              ),
            );

            // 4. Remove the split story cluster from the cluster list.
            StoryModel.of(context).remove(
              StoryModel.of(context).getStoryCluster(story.clusterId),
            );
            StoryModel.of(context).clearPlaceHolderStoryClusters();
          },
        ),
        onDragStarted: () {
          RenderBox box = story.positionedKey.currentContext.findRenderObject();
          Offset boxTopLeft = box.localToGlobal(Offset.zero);
          Offset boxBottomRight = box.localToGlobal(
            new Offset(box.size.width, box.size.height),
          );
          Rect initialBoundsOnDrag = new Rect.fromLTRB(
            boxTopLeft.dx,
            boxTopLeft.dy,
            boxBottomRight.dx,
            boxBottomRight.dy,
          );

          RenderBox storyBarBox =
              story.storyBarKey.currentContext.findRenderObject();
          Offset storyBarBoxTopLeft = storyBarBox.localToGlobal(Offset.zero);
          initialDxOnDrag = (storyCluster.displayMode == DisplayMode.tabs)
              ? -storyBarBoxTopLeft.dx
              : 0.0;

          // Store off panel configuration before splitting.
          storyPanelsOnDrag.clear();
          storyListOrderOnDrag.clear();
          storyCluster.stories.forEach((Story story) {
            storyPanelsOnDrag[story.id] = new Panel.from(story.panel);
            storyListOrderOnDrag.add(story.id);
          });
          displayModeOnDrag = storyCluster.displayMode;

          StoryModel.of(context).split(
            storyToSplit: story,
            from: storyCluster,
          );
          StoryClusterDragStateModel.of(context).addDragging(
            story.clusterId,
          );
          return initialBoundsOnDrag;
        },
        onDragEnded: () =>
            StoryClusterDragStateModel.of(context).removeDragging(
          story.clusterId,
        ),
        childWhenDragging: Nothing.widget,
        feedbackBuilder: (
          Offset localDragStartPoint,
          Rect initialBoundsOnDrag,
        ) {
          StoryCluster storyCluster =
              StoryModel.of(context).getStoryCluster(story.clusterId);

          return new StoryClusterDragFeedback(
            key: storyCluster.dragFeedbackKey,
            overlayKey: overlayKey,
            storyCluster: storyCluster,
            storyWidgets: <StoryId, Widget>{story.id: storyWidget},
            localDragStartPoint: localDragStartPoint,
            initialBounds: initialBoundsOnDrag,
            focusProgress: focusProgress,
            initDx: initialDxOnDrag,
          );
        },
        child: child,
      ),
      child: child,
    );
  }

  Widget _getStory(
    BuildContext context,
    Story story,
    double fractionalLeftPadding,
    double fractionalRightPadding,
    Size currentSize,
    double dragProgress,
  ) =>
      story.isPlaceHolder
          ? isBeingDragged
              ? Nothing.widget
              : new PhysicalModel(
                  elevation: _getElevation(dragProgress),
                  color: Colors.black,
                  child: story.builder(context),
                )
          : new Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                // The story bar that pushes down the story.
                new SimulatedPadding(
                  key: story.storyBarPaddingKey,
                  fractionalLeftPadding: fractionalLeftPadding,
                  fractionalRightPadding: fractionalRightPadding,
                  width: currentSize.width,
                  child: new GestureDetector(
                    onTap: () {
                      storyCluster.focusedStoryId = story.id;
                      // If we're in tabbed mode we want to jump the newly
                      // focused story's size to full size instead of animating
                      // it.
                      if (storyCluster.displayMode == DisplayMode.tabs) {
                        storyCluster.stories.forEach((Story story) {
                          bool storyFocused =
                              (storyCluster.focusedStoryId == story.id);
                          story.tabSizerKey.currentState
                              .jump(heightFactor: storyFocused ? 1.0 : 0.0);
                          if (storyFocused) {
                            story.positionedKey.currentState
                                .jumpFractionalHeight(1.0);
                          }
                        });
                      }
                    },
                    child: new ConstrainedBox(
                      constraints: const BoxConstraints(
                        maxHeight: _kStoryBarMaximizedHeight,
                      ),
                      child: _getStoryBarDraggableWrapper(
                        context: context,
                        story: story,
                        child: new StoryBar(
                          key: story.storyBarKey,
                          story: story,
                          minimizedHeight: _kStoryBarMinimizedHeight,
                          maximizedHeight: _kStoryBarMaximizedHeight,
                          focused: (storyCluster.displayMode ==
                                  DisplayMode.panels) ||
                              (storyCluster.focusedStoryId == story.id),
                          elevation: _getElevation(dragProgress),
                        ),
                      ),
                    ),
                  ),
                ),
                // The story itself.
                new Expanded(
                  child: new SimulatedFractionallySizedBox(
                    key: story.tabSizerKey,
                    alignment: FractionalOffset.topCenter,
                    heightFactor: (storyCluster.focusedStoryId == story.id ||
                            storyCluster.displayMode == DisplayMode.panels)
                        ? 1.0
                        : 0.0,
                    child: new Container(
                      color: story.themeColor,
                      child: new PhysicalModel(
                        color: story.themeColor,
                        elevation: _getElevation(dragProgress),
                        child: _getStoryContents(context, story),
                      ),
                    ),
                  ),
                ),
              ],
            );

  /// The scaled and clipped story.  When full size, the story will
  /// no longer be scaled or clipped.
  Widget _getStoryContents(BuildContext context, Story story) => new FittedBox(
        fit: BoxFit.cover,
        alignment: FractionalOffset.topCenter,
        child: new StoryFullSizeSimulatedSizedBox(
          displayMode: storyCluster.displayMode,
          panel: story.panel,
          containerKey: story.containerKey,
          storyBarMaximizedHeight: _kStoryBarMaximizedHeight,
          child: storyWidgets[story.id] ?? story.builder(context),
        ),
      );

  /// Returns the fractionalLeftPadding [0] and fractionalRightPadding [1] for
  /// the [story].  If [growFocused] is true, the focused story is given double
  /// the width of the other stories.
  List<double> _getStoryBarPadding({
    Story story,
    double width,
    bool growFocused: _kGrowFocusedTab,
  }) {
    if (storyCluster.displayMode == DisplayMode.panels) {
      return <double>[0.0, 0.0];
    }
    int storyBarGaps = storyCluster.stories.length - 1;
    int spaces = _kGrowFocusedTab
        ? storyCluster.stories.length + 1
        : storyCluster.stories.length;
    double gapFractionalWidth = 4.0 / width;
    double fractionalWidthPerSpace =
        (1.0 - (storyBarGaps * gapFractionalWidth)) / spaces;

    int index = storyCluster.stories.indexOf(story);
    double left = 0.0;
    for (int i = 0; i < storyCluster.stories.length; i++) {
      if (i == index) {
        break;
      }
      left += fractionalWidthPerSpace + gapFractionalWidth;
      if (growFocused &&
          storyCluster.stories[i].id == storyCluster.focusedStoryId) {
        left += fractionalWidthPerSpace;
      }
    }
    double fractionalWidth =
        growFocused && (story.id == storyCluster.focusedStoryId)
            ? 2.0 * fractionalWidthPerSpace
            : fractionalWidthPerSpace;
    double right = 1.0 - left - fractionalWidth;
    return <double>[left, right];
  }
}
