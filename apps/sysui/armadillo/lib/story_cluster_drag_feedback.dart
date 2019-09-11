// Copyright 2016 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:math' as math;
import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';

import 'armadillo_overlay.dart';
import 'display_mode.dart';
import 'simulated_sized_box.dart';
import 'simulated_transform.dart';
import 'size_model.dart';
import 'story.dart';
import 'story_cluster.dart';
import 'story_cluster_drag_state_model.dart';
import 'story_cluster_panels_model.dart';
import 'story_cluster_widget.dart';
import 'story_list_layout.dart';
import 'story_panels.dart';

const double _kStoryBarMinimizedHeight = 4.0;
const double _kStoryBarMaximizedHeight = 32.0;
const double _kUnfocusedCornerRadius = 4.0;
const double _kFocusedCornerRadius = 8.0;

/// Displays a representation of a StoryCluster while being dragged.
class StoryClusterDragFeedback extends StatefulWidget {
  /// The cluster being dragged.
  final StoryCluster storyCluster;

  /// The key of the overlay this feedback has been added to.
  final GlobalKey<ArmadilloOverlayState> overlayKey;

  /// The widgets for the stories in the cluster being dragged.
  final Map<StoryId, Widget> storyWidgets;

  /// Where the drag began relative to the cluster's widget's coordinate system.
  final Offset localDragStartPoint;

  /// The bounds of the cluster's widget when the drag begin.
  final Rect initialBounds;

  /// The focus progress of the cluster's widget.
  final double focusProgress;

  /// The initial X offset of the cluster's widget.
  final double initDx;

  /// Constructor.
  StoryClusterDragFeedback({
    Key key,
    this.overlayKey,
    this.storyCluster,
    this.storyWidgets,
    this.localDragStartPoint,
    this.initialBounds,
    this.focusProgress,
    this.initDx: 0.0,
  })
      : super(key: key) {
    assert(overlayKey != null);
    assert(storyCluster != null);
    assert(storyWidgets != null);
    assert(localDragStartPoint != null);
    assert(initialBounds != null);
    assert(focusProgress != null);
  }

  @override
  StoryClusterDragFeedbackState createState() =>
      new StoryClusterDragFeedbackState();
}

/// Holds the necessary state for performing transitions to and from its
/// [StoryClusterDragFeedback.storyCluster]'s being a candidate in a new
/// cluster.
class StoryClusterDragFeedbackState extends State<StoryClusterDragFeedback> {
  final GlobalKey<SimulatedSizedBoxState> _childKey =
      new GlobalKey<SimulatedSizedBoxState>();
  StoryClusterDragStateModel _storyClusterDragStateModel;
  List<Story> _originalStories;
  DisplayMode _originalDisplayMode;
  bool _wasAcceptable = false;

  @override
  void initState() {
    super.initState();
    _storyClusterDragStateModel = StoryClusterDragStateModel.of(context);
    _storyClusterDragStateModel.addListener(_updateStoryBars);

    // Store off original stories and display state and on change to
    // isAccepted, revert to initial story locations and
    // display state.
    _originalStories = widget.storyCluster.stories;
    _originalDisplayMode = widget.storyCluster.displayMode;
  }

  @override
  void dispose() {
    _storyClusterDragStateModel.removeListener(_updateStoryBars);
    super.dispose();
  }

  void _updateStoryBars() {
    if (!mounted) {
      return;
    }
    if (!StoryClusterDragStateModel.of(context).isDragging) {
      return;
    }

    if (StoryClusterDragStateModel.of(context).isAcceptable &&
        widget.storyCluster.previewStories.isNotEmpty) {
      widget.storyCluster.maximizeStoryBars();
    } else {
      widget.storyCluster.minimizeStoryBars();
    }

    if (_wasAcceptable &&
        !StoryClusterDragStateModel.of(context).isAcceptable) {
      // Revert to initial story locations and display state.
      widget.storyCluster.removePreviews();
      _originalStories.forEach((Story story) {
        widget.storyCluster.replaceStoryPanel(
          storyId: story.id,
          withPanel: story.panel,
        );
      });
      widget.storyCluster.displayMode = _originalDisplayMode;
    }
    _wasAcceptable = StoryClusterDragStateModel.of(context).isAcceptable;
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

  Widget _buildWidget(BuildContext context) =>
      new ScopedModelDescendant<SizeModel>(
        builder: (BuildContext context, Widget child, SizeModel sizeModel) =>
            new ScopedModelDescendant<StoryClusterDragStateModel>(
              builder: (BuildContext context, Widget child,
                  StoryClusterDragStateModel storyClusterDragStateModel) {
                _updateStoryBars();

                double width;
                double height;
                double childScale;
                double inlinePreviewScale =
                    StoryListLayout.getInlinePreviewScale(
                  sizeModel.size,
                );
                bool isAcceptable = storyClusterDragStateModel.isAcceptable;

                if (isAcceptable &&
                    widget.storyCluster.previewStories.isNotEmpty) {
                  width = sizeModel.size.width;
                  height = sizeModel.size.height;
                  childScale =
                      lerpDouble(inlinePreviewScale, 0.7, widget.focusProgress);
                } else {
                  width = widget.storyCluster.storyLayout.size.width;
                  height = widget.storyCluster.storyLayout.size.height;
                  childScale = 1.0;
                }
                double targetWidth = (_childKey.currentState == null
                        ? widget.initialBounds.width
                        : width) *
                    childScale;
                double targetHeight = (_childKey.currentState == null
                        ? widget.initialBounds.height
                        : height) *
                    childScale;

                // Determine the fractional bounds of the real stories in this cluster.
                // We do this so we can properly position the drag feedback under the user's
                // finger when in preview mode.
                double realStoriesFractionalLeft = 1.0;
                double realStoriesFractionalRight = 0.0;
                double realStoriesFractionalTop = 1.0;
                double realStoriesFractionalBottom = 0.0;

                widget.storyCluster.realStories.forEach((Story story) {
                  realStoriesFractionalLeft =
                      math.min(realStoriesFractionalLeft, story.panel.left);
                  realStoriesFractionalRight =
                      math.max(realStoriesFractionalRight, story.panel.right);
                  realStoriesFractionalTop =
                      math.min(realStoriesFractionalTop, story.panel.top);
                  realStoriesFractionalBottom =
                      math.max(realStoriesFractionalBottom, story.panel.bottom);
                });

                double realStoriesFractionalCenterX =
                    realStoriesFractionalLeft +
                        (realStoriesFractionalRight -
                                realStoriesFractionalLeft) /
                            2.0;
                double realStoriesFractionalCenterY = realStoriesFractionalTop +
                    (realStoriesFractionalBottom - realStoriesFractionalTop) /
                        2.0;
                double realStoriesFractionalTopY = realStoriesFractionalTop;

                List<Story> stories = widget.storyCluster.stories;
                int realTabStartingIndex = 0;
                for (int i = 0; i < stories.length; i++) {
                  if (!stories[i].isPlaceHolder) {
                    break;
                  }
                  realTabStartingIndex++;
                }
                int totalTabs = stories.length;
                int realStories = widget.storyCluster.realStories.length;
                double realStoriesOffset = realStories / totalTabs / 2.0;
                double tabFractionalXOffset =
                    realTabStartingIndex / totalTabs + realStoriesOffset;

                // Since the user begins the drag at widget.localDragStartPoint and we want
                // to move the story to a better visual position when previewing we animate
                // its translation when isAcceptable is true.
                // In tab mode we center on the story's story bar.
                // In panel mode we center on the story itself.
                double newDx = (isAcceptable ||
                        widget.localDragStartPoint.dx > targetWidth)
                    ? (widget.storyCluster.displayMode == DisplayMode.tabs)
                        ? widget.localDragStartPoint.dx -
                            targetWidth * tabFractionalXOffset
                        : widget.localDragStartPoint.dx -
                            targetWidth * realStoriesFractionalCenterX
                    : 0.0;
                double newDy = (isAcceptable ||
                        widget.localDragStartPoint.dy > targetHeight)
                    ? (widget.storyCluster.displayMode == DisplayMode.tabs)
                        ? widget.localDragStartPoint.dy -
                            targetHeight * realStoriesFractionalTopY -
                            childScale * _kStoryBarMaximizedHeight
                        : widget.localDragStartPoint.dy -
                            targetHeight * realStoriesFractionalCenterY
                    : 0.0;

                Size simulatedSizedBoxCurrentSize =
                    _childKey.currentState?.size;
                Size panelsCurrentSize = simulatedSizedBoxCurrentSize == null
                    ? new Size(targetWidth, targetHeight)
                    : new Size(
                        simulatedSizedBoxCurrentSize.width,
                        simulatedSizedBoxCurrentSize.height -
                            InlineStoryTitle.getHeight(widget.focusProgress),
                      );

                return new SimulatedTransform(
                  initDx: widget.initDx,
                  targetDx: newDx,
                  targetDy: newDy,
                  child: new SimulatedSizedBox(
                    key: _childKey,
                    width: targetWidth,
                    height: targetHeight +
                        InlineStoryTitle.getHeight(widget.focusProgress),
                    child: new Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        new Expanded(
                          child: new StoryPanels(
                            key: widget.storyCluster.panelsKey,
                            storyCluster: widget.storyCluster,
                            focusProgress: 0.0,
                            overlayKey: widget.overlayKey,
                            storyWidgets: widget.storyWidgets,
                            paintShadows: true,
                            currentSize: panelsCurrentSize,
                            isBeingDragged: true,
                          ),
                        ),
                        new InlineStoryTitle(
                          focusProgress: widget.focusProgress,
                          storyCluster: widget.storyCluster,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
      );
}
