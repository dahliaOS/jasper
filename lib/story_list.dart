// Copyright 2016 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';
import 'package:sysui_widgets/rk4_spring_simulation.dart';

import 'armadillo_overlay.dart';
import 'nothing.dart';
import 'render_story_list_body.dart';
import 'simulation_builder.dart';
import 'size_model.dart';
import 'story.dart';
import 'story_cluster.dart';
import 'story_cluster_widget.dart';
import 'story_drag_transition_model.dart';
import 'story_list_body_parent_data.dart';
import 'story_list_layout.dart';
import 'story_model.dart';
import 'story_rearrangement_scrim_model.dart';

const double _kStoryInlineTitleHeight = 20.0;

const RK4SpringDescription _kInlinePreviewSimulationDesc =
    const RK4SpringDescription(tension: 900.0, friction: 50.0);

/// Displays the [StoryCluster]s of it's ancestor [StoryModel].
class StoryList extends StatelessWidget {
  /// Called when the story list scrolls.
  final ValueChanged<double> onScroll;

  /// Called when a story cluster begins to take focus.  This is when its
  /// focus animation begins.
  final VoidCallback onStoryClusterFocusStarted;

  /// Called when a story cluster has taken focus. This is when its
  /// focus animation finishes.
  final OnStoryClusterEvent onStoryClusterFocusCompleted;

  /// The amount to shift up the list when at scroll position 0.0.
  final double bottomPadding;

  /// Controls the scrolling of this list.
  final ScrollController scrollController;

  /// The overlay dragged stories should place their avatars when dragging.
  final GlobalKey<ArmadilloOverlayState> overlayKey;

  /// Called when a cluster is dragged to the top or bottom of the screen for
  /// a certain length of time.
  final VoidCallback onStoryClusterVerticalEdgeHover;

  /// If true, children of the list will be blurred when we're inline
  /// previewing.
  final bool blurScrimmedChildren;

  /// Passes the parent size to all its [StoryClusterWidget]s
  final SizeModel _sizeModel;

  /// Constructor.
  /// [parentSize] is the parent size when this [StoryList] was created.
  StoryList({
    Key key,
    this.scrollController,
    this.overlayKey,
    this.bottomPadding,
    this.onScroll,
    this.onStoryClusterFocusStarted,
    this.onStoryClusterFocusCompleted,
    Size parentSize,
    this.onStoryClusterVerticalEdgeHover,
    this.blurScrimmedChildren,
  })  : _sizeModel = new SizeModel(parentSize),
        super(key: key);

  @override
  Widget build(BuildContext context) => new ScopedModelDescendant<StoryModel>(
        builder: (
          BuildContext context,
          Widget child,
          StoryModel storyModel,
        ) {
          // IMPORTANT:  In order for activation of inactive stories from suggestions
          // to work we must have them in the widget tree.
          List<Widget> stackChildren = new List<Widget>.from(
            storyModel.inactiveStoryClusters.map(
              (StoryCluster storyCluster) => new Positioned(
                width: 0.0,
                height: 0.0,
                child: new SimulationBuilder(
                  key: storyCluster.focusSimulationKey,
                  initValue: 0.0,
                  targetValue: 1.0,
                  builder: (BuildContext context, double progress) =>
                      _createStoryCluster(
                    storyModel.activeSortedStoryClusters,
                    storyCluster,
                    0.0,
                    storyCluster.buildStoryWidgets(context),
                  ),
                ),
              ),
            ),
          );

          stackChildren.add(
            new Positioned(
              top: 0.0,
              left: 0.0,
              bottom: 0.0,
              right: 0.0,
              child: new LayoutBuilder(
                builder: (BuildContext context, BoxConstraints constraints) {
                  _sizeModel.size = new Size(
                    constraints.maxWidth,
                    constraints.maxHeight,
                  );
                  return Nothing.widget;
                },
              ),
            ),
          );

          stackChildren.add(_createScrollableList(storyModel));

          stackChildren.add(new ArmadilloOverlay(key: overlayKey));

          return new ScopedModel<SizeModel>(
            model: _sizeModel,
            child: new Stack(
              fit: StackFit.passthrough,
              children: stackChildren,
            ),
          );
        },
      );

  Widget _createScrollableList(StoryModel storyModel) =>
      new NotificationListener<ScrollNotification>(
        onNotification: (ScrollNotification notification) {
          if (notification is ScrollUpdateNotification &&
              notification.depth == 0) {
            onScroll?.call(notification.metrics.extentBefore);
          }
          return false;
        },
        child: new SingleChildScrollView(
          reverse: true,
          controller: scrollController,
          child: new ScopedModelDescendant<SizeModel>(
            builder: (_, __, SizeModel sizeModel) =>
                new ScopedModelDescendant<StoryRearrangementScrimModel>(
              builder: (
                _,
                __,
                StoryRearrangementScrimModel storyRearrangementScrimModel,
              ) =>
                  new ScopedModelDescendant<StoryDragTransitionModel>(
                builder: (
                  BuildContext context,
                  _,
                  StoryDragTransitionModel storyDragTransitionModel,
                ) =>
                    new AnimatedBuilder(
                  animation: scrollController,
                  builder: (BuildContext context, Widget child) =>
                      new _StoryListBody(
                    children: new List<Widget>.generate(
                      storyModel.activeSortedStoryClusters.length,
                      (int index) => _createFocusableStoryCluster(
                        context,
                        storyModel.activeSortedStoryClusters,
                        storyModel.activeSortedStoryClusters[index],
                        storyModel.activeSortedStoryClusters[index]
                            .buildStoryWidgets(
                          context,
                        ),
                      ),
                    ),
                    listHeight: storyModel.listHeight,
                    scrollOffset: scrollController?.offset ?? 0.0,
                    bottomPadding: bottomPadding,
                    parentSize: sizeModel.size,
                    scrimColor: storyRearrangementScrimModel.scrimColor,
                    blurScrimmedChildren: blurScrimmedChildren,
                    storyDragTransitionModelProgress:
                        storyDragTransitionModel.progress,
                  ),
                ),
              ),
            ),
          ),
        ),
      );

  Widget _createFocusableStoryCluster(
    BuildContext context,
    List<StoryCluster> storyClusters,
    StoryCluster storyCluster,
    Map<StoryId, Widget> storyWidgets,
  ) =>
      new SimulationBuilder(
        key: storyCluster.inlinePreviewHintScaleSimulationKey,
        springDescription: _kInlinePreviewSimulationDesc,
        initValue: 0.0,
        targetValue: 0.0,
        builder: (
          BuildContext context,
          double inlinePreviewHintScaleProgress,
        ) =>
            new SimulationBuilder(
          key: storyCluster.inlinePreviewScaleSimulationKey,
          springDescription: _kInlinePreviewSimulationDesc,
          initValue: 0.0,
          targetValue: 0.0,
          builder: (BuildContext context, double inlinePreviewScaleProgress) =>
              new SimulationBuilder(
            key: storyCluster.focusSimulationKey,
            initValue: 0.0,
            targetValue: 0.0,
            onSimulationChanged: (double focusProgress, bool isDone) {
              if (focusProgress == 1.0 && isDone) {
                onStoryClusterFocusCompleted?.call(storyCluster);
              }
            },
            builder: (BuildContext context, double focusProgress) =>
                new _StoryListChild(
              storyLayout: storyCluster.storyLayout,
              focusProgress: focusProgress,
              inlinePreviewScaleProgress: inlinePreviewScaleProgress,
              inlinePreviewHintScaleProgress: inlinePreviewHintScaleProgress,
              child: _createStoryCluster(
                storyClusters,
                storyCluster,
                focusProgress,
                storyWidgets,
              ),
            ),
          ),
        ),
      );

  Widget _createStoryCluster(
    List<StoryCluster> storyClusters,
    StoryCluster storyCluster,
    double progress,
    Map<StoryId, Widget> storyWidgets,
  ) =>
      new RepaintBoundary(
        child: new StoryClusterWidget(
          overlayKey: overlayKey,
          focusProgress: progress,
          storyCluster: storyCluster,
          onAccept: () {
            if (!_inFocus(storyCluster)) {
              _onGainFocus(storyClusters, storyCluster);
            }
          },
          onTap: () => _onGainFocus(storyClusters, storyCluster),
          onVerticalEdgeHover: onStoryClusterVerticalEdgeHover,
          storyWidgets: storyWidgets,
        ),
      );

  bool _inFocus(StoryCluster s) =>
      (s.focusSimulationKey.currentState?.progress ?? 0.0) > 0.0;

  void _onGainFocus(
    List<StoryCluster> storyClusters,
    StoryCluster storyCluster,
  ) {
    // Defocus any focused stories.
    storyClusters.forEach((StoryCluster s) {
      if (_inFocus(s)) {
        s.unFocus();
      }
    });

    // Bring tapped story into focus.
    storyCluster.focusSimulationKey.currentState?.target = 1.0;

    storyCluster.maximizeStoryBars();

    onStoryClusterFocusStarted?.call();
  }
}

class _StoryListBody extends MultiChildRenderObjectWidget {
  final double _scrollOffset;
  final double _bottomPadding;
  final double _listHeight;
  final Size _parentSize;
  final Color _scrimColor;
  final bool _blurScrimmedChildren;
  final double _storyDragTransitionModelProgress;

  /// Constructor.
  _StoryListBody({
    Key key,
    List<Widget> children,
    double scrollOffset,
    double bottomPadding,
    double listHeight,
    Size parentSize,
    Color scrimColor,
    bool blurScrimmedChildren,
    double storyDragTransitionModelProgress,
  })  : _scrollOffset = scrollOffset,
        _bottomPadding = bottomPadding,
        _listHeight = listHeight,
        _parentSize = parentSize,
        _scrimColor = scrimColor,
        _blurScrimmedChildren = blurScrimmedChildren,
        _storyDragTransitionModelProgress = storyDragTransitionModelProgress,
        super(key: key, children: children);

  @override
  RenderStoryListBody createRenderObject(BuildContext context) =>
      new RenderStoryListBody(
        parentSize: _parentSize,
        scrollOffset: _scrollOffset,
        bottomPadding: _bottomPadding,
        listHeight: _listHeight,
        scrimColor: _scrimColor,
        blurScrimmedChildren: _blurScrimmedChildren,
        liftScale: lerpDouble(
          1.0,
          0.9,
          _storyDragTransitionModelProgress,
        ),
      );

  @override
  void updateRenderObject(
    BuildContext context,
    RenderStoryListBody renderObject,
  ) {
    renderObject
      ..axisDirection = AxisDirection.down
      ..parentSize = _parentSize
      ..scrollOffset = _scrollOffset
      ..bottomPadding = _bottomPadding
      ..listHeight = _listHeight
      ..scrimColor = _scrimColor
      ..blurScrimmedChildren = _blurScrimmedChildren
      ..liftScale = lerpDouble(
        1.0,
        0.9,
        _storyDragTransitionModelProgress,
      );
  }
}

class _StoryListChild extends ParentDataWidget<_StoryListBody> {
  final StoryLayout _storyLayout;
  final double _focusProgress;
  final double _inlinePreviewScaleProgress;
  final double _inlinePreviewHintScaleProgress;

  _StoryListChild({
    Widget child,
    StoryLayout storyLayout,
    double focusProgress,
    double inlinePreviewScaleProgress,
    double inlinePreviewHintScaleProgress,
  })  : _storyLayout = storyLayout,
        _focusProgress = focusProgress,
        _inlinePreviewScaleProgress = inlinePreviewScaleProgress,
        _inlinePreviewHintScaleProgress = inlinePreviewHintScaleProgress,
        super(child: child);

  @override
  void applyParentData(RenderObject renderObject) {
    assert(renderObject.parentData is StoryListBodyParentData);
    final StoryListBodyParentData parentData = renderObject.parentData;
    parentData
      ..storyLayout = _storyLayout
      ..focusProgress = _focusProgress
      ..inlinePreviewScaleProgress = _inlinePreviewScaleProgress
      ..inlinePreviewHintScaleProgress = _inlinePreviewHintScaleProgress;
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder description) {
    super.debugFillProperties(description);
    description.add(
      new DiagnosticsProperty<StoryLayout>(
        'storyLayout',
        _storyLayout,
      ),
    );
    description.add(
      new DoubleProperty(
        'focusProgress',
        _focusProgress,
      ),
    );
    description.add(
      new DoubleProperty(
        'inlinePreviewScaleProgress',
        _inlinePreviewScaleProgress,
      ),
    );
    description.add(
      new DoubleProperty(
        'inlinePreviewHintScaleProgress',
        _inlinePreviewHintScaleProgress,
      ),
    );
  }
}
