// Copyright 2016 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import 'armadillo_drag_target.dart';
import 'display_mode.dart';
import 'panel.dart';
import 'panel_drag_targets.dart';
import 'place_holder_story.dart';
import 'simulation_builder.dart';
import 'story.dart';
import 'story_cluster_drag_feedback.dart';
import 'story_cluster_id.dart';
import 'story_cluster_panels_model.dart';
import 'story_cluster_stories_model.dart';
import 'story_cluster_widget.dart';
import 'story_list_layout.dart';
import 'story_panels.dart';

/// Called when something related to [storyCluster] happens.
typedef void OnStoryClusterEvent(StoryCluster storyCluster);

/// A data model representing a list of [Story]s.
class StoryCluster {
  /// The unique id of the cluster.
  final StoryClusterId id;

  /// The list of stories contained in the cluster.
  final List<Story> _stories;

  /// The key used for the cluster's [StoryClusterWidget]'s
  /// [PanelDragTargets].
  final GlobalKey clusterDragTargetsKey;

  /// The key used for the cluster's [StoryPanels].
  final GlobalKey panelsKey;

  /// The key used for the cluster's [StoryClusterDragFeedback].
  final GlobalKey<StoryClusterDragFeedbackState> dragFeedbackKey;

  /// The focus simulation is the scaling that occurs when the
  /// user has focused on the cluster to bring it to full screen size.
  final GlobalKey<SimulationBuilderState> focusSimulationKey;

  /// The inline preview scale simulation is the scaling that occurs when the
  /// user drags a cluster over this cluster while in the timeline after the
  /// inline preview timeout occurs.
  final GlobalKey<SimulationBuilderState> inlinePreviewScaleSimulationKey;

  /// The inline preview hint scale simulation is the scaling that occurs when
  /// the user drags a cluster over this cluster while in the timeline before
  /// the inline preview timeout occurs.
  final GlobalKey<SimulationBuilderState> inlinePreviewHintScaleSimulationKey;

  final Set<VoidCallback> _storyListListeners;

  /// The title of a cluster is currently generated via
  /// [_getClusterTitle] whenever the list of stories in this cluster changes.
  /// [_getClusterTitle] currently just concatenates the titles of the stories
  /// within the cluster.
  String title;

  /// The key used for the cluster's [StoryClusterWidget]'s
  /// [ArmadilloLongPressDraggable].
  GlobalKey clusterDraggableKey;

  /// The layout this cluster should use to place and size itself.
  StoryLayout storyLayout;

  DateTime _lastInteraction;
  Duration _cumulativeInteractionDuration;
  DisplayMode _displayMode;
  StoryId _focusedStoryId;
  StoryClusterStoriesModel _storiesModel;
  StoryClusterPanelsModel _panelsModel;

  /// Constructor.
  StoryCluster({
    StoryClusterId id,
    GlobalKey clusterDraggableKey,
    List<Story> stories,
    this.storyLayout,
  })  : this._stories = stories,
        this.title = _getClusterTitle(stories),
        this._lastInteraction = _getClusterLastInteraction(stories),
        this._cumulativeInteractionDuration =
            _getClusterCumulativeInteractionDuration(stories),
        this.id = id ?? new StoryClusterId(),
        this.clusterDraggableKey = clusterDraggableKey ??
            new GlobalKey(debugLabel: 'clusterDraggableKey'),
        this.clusterDragTargetsKey =
            new GlobalKey(debugLabel: 'clusterDragTargetsKey'),
        this.panelsKey = new GlobalKey(debugLabel: 'panelsKey'),
        this.dragFeedbackKey = new GlobalKey<StoryClusterDragFeedbackState>(
            debugLabel: 'dragFeedbackKey'),
        this.focusSimulationKey = new GlobalKey<SimulationBuilderState>(
            debugLabel: 'focusSimulationKey'),
        this.inlinePreviewScaleSimulationKey =
            new GlobalKey<SimulationBuilderState>(
                debugLabel: 'inlinePreviewScaleSimulationKey'),
        this.inlinePreviewHintScaleSimulationKey =
            new GlobalKey<SimulationBuilderState>(
                debugLabel: 'inlinePreviewHintScaleSimulationKey'),
        this._displayMode = DisplayMode.panels,
        this._storyListListeners = new Set<VoidCallback>(),
        this._focusedStoryId = stories[0].id {
    _storiesModel = new StoryClusterStoriesModel(this);
    addStoryListListener(_storiesModel.notifyListeners);
    _panelsModel = new StoryClusterPanelsModel(this);
  }

  /// Creates a [StoryCluster] from [story].
  factory StoryCluster.fromStory(Story story) {
    story.panel = new Panel();
    story.positionedKey =
        new GlobalKey(debugLabel: '${story.id} positionedKey');
    return new StoryCluster(
      id: story.clusterId,
      clusterDraggableKey: story.clusterDraggableKey,
      stories: <Story>[story],
    );
  }

  /// Wraps [child] with the [Model]s corresponding to this [StoryCluster].
  Widget wrapWithModels({Widget child}) =>
      new ScopedModel<StoryClusterStoriesModel>(
        model: _storiesModel,
        child: new ScopedModel<StoryClusterPanelsModel>(
          model: _panelsModel,
          child: child,
        ),
      );

  /// The list of stories in this cluster including both 'real' stories and
  /// place holder stories.
  List<Story> get stories => new List<Story>.unmodifiable(_stories);

  /// The list of 'real' stories in this cluster.
  List<Story> get realStories => new List<Story>.unmodifiable(
        _stories.where((Story story) => !story.isPlaceHolder),
      );

  /// The list of place holder stories in this cluster.
  List<PlaceHolderStory> get previewStories =>
      new List<PlaceHolderStory>.unmodifiable(
        _stories.where((Story story) => story.isPlaceHolder),
      );

  /// Returns [Widget]s for each of the stories in this cluster.
  Map<StoryId, Widget> buildStoryWidgets(BuildContext context) {
    Map<StoryId, Widget> storyWidgets = <StoryId, Widget>{};
    stories.forEach((Story story) {
      storyWidgets[story.id] = story.builder(context);
    });
    return storyWidgets;
  }

  /// [listener] will be called whenever the list of stories changes.
  void addStoryListListener(VoidCallback listener) {
    _storyListListeners.add(listener);
  }

  /// [listener] will no longer be called whenever the list of stories changes.
  void removeStoryListListener(VoidCallback listener) {
    _storyListListeners.remove(listener);
  }

  void _notifyStoryListListeners() {
    title = _getClusterTitle(realStories);
    _storyListListeners.forEach((VoidCallback listener) => listener());
    _panelsModel.notifyListeners();
  }

  /// Activates the cluster.  This is only used for demo purposes.
  void activate() {
    _stories.forEach((Story story) {
      story.inactive = false;
    });
  }

  /// Sets the last interaction time for the cluster.  Used for ordering
  /// clusters in the story list.
  set lastInteraction(DateTime lastInteraction) {
    this._lastInteraction = lastInteraction;
    _stories.forEach((Story story) {
      story.lastInteraction = lastInteraction;
    });
  }

  /// Gets the last interaction time for the cluster.
  DateTime get lastInteraction => _lastInteraction;

  /// Sets the cumulative interaction time this cluster has had.  Used for
  /// ordering laying out clusters in the story list.
  set cumulativeInteractionDuration(Duration cumulativeInteractionDuration) {
    this._cumulativeInteractionDuration = cumulativeInteractionDuration;
    _stories.forEach((Story story) {
      story.cumulativeInteractionDuration = cumulativeInteractionDuration;
    });
  }

  /// Gets the cumulative interaction time this cluster has had.
  Duration get cumulativeInteractionDuration => _cumulativeInteractionDuration;

  /// Gets the importance of the cluster relative to other clusters.
  double get importance => (_stories.isEmpty)
      ? 1.0
      : _stories.map((Story s) => s.importance).reduce(math.max);

  @override
  int get hashCode => id.hashCode;

  @override
  bool operator ==(dynamic other) => (other is StoryCluster && other.id == id);

  @override
  String toString() {
    String string = 'StoryCluster( id: $id, title: $title,\n';
    _stories.forEach((Story story) {
      string += '\n   story: $story';
    });
    string += ' )';
    return string;
  }

  /// The current [DisplayMode] of this cluster.
  DisplayMode get displayMode => _displayMode;

  /// Switches the [DisplayMode] to [displayMode].
  set displayMode(DisplayMode displayMode) {
    if (_displayMode != displayMode) {
      _displayMode = displayMode;
      _panelsModel.notifyListeners();
    }
  }

  /// Removes any preview stories from [stories]
  Map<StoryId, PlaceHolderStory> removePreviews() {
    Map<StoryId, PlaceHolderStory> storiesRemoved =
        <StoryId, PlaceHolderStory>{};
    _stories.toList().forEach((Story story) {
      if (story is PlaceHolderStory) {
        absorb(story);
        storiesRemoved[story.associatedStoryId] = story;
      }
    });
    return storiesRemoved;
  }

  /// Returns the [Panel]s of the [stories].
  Iterable<Panel> get panels => _stories.map((Story story) => story.panel);

  /// Resizes the [Panel]s of the [stories] to have columns with equal widths
  /// and rows of equal heights.
  void normalizeSizes() {
    Set<double> currentLeftsSet = new Set<double>();
    Set<double> currentTopsSet = new Set<double>();
    panels.forEach((Panel panel) {
      currentLeftsSet.add(panel.left);
      currentTopsSet.add(panel.top);
    });

    List<double> currentSortedLefts = new List<double>.from(currentLeftsSet);
    currentSortedLefts.sort();

    List<double> currentSortedTops = new List<double>.from(currentTopsSet);
    currentSortedTops.sort();

    Map<double, double> leftMap = <double, double>{1.0: 1.0};
    double left = 0.0;
    for (int i = 0; i < currentSortedLefts.length; i++) {
      leftMap[currentSortedLefts[i]] = left;
      left += getSpanSpan(1.0, i, currentSortedLefts.length);
    }

    Map<double, double> topMap = <double, double>{1.0: 1.0};
    double top = 0.0;
    for (int i = 0; i < currentSortedTops.length; i++) {
      topMap[currentSortedTops[i]] = top;
      top += getSpanSpan(1.0, i, currentSortedTops.length);
    }

    panels.toList().forEach(
      (Panel panel) {
        assert(() {
          bool hadErrors = false;
          if (leftMap[panel.left] == null) {
            print(
                'leftMap doesn\'t contain left ${panel.left}: ${leftMap.keys}');
            hadErrors = true;
          }
          if (topMap[panel.top] == null) {
            print('topMap doesn\'t contain top ${panel.top}: ${topMap.keys}');
            hadErrors = true;
          }
          if (leftMap[panel.right] == null) {
            print(
                'leftMap doesn\'t contain right ${panel.right}: ${leftMap.keys}');
            hadErrors = true;
          }
          if (topMap[panel.bottom] == null) {
            print(
                'topMap doesn\'t contain bottom ${panel.bottom}: ${topMap.keys}');
            hadErrors = true;
          }
          if (hadErrors) {
            panels.forEach((Panel panel) {
              print(' |--> $panel');
            });
          }
          return !hadErrors;
        }());
        replace(
          panel: panel,
          withPanel: new Panel.fromLTRB(
            leftMap[panel.left],
            topMap[panel.top],
            leftMap[panel.right],
            topMap[panel.bottom],
          ),
        );
      },
    );
    _panelsModel.notifyListeners();
  }

  /// Adds the [story] to [stories] with a [Panel] of [withPanel].
  void add({Story story, Panel withPanel, int atIndex}) {
    story.panel = withPanel;
    if (atIndex == null) {
      _stories.add(story);
    } else {
      _stories.insert(atIndex, story);
    }
    _notifyStoryListListeners();
  }

  /// Replaces the [Story.panel] of the story with [panel] with [withPanel]/
  void replace({Panel panel, Panel withPanel}) {
    Story story = _stories.where((Story story) => story.panel == panel).single;
    story.panel = withPanel;
    _panelsModel.notifyListeners();
  }

  /// Replaces the [Story.panel] of the story with [storyId] with [withPanel]/
  void replaceStoryPanel({StoryId storyId, Panel withPanel}) {
    Story story = _stories.where((Story story) => story.id == storyId).single;
    story.panel = withPanel;
    _panelsModel.notifyListeners();
  }

  /// true if this cluster has become a placeholder via [becomePlaceholder].
  bool get isPlaceholder => stories.length == 1 && stories.first.isPlaceHolder;

  /// Converts this cluster into a placeholder by replacing all its stories
  /// with a single place holder story.
  void becomePlaceholder() {
    _stories.clear();
    _stories.add(new PlaceHolderStory(transparent: true));
    _notifyStoryListListeners();
  }

  /// Removes [story] from this cluster.  Stories adjacent to [story] in the
  /// cluster will absorb the area left behind by [story]'s [Story.panel].
  void absorb(Story story) {
    List<Story> stories = new List<Story>.from(_stories);
    // We can't absorb the story if it's the only story.
    if (stories.length <= 1) {
      return;
    }
    stories.remove(story);
    stories.sort(
      (Story a, Story b) => a.panel.sizeFactor > b.panel.sizeFactor
          ? 1
          : a.panel.sizeFactor < b.panel.sizeFactor ? -1 : 0,
    );

    Panel remainingAreaToAbsorb = story.panel;
    double remainingSize;
    Story absorbingStory;
    do {
      remainingSize = remainingAreaToAbsorb.sizeFactor;
      absorbingStory = stories
          .where((Story story) => story.panel.canAbsorb(remainingAreaToAbsorb))
          .first;
      absorbingStory.panel.absorb(remainingAreaToAbsorb,
          (Panel absorbed, Panel remainder) {
        absorbingStory.panel = absorbed;
        remainingAreaToAbsorb = remainder;
      });
    } while (remainingAreaToAbsorb.sizeFactor < remainingSize &&
        remainingAreaToAbsorb.sizeFactor > 0.0);
    assert(remainingAreaToAbsorb.sizeFactor == 0.0);

    int absorbedStoryIndex = _stories.indexOf(story);
    _stories.remove(story);
    normalizeSizes();

    // If we've just removed the focused story, switch focus to a tab adjacent
    // story.
    if (focusedStoryId == story.id) {
      focusedStoryId = _stories[absorbedStoryIndex >= _stories.length
              ? _stories.length - 1
              : absorbedStoryIndex]
          .id;
    }

    _notifyStoryListListeners();
  }

  /// Sets the focused story for this cluster.
  set focusedStoryId(StoryId storyId) {
    if (storyId != _focusedStoryId) {
      _focusedStoryId = storyId;
      _panelsModel.notifyListeners();
    }
  }

  /// The id of the currently focused story.
  StoryId get focusedStoryId => _focusedStoryId;

  /// Unfocuses the story cluster.
  void unFocus() {
    focusSimulationKey.currentState?.target = 0.0;
    minimizeStoryBars();
  }

  /// Maximizes the story bars for all the stories within the cluster.
  /// See [Story.maximizeStoryBar].
  void maximizeStoryBars({
    bool jumpToFinish: false,
  }) =>
      stories.forEach(
        (Story story) => story.maximizeStoryBar(jumpToFinish: jumpToFinish),
      );

  /// Minimizes the story bars for all the stories within the cluster.
  /// See [Story.minimizeStoryBar].
  void minimizeStoryBars() =>
      stories.forEach((Story story) => story.minimizeStoryBar());

  /// Hides the story bars for all the stories within the cluster.
  /// See [Story.hideStoryBar].
  void hideStoryBars() =>
      stories.forEach((Story story) => story.hideStoryBar());

  /// Shows the story bars for all the stories within the cluster.
  /// See [Story.showStoryBar].
  void showStoryBars() =>
      stories.forEach((Story story) => story.showStoryBar());

  /// Moves the [storiesToMove] from their current location in the story list
  /// to [targetIndex].
  void moveStoriesToIndex(List<Story> storiesToMove, int targetIndex) {
    List<Story> removedStories = <Story>[];
    storiesToMove.forEach((Story storyToMove) {
      Story story =
          stories.where((Story story) => story.id == storyToMove.id).single;
      _stories.remove(story);
      removedStories.add(story);
    });
    removedStories.reversed.forEach(
      (Story removedStory) => _stories.insert(targetIndex, removedStory),
    );
    _notifyStoryListListeners();
  }

  /// Moves the [storiesToMove] from their current location in the story list
  /// to [targetIndex].  This differs from [moveStoriesToIndex] in that only
  /// [previewStories] are moved.
  void movePlaceholderStoriesToIndex(
    List<Story> storiesToMove,
    int targetIndex,
  ) {
    List<Story> removedStories = <Story>[];
    storiesToMove.forEach((Story storyToMove) {
      Story story = previewStories
          .where((PlaceHolderStory story) =>
              story.associatedStoryId == storyToMove.id)
          .single;
      _stories.remove(story);
      removedStories.add(story);
    });
    removedStories.reversed.forEach(
      (Story removedStory) => _stories.insert(targetIndex, removedStory),
    );
    _notifyStoryListListeners();
  }

  /// Mirrors the order of [stories] to match the given [storiesToMirror].
  /// Note in this case the stories in [storiesToMirror] are expected to have
  /// the opposite 'realness' as those in [stories] (ie. A placeholder story in
  /// [storiesToMirror] corresponds to a non-placeholder story in [stories] and
  /// vice versa).
  void mirrorStoryOrder(List<Story> storiesToMirror) {
    for (int i = 0; i < storiesToMirror.length; i++) {
      if (storiesToMirror[i].isPlaceHolder) {
        PlaceHolderStory placeHolderMirror = storiesToMirror[i];
        Story story = stories
            .where((Story story) =>
                story.id == placeHolderMirror.associatedStoryId)
            .single;
        _stories.remove(story);
        _stories.insert(i, story);
      } else {
        Story realMirror = storiesToMirror[i];
        Story story = previewStories
            .where((PlaceHolderStory story) =>
                story.associatedStoryId == realMirror.id)
            .single;
        _stories.remove(story);
        _stories.insert(i, story);
      }
    }
  }

  static String _getClusterTitle(List<Story> stories) {
    String title = '';
    stories.where((Story story) => !story.isPlaceHolder).forEach((Story story) {
      if (title.isNotEmpty) {
        title += ', ';
      }
      title += story.title;
    });
    return title;
  }

  static DateTime _getClusterLastInteraction(List<Story> stories) {
    DateTime latestTime = new DateTime(1970);
    stories.where((Story story) => !story.isPlaceHolder).forEach((Story story) {
      if (latestTime.isBefore(story.lastInteraction)) {
        latestTime = story.lastInteraction;
      }
    });
    return latestTime;
  }

  static Duration _getClusterCumulativeInteractionDuration(
      List<Story> stories) {
    Duration largestDuration = new Duration();
    stories.where((Story story) => !story.isPlaceHolder).forEach((Story story) {
      if (largestDuration < story.cumulativeInteractionDuration) {
        largestDuration = story.cumulativeInteractionDuration;
      }
    });
    return largestDuration;
  }
}
