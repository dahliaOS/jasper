// Copyright 2016 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:sysui_widgets/rk4_spring_simulation.dart';
import 'package:sysui_widgets/ticking_state.dart';

import 'armadillo_drag_target.dart';
import 'candidate_info.dart';
import 'cluster_layout.dart';
import 'debug_model.dart';
import 'drag_direction.dart';
import 'panel.dart';
import 'panel_drag_target.dart';
import 'panel_drag_target_generator.dart';
import 'panel_event_handler.dart';
import 'place_holder_story.dart';
import 'simulated_fractional.dart';
import 'size_model.dart';
import 'story.dart';
import 'story_cluster.dart';
import 'story_cluster_drag_data.dart';
import 'story_cluster_drag_state_model.dart';
import 'story_cluster_id.dart';
import 'story_cluster_stories_model.dart';
import 'story_model.dart';
import 'target_overlay.dart';
import 'target_influence_overlay.dart';

const double _kUnfocusedCornerRadius = 4.0;
const double _kFocusedCornerRadius = 8.0;
const int _kMaxStoriesPerCluster = 100;

const RK4SpringDescription _kScaleSimulationDesc =
    const RK4SpringDescription(tension: 450.0, friction: 50.0);

const Duration _kHoverDuration = const Duration(milliseconds: 400);
const Duration _kVerticalEdgeHoverDuration = const Duration(
  milliseconds: 1000,
);

const double _kVerticalFlingToDiscardSpeedThreshold = 2000.0;

/// Wraps its [child] in an [ArmadilloDragTarget] which tracks any
/// [ArmadilloLongPressDraggable]'s above it such that they can be dropped on
/// specific parts of [storyCluster]'s [StoryCluster.stories]'s [Panel]s.
///
/// When an [ArmadilloLongPressDraggable] is above, [child] will be scaled down
/// slightly depending on [focusProgress].
/// [onVerticalEdgeHover] will be called whenever a cluster hovers over the top
/// or bottom targets.
class PanelDragTargets extends StatefulWidget {
  /// The cluster the drag targets are being created for.
  final StoryCluster storyCluster;

  /// The cluster's widget.
  final Widget child;

  /// The scale the cluster's widget should be when a candidate cluster is
  /// dragged over it.
  final double scale;

  /// The progress of the cluster coming into focus.
  final double focusProgress;

  /// Called when a candidate is accepted by one of the drag targets.
  final VoidCallback onAccept;

  /// Called when a candidate hovers over the top or bottom edge of this
  /// widget.
  final VoidCallback onVerticalEdgeHover;

  /// The current size of the cluster's widget.
  final Size currentSize;

  /// Constructor.
  PanelDragTargets({
    Key key,
    this.storyCluster,
    this.child,
    this.scale,
    this.focusProgress,
    this.onAccept,
    this.onVerticalEdgeHover,
    this.currentSize,
  }) : super(key: key);

  @override
  _PanelDragTargetsState createState() => new _PanelDragTargetsState();
}

class _PanelDragTargetsState extends TickingState<PanelDragTargets> {
  final PanelDragTargetGenerator _panelDragTargetGenerator =
      new PanelDragTargetGenerator();
  final Set<PanelDragTarget> _targets = new Set<PanelDragTarget>();

  final Map<StoryClusterId, CandidateInfo> _trackedCandidates =
      <StoryClusterId, CandidateInfo>{};
  final RK4SpringSimulation _scaleSimulation = new RK4SpringSimulation(
    initValue: 1.0,
    desc: _kScaleSimulationDesc,
  );

  /// When candidates are dragged over this drag target we add
  /// [PlaceHolderStory]s to the [StoryCluster] this target is representing.
  /// To ensure we can return to the original layout of the stories if the
  /// candidates leave without being dropped we store off the original story
  /// list, the original focus story ID, and the original display mode.
  ClusterLayout _originalClusterLayout;

  bool _hadCandidates = false;

  /// Candidates become valid after hovering over this drag target for
  /// [_kHoverDuration]
  bool _candidatesValid = false;

  /// The timer which triggers candidate validity when [_kHoverDuration]
  /// elapses.
  Timer _candidateValidityTimer;

  /// The timer which triggers [PanelDragTargets.onVerticalEdgeHover] when
  /// [_kVerticalEdgeHoverDuration] elapses.
  Timer _verticalEdgeHoverTimer;

  PanelEventHandler panelEventHandler;

  @override
  void initState() {
    super.initState();
    _originalClusterLayout = new ClusterLayout.from(widget.storyCluster);
    panelEventHandler = new PanelEventHandler(widget.storyCluster);
    _populateTargets();
  }

  @override
  void didUpdateWidget(PanelDragTargets oldWidget) {
    super.didUpdateWidget(oldWidget);
    panelEventHandler = new PanelEventHandler(widget.storyCluster);
    if (oldWidget.storyCluster.id != widget.storyCluster.id) {
      _originalClusterLayout = new ClusterLayout.from(widget.storyCluster);
    }
    if (oldWidget.focusProgress != widget.focusProgress ||
        oldWidget.currentSize != widget.currentSize) {
      _populateTargets();
    }
  }

  @override
  Widget build(BuildContext context) =>
      new ScopedModelDescendant<StoryClusterStoriesModel>(
        builder: (
          BuildContext context,
          Widget child,
          StoryClusterStoriesModel storyClusterStoriesModel,
        ) {
          _populateTargets();
          return _buildWidget(context);
        },
      );

  Widget _buildWidget(BuildContext context) =>
      new ArmadilloDragTarget<StoryClusterDragData>(
        onWillAccept: (StoryClusterDragData data, _) =>
            widget.storyCluster.id != data.id,
        onAccept: (StoryClusterDragData data, _, Velocity velocity) =>
            _onAccept(
          data,
          velocity,
        ),
        builder: (
          BuildContext context,
          Map<StoryClusterDragData, Offset> candidates,
          Map<dynamic, Offset> rejectedData,
        ) =>
            _build(candidates),
      );

  @override
  bool handleTick(double elapsedSeconds) {
    _scaleSimulation.elapseTime(elapsedSeconds);
    return !_scaleSimulation.isDone;
  }

  void _onAccept(StoryClusterDragData data, Velocity velocity) {
    StoryCluster storyCluster = StoryModel.of(context).getStoryCluster(data.id);

    // When focused, if the cluster has been flung, don't call the target
    // onDrop, instead just adjust the appropriate story bars.  Since a dragged
    // story cluster is already not a part of this cluster, not calling onDrop
    // ensures it will not be added to this cluster.
    if (!_inTimeline &&
        velocity.pixelsPerSecond.dy.abs() >
            _kVerticalFlingToDiscardSpeedThreshold) {
      storyCluster.removePreviews();
      storyCluster.minimizeStoryBars();
      return;
    }

    _transposeToChildCoordinates(storyCluster.stories);

    widget.onAccept?.call();

    // If a target hasn't been chosen yet, default to dropping on the story bar
    // target as that's always there.
    if (_trackedCandidates[storyCluster.id]?.closestTarget?.onDrop != null) {
      _trackedCandidates[storyCluster.id]
          .closestTarget
          .onDrop(context, storyCluster);
    } else {
      if (!_inTimeline && data.onNoTarget != null) {
        data.onNoTarget.call();
      } else {
        panelEventHandler.onStoryBarDrop(
          context: context,
          storyCluster: storyCluster,
        );
      }
    }
    _updateFocusedStoryId(storyCluster);
  }

  bool get _inTimeline => widget.focusProgress == 0.0;

  /// [candidates] are the clusters that are currently
  /// being dragged over this drag target with their associated local
  /// position.
  Widget _build(Map<StoryClusterDragData, Offset> candidates) {
    // Update the acceptance of a dragged StoryCluster.  If we have no
    // candidates we're not accepting it.  If we do have condidates and we're
    // focused we do accept it.  If we're in the timeline we need to wait for
    // the validity timer to go off before accepting it.
    if (candidates.isEmpty) {
      StoryClusterDragStateModel.of(context).removeAcceptance(
        widget.storyCluster.id,
      );
    } else if (!_inTimeline) {
      StoryClusterDragStateModel.of(context).addAcceptance(
        widget.storyCluster.id,
      );
    }

    if (_inTimeline) {
      if (candidates.isEmpty) {
        _candidateValidityTimer?.cancel();
        _candidateValidityTimer = null;
        _candidatesValid = false;
      } else {
        if (!_candidatesValid && _candidateValidityTimer == null) {
          _candidateValidityTimer = new Timer(
            _kHoverDuration,
            () {
              if (mounted) {
                setState(
                  () {
                    _candidatesValid = true;
                    _candidateValidityTimer = null;
                    StoryClusterDragStateModel.of(context)
                        .addAcceptance(widget.storyCluster.id);
                  },
                );
              }
            },
          );
        }
      }
    }

    return _buildWithConfirmedCandidates(
      !_inTimeline || _candidatesValid
          ? candidates
          : <StoryClusterDragData, Offset>{},
    );
  }

  /// [candidates] are the clusters that are currently
  /// being dragged over this drag target for the prerequesite time period with
  /// their associated local position.
  Widget _buildWithConfirmedCandidates(
    Map<StoryClusterDragData, Offset> candidates,
  ) {
    candidates.keys.forEach((StoryClusterDragData data) {
      if (_trackedCandidates[data.id] == null) {
        _trackedCandidates[data.id] = new CandidateInfo(
          initialLockPoint: candidates[data],
        );
      }
      // Update velocity trackers.
      _trackedCandidates[data.id].updateVelocity(candidates[data]);
    });

    bool hasCandidates = candidates.isNotEmpty;
    if (hasCandidates && !_hadCandidates) {
      _originalClusterLayout = new ClusterLayout.from(widget.storyCluster);
      _populateTargets();

      // Invoke onFirstHover callbacks if they exist.
      candidates.keys.forEach(
        (StoryClusterDragData data) => data.onFirstHover?.call(),
      );
    }
    _hadCandidates = hasCandidates;

    _updateInlinePreviewScalingSimulation(hasCandidates && _inTimeline);

    Map<StoryCluster, Offset> storyClusterCandidates = _getStoryClusterMap(
      candidates,
    );

    _updateStoryBars(hasCandidates);
    _updateClosestTargets(candidates);

    // Scale child to widget.scale if we aren't in the timeline
    // and we have a candidate being dragged over us.
    _scale = hasCandidates && !_inTimeline ? widget.scale : 1.0;

    List<PanelDragTarget> validTargets = _targets
        .where(
          (PanelDragTarget target) => !storyClusterCandidates.keys.every(
            (StoryCluster key) =>
                !target.canAccept(key.realStories.length) ||
                !target.isValidInDirection(
                  _trackedCandidates[key.id].dragDirection,
                ),
          ),
        )
        .toList();

    // The direction the candidates are being dragged from the perspective of
    // the debug overlays.  If we have no candidates, assume we don't move.
    DragDirection influenceDragDirection = candidates.isEmpty
        ? DragDirection.none
        : _trackedCandidates[candidates.keys.first.id].dragDirection;

    return new ScopedModelDescendant<DebugModel>(
      builder: (BuildContext context, Widget child, DebugModel debugModel) =>
          new TargetInfluenceOverlay(
        enabled: debugModel.showTargetInfluenceOverlay && candidates.isNotEmpty,
        targets: validTargets,
        dragDirection: influenceDragDirection,
        closestTargetGetter: (Offset point) => _getClosestTarget(
          influenceDragDirection,
          point,
          storyClusterCandidates.keys.isNotEmpty
              ? storyClusterCandidates.keys.first
              : null,
          false,
        ),
        child: new TargetOverlay(
          enabled: debugModel.showTargetOverlay,
          targets: validTargets,
          closestTargetLockPoints:
              _trackedCandidates.values.map(CandidateInfo.toPoint).toList(),
          candidatePoints: candidates.values.toList(),
          child: child,
        ),
      ),
      child: new Transform(
        transform: new Matrix4.identity().scaled(_scale, _scale),
        alignment: FractionalOffset.center,
        child: widget.child,
      ),
    );
  }

  set _scale(double scale) {
    if (_scaleSimulation.target != scale) {
      _scaleSimulation.target = scale;
      startTicking();
    }
  }

  double get _scale => _scaleSimulation.value;

  void _updateStoryBars(bool hasCandidates) {
    if (!StoryClusterDragStateModel.of(context).isDragging) {
      return;
    }

    if (hasCandidates) {
      widget.storyCluster.maximizeStoryBars();
    } else {
      widget.storyCluster.minimizeStoryBars();
    }
  }

  /// Moves the [stories] corrdinates from whatever space they're in to the
  /// coordinate space of our [PanelDragTargets.child].
  void _transposeToChildCoordinates(List<Story> stories) {
    stories.forEach((Story story) {
      // Get the Story's current global bounds...
      RenderBox storyBox =
          story.positionedKey.currentContext?.findRenderObject();

      // If the Story's positioned widget hasn't been built yet there's nothing
      // to transpose so do nothing.
      if (storyBox == null) {
        return;
      }

      Offset storyTopLeft = storyBox.localToGlobal(Offset.zero);
      Offset storyBottomRight = storyBox.localToGlobal(
        new Offset(storyBox.size.width, storyBox.size.height),
      );

      // Convert the Story's global bounds into bounds local to the
      // StoryPanels...
      RenderBox panelsBox =
          widget.storyCluster.panelsKey.currentContext.findRenderObject();
      Offset storyInPanelsTopLeft = panelsBox.globalToLocal(storyTopLeft);
      Offset storyInPanelsBottomRight =
          panelsBox.globalToLocal(storyBottomRight);
      // Jump the Story's SimulatedFractional to its new location to
      // ensure a seamless animation into place.
      SimulatedFractionalState state = story.positionedKey.currentState;
      state.jump(
        new Rect.fromLTRB(
          storyInPanelsTopLeft.dx,
          storyInPanelsTopLeft.dy,
          storyInPanelsBottomRight.dx,
          storyInPanelsBottomRight.dy,
        ),
        panelsBox.size,
      );
    });
  }

  Map<StoryCluster, Offset> _getStoryClusterMap(
    Map<StoryClusterDragData, Offset> candidates,
  ) {
    Map<StoryCluster, Offset> storyClusterMap = <StoryCluster, Offset>{};
    candidates.keys.forEach((StoryClusterDragData data) {
      Offset storyClusterPoint = candidates[data];
      StoryCluster storyCluster =
          StoryModel.of(context).getStoryCluster(data.id);
      storyClusterMap[storyCluster] = storyClusterPoint;
    });
    return storyClusterMap;
  }

  /// If [activate] is true, start the inline preview scale simulation.  If
  /// false, reverse the simulation back to its beginning.
  void _updateInlinePreviewScalingSimulation(bool activate) {
    widget.storyCluster.inlinePreviewScaleSimulationKey.currentState?.target =
        activate ? 1.0 : 0.0;
    widget.storyCluster.inlinePreviewHintScaleSimulationKey.currentState
        ?.target = (activate || _candidateValidityTimer != null) ? 1.0 : 0.0;
  }

  void _updateClosestTargets(Map<StoryClusterDragData, Offset> candidates) {
    // Remove any candidates that no longer exist.
    _trackedCandidates.keys.toList().forEach((StoryClusterId storyClusterId) {
      if (candidates.keys
          .every((StoryClusterDragData data) => data.id != storyClusterId)) {
        _trackedCandidates.remove(storyClusterId);

        panelEventHandler.onCandidateRemoved();

        // If no stories have changed, and a candidate was removed we need
        // to revert back to our original layout.
        if (_originalClusterLayout.storyCount ==
            widget.storyCluster.stories.length) {
          _originalClusterLayout.restore(widget.storyCluster);
        }
      }
    });

    // For each candidate...
    candidates.keys.forEach((StoryClusterDragData data) {
      Offset storyClusterPoint = candidates[data];

      CandidateInfo candidateInfo = _trackedCandidates[data.id];

      StoryCluster storyCluster = StoryModel.of(context).getStoryCluster(
        data.id,
      );
      PanelDragTarget closestTarget = _getClosestTarget(
        candidateInfo.dragDirection,
        storyClusterPoint,
        storyCluster,
        candidateInfo.closestTarget == null,
      );

      if (candidateInfo.canLock(closestTarget, storyClusterPoint)) {
        _lockClosestTarget(
          candidateInfo: candidateInfo,
          storyCluster: storyCluster,
          point: storyClusterPoint,
          closestTarget: closestTarget,
        );
      }
    });
  }

  void _lockClosestTarget({
    CandidateInfo candidateInfo,
    StoryCluster storyCluster,
    Offset point,
    PanelDragTarget closestTarget,
  }) {
    candidateInfo.lock(point, closestTarget);
    _verticalEdgeHoverTimer?.cancel();
    _verticalEdgeHoverTimer = null;
    closestTarget.onHover?.call(context, storyCluster);
    _updateFocusedStoryId(storyCluster);
  }

  PanelDragTarget _getClosestTarget(
    DragDirection dragDirection,
    Offset point,
    StoryCluster storyCluster,
    bool initialTarget,
  ) {
    double minScore = double.infinity;
    PanelDragTarget closestTarget;
    _targets
        .where((PanelDragTarget target) => storyCluster == null
            ? true
            : target.canAccept(storyCluster.realStories.length))
        .where((PanelDragTarget target) =>
            target.isValidInDirection(dragDirection))
        .where((PanelDragTarget target) => target.withinRange(point))
        .where((PanelDragTarget target) =>
            (!initialTarget || target.initiallyTargetable))
        .forEach((PanelDragTarget target) {
      double targetScore = target.distanceFrom(point);
      targetScore *=
          target.isInDirectionFromPoint(dragDirection, point) ? 1.0 : 2.0;
      if (targetScore < minScore) {
        minScore = targetScore;
        closestTarget = target;
      }
    });
    return closestTarget;
  }

  void _populateTargets() {
    _targets.clear();
    _targets.addAll(
      _panelDragTargetGenerator.createTargets(
        size: SizeModel.of(context).size,
        currentSize: widget.currentSize,
        clusterLayout: _originalClusterLayout,
        scale: widget.scale,
        inTimeline: _inTimeline,
        maxStories: _kMaxStoriesPerCluster - widget.storyCluster.stories.length,
        onAddClusterAbovePanels: panelEventHandler.onAddClusterAbovePanels,
        onAddClusterBelowPanels: panelEventHandler.onAddClusterBelowPanels,
        onAddClusterToLeftOfPanels:
            panelEventHandler.onAddClusterToLeftOfPanels,
        onAddClusterToRightOfPanels:
            panelEventHandler.onAddClusterToRightOfPanels,
        onAddClusterAbovePanel: panelEventHandler.onAddClusterAbovePanel,
        onAddClusterBelowPanel: panelEventHandler.onAddClusterBelowPanel,
        onAddClusterToLeftOfPanel: panelEventHandler.onAddClusterToLeftOfPanel,
        onAddClusterToRightOfPanel:
            panelEventHandler.onAddClusterToRightOfPanel,
        onStoryBarHover: panelEventHandler.onStoryBarHover,
        onStoryBarDrop: panelEventHandler.onStoryBarDrop,
        onLeaveCluster: _onLeaveCluster,
      ),
    );
  }

  void _onLeaveCluster({
    BuildContext context,
    StoryCluster storyCluster,
    bool preview: false,
  }) {
    panelEventHandler.onLeaveCluster(
        context: context, storyCluster: storyCluster, preview: preview);
    if (preview) {
      _verticalEdgeHoverTimer = new Timer(
        _kVerticalEdgeHoverDuration,
        () => widget.onVerticalEdgeHover?.call(),
      );
    } else {
      _verticalEdgeHoverTimer?.cancel();
      _verticalEdgeHoverTimer = null;
    }
  }

  void _updateFocusedStoryId(StoryCluster storyCluster) {
    // After onHover or onDrop call always focus on, in order of priority:

    // 1. story with same ID as storyCluster.focusedStoryId if exists. OR
    if (widget.storyCluster.realStories
        .where((Story story) => story.id == storyCluster.focusedStoryId)
        .isNotEmpty) {
      widget.storyCluster.focusedStoryId = storyCluster.focusedStoryId;
      return;
    }

    // 2. placeholder with same ID as storyCluster.focusedStoryId if exists. OR
    List<PlaceHolderStory> previews = widget.storyCluster.previewStories
        .where((PlaceHolderStory story) =>
            story.associatedStoryId == storyCluster.focusedStoryId)
        .toList();
    if (previews.isNotEmpty) {
      widget.storyCluster.focusedStoryId = previews[0].id;
      return;
    }

    // 3. Original focused story.
    _originalClusterLayout.restoreFocus(widget.storyCluster);
  }
}
