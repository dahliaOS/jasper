// Copyright 2016 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

import 'armadillo_drag_target.dart';
import 'armadillo_overlay.dart';
import 'display_mode.dart';
import 'nothing.dart';
import 'optional_wrapper.dart';
import 'panel.dart' as panel;
import 'panel_drag_targets.dart';
import 'panel_resizing_overlay.dart';
import 'story.dart';
import 'story_cluster.dart';
import 'story_cluster_drag_data.dart';
import 'story_cluster_drag_feedback.dart';
import 'story_cluster_drag_state_model.dart';
import 'story_cluster_panels_model.dart';
import 'story_drag_transition_model.dart';
import 'story_list.dart';
import 'story_panels.dart';
import 'story_rearrangement_scrim_model.dart';
import 'story_title.dart';

/// The height of the vertical gesture detector used to reveal the story bar in
/// full screen mode.
/// TODO(apwilson): Reduce the height of this.  It's large for now for ease of
/// use.
const double _kVerticalGestureDetectorHeight = 32.0;

const double _kStoryInlineTitleHeight = 20.0;

const double _kDragScale = 0.8;

/// The visual representation of a [Story].  A [Story] has a default size but
/// will expand to full size when it comes into focus.  [StoryClusterWidget]s
/// are intended to be children of [StoryList].
class StoryClusterWidget extends StatelessWidget {
  /// The cluster this [Widget] displays.
  final StoryCluster storyCluster;

  /// The progress of the focus animation for this cluster.
  final double focusProgress;

  /// Called when this cluster has another cluster dropped upon it.
  final VoidCallback onAccept;

  /// Called when this cluster is tapped.
  final VoidCallback onTap;

  /// Called when this cluster hovers over the top and bottom edges of the
  /// screen.
  final VoidCallback onVerticalEdgeHover;

  /// The key this [Widget]'s [ArmadilloLongPressDraggable] puts its avatar in.
  final GlobalKey<ArmadilloOverlayState> overlayKey;

  /// The [Widget]s for the stories in this cluster.
  final Map<StoryId, Widget> storyWidgets;

  /// Constructor.
  StoryClusterWidget({
    Key key,
    this.storyCluster,
    this.focusProgress,
    this.onAccept,
    this.onTap,
    this.onVerticalEdgeHover,
    this.overlayKey,
    this.storyWidgets,
  })
      : super(key: key);

  @override
  Widget build(BuildContext context) => storyCluster.wrapWithModels(
        child: _isUnfocused
            ? _getUnfocusedDragTargetChild(context)
            : _getStoryClusterWithInlineStoryTitle(context, true),
      );

  Widget _getUnfocusedDragTargetChild(BuildContext context) {
    return new OptionalWrapper(
      useWrapper: _isUnfocused && !storyCluster.isPlaceholder,
      builder: (BuildContext context, Widget child) =>
          new ArmadilloLongPressDraggable<StoryClusterDragData>(
            key: storyCluster.clusterDraggableKey,
            overlayKey: overlayKey,
            data: new StoryClusterDragData(id: storyCluster.id),
            childWhenDragging: Nothing.widget,
            onDragStarted: () {
              RenderBox box =
                  storyCluster.panelsKey.currentContext.findRenderObject();
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
              StoryClusterDragStateModel.of(context).addDragging(
                    storyCluster.id,
                  );
              return initialBoundsOnDrag;
            },
            onDragEnded: () =>
                StoryClusterDragStateModel.of(context).removeDragging(
                      storyCluster.id,
                    ),
            feedbackBuilder: (
              Offset localDragStartPoint,
              Rect initialBoundsOnDrag,
            ) =>
                new StoryClusterDragFeedback(
                  key: storyCluster.dragFeedbackKey,
                  overlayKey: overlayKey,
                  storyCluster: storyCluster,
                  storyWidgets: storyWidgets,
                  localDragStartPoint: localDragStartPoint,
                  initialBounds: initialBoundsOnDrag,
                  focusProgress: 0.0,
                ),
            child: child,
          ),
      child: _getStoryClusterWithInlineStoryTitle(
        context,
        false,
      ),
    );
  }

  Widget _getStoryClusterWithInlineStoryTitle(
          BuildContext context, bool focused) =>
      new Stack(
        fit: StackFit.passthrough,
        children: <Widget>[
          new Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              new Expanded(
                child: _getStoryCluster(context),
              ),
              new InlineStoryTitle(
                focusProgress: focusProgress,
                storyCluster: storyCluster,
              ),
            ],
          ),
          _focusOnTap,
        ],
      );

  /// The Story including its StoryBar.
  Widget _getStoryCluster(BuildContext context) => new LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          Size currentSize = new Size(
            constraints.maxWidth,
            constraints.maxHeight,
          );
          // If the current size is too small to support paneling (only one row
          // and one column is supported) we want to hide the story bars when
          // we're in focus and the user starts to interact with the story.
          // A drag down from the top will bring back the story bars in this
          // situation.
          return new OptionalWrapper(
            useWrapper: panel.maxRows(currentSize) == 1 &&
                panel.maxColumns(currentSize) == 1 &&
                _isFocused,
            builder: (BuildContext context, Widget child) => new Listener(
                  behavior: HitTestBehavior.translucent,
                  onPointerDown: (PointerDownEvent event) =>
                      storyCluster.hideStoryBars(),
                  child: new Stack(
                    fit: StackFit.passthrough,
                    children: <Widget>[
                      new Positioned.fill(child: child),
                      new Positioned(
                        top: 0.0,
                        left: 0.0,
                        right: 0.0,
                        height: _kVerticalGestureDetectorHeight,
                        child: new GestureDetector(
                          behavior: HitTestBehavior.translucent,
                          onVerticalDragUpdate: (DragUpdateDetails details) =>
                              storyCluster.showStoryBars(),
                        ),
                      ),
                    ],
                  ),
                ),
            child: new PanelDragTargets(
              key: storyCluster.clusterDragTargetsKey,
              scale: _kDragScale,
              focusProgress: focusProgress,
              currentSize: currentSize,
              storyCluster: storyCluster,
              onAccept: onAccept,
              onVerticalEdgeHover: onVerticalEdgeHover,
              child: new ScopedModelDescendant<StoryClusterPanelsModel>(
                builder: (
                  BuildContext context,
                  Widget child,
                  StoryClusterPanelsModel storyClusterPanelsModel,
                ) =>
                    new OptionalWrapper(
                      useWrapper: _isFocused &&
                          storyCluster.displayMode == DisplayMode.panels,
                      builder: (BuildContext context, Widget child) =>
                          new PanelResizingOverlay(
                            storyCluster: storyCluster,
                            currentSize: currentSize,
                            onPanelsChanged: () =>
                                storyClusterPanelsModel.notifyListeners(),
                            child: child,
                          ),
                      child: new StoryPanels(
                        key: storyCluster.panelsKey,
                        storyCluster: storyCluster,
                        focusProgress: focusProgress,
                        overlayKey: overlayKey,
                        storyWidgets: storyWidgets,
                        currentSize: currentSize,
                      ),
                    ),
              ),
            ),
          );
        },
      );

  Widget get _focusOnTap => new Positioned(
        left: 0.0,
        right: 0.0,
        top: 0.0,
        bottom: 0.0,
        child: new Offstage(
          offstage: !_isUnfocused,
          child: new GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTap: onTap,
          ),
        ),
      );

  bool get _isUnfocused => focusProgress == 0.0;
  bool get _isFocused => focusProgress == 1.0;
}

/// The Story Title that hovers below the story itself.
class InlineStoryTitle extends StatelessWidget {
  /// The progress of [storyCluster] coming into focus.
  final double focusProgress;

  /// The cluster this story title represents.
  final StoryCluster storyCluster;

  /// Constructor.
  InlineStoryTitle({this.focusProgress, this.storyCluster});

  /// THe height the inline story title should be for the given [focusProgress].
  static double getHeight(double focusProgress) =>
      lerpDouble(_kStoryInlineTitleHeight, 0.0, focusProgress);

  @override
  Widget build(BuildContext context) =>
      new ScopedModelDescendant<StoryDragTransitionModel>(
        builder: (
          BuildContext context,
          Widget child,
          StoryDragTransitionModel storyDragTransitionModel,
        ) =>
            new ScopedModelDescendant<StoryRearrangementScrimModel>(
              builder: (
                BuildContext context,
                Widget child,
                StoryRearrangementScrimModel storyRearrangementScrimModel,
              ) =>
                  new Opacity(
                    opacity: lerpDouble(
                      lerpDouble(1.0, 0.5, storyDragTransitionModel.progress),
                      0.0,
                      storyRearrangementScrimModel.progress,
                    ),
                    child: child,
                  ),
              child: child,
            ),
        child: new Container(
          height: getHeight(focusProgress),
          child: new OverflowBox(
            minHeight: _kStoryInlineTitleHeight,
            maxHeight: _kStoryInlineTitleHeight,
            child: new Padding(
              padding: const EdgeInsets.only(
                left: 8.0,
                right: 8.0,
                top: 4.0,
              ),
              child: new Align(
                alignment: FractionalOffset.bottomLeft,
                child: new StoryTitle(
                  title: storyCluster.title,
                  opacity: 1.0 - focusProgress,
                ),
              ),
            ),
          ),
        ),
      );
}
