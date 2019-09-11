// Copyright 2016 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/widgets.dart';

import 'panel.dart';
import 'simulated_fractional.dart';
import 'story_bar.dart';
import 'story_cluster_id.dart';
import 'story_list.dart';
import 'simulated_fractionally_sized_box.dart';

/// The ID of a Story as a [ValueKey].
class StoryId extends ValueKey<dynamic> {
  /// Constructs a StoryId by passing [value] to [ValueKey]'s constructor.
  StoryId(dynamic value) : super(value);
}

/// A builder that is called for different values of [opacity].
typedef Widget OpacityBuilder(BuildContext context, double opacity);

/// The representation of a Story.  A Story's contents are display as a [Widget]
/// provided by [builder] while the size of a story in the [StoryList] is
/// determined by [lastInteraction] and [cumulativeInteractionDuration].
class Story {
  /// The Story's ID.
  final StoryId id;

  /// Builds the [Widget] representation of the story.
  final WidgetBuilder builder;

  /// The icons indicating the source of the story.
  final List<OpacityBuilder> icons;

  /// The image of the user this story belongs to.
  final OpacityBuilder avatar;

  /// The title of the story.
  final String title;

  /// The story's theme color.  The Story's bar and background are set to this
  /// color.
  final Color themeColor;

  /// The ID of the cluster this story will form if it is removed from a
  /// different cluster.
  final StoryClusterId clusterId;

  /// The key of the [StoryBar] representing this story.
  final GlobalKey<StoryBarState> storyBarKey;

  /// The key of the padding being applied to the story's story bar.
  final GlobalKey storyBarPaddingKey;

  /// The key of draggable portion of the widget represeting this story.
  final GlobalKey clusterDraggableKey;

  /// The key of shadow being applied behind this story's widget.
  final GlobalKey<SimulatedFractionalState> shadowPositionedKey;

  /// The key of container in which this story's widget resides.
  final GlobalKey containerKey;

  /// The key of the container that sizes the story's widget in tab mode.
  final GlobalKey<SimulatedFractionallySizedBoxState> tabSizerKey;

  /// Called when the cluster index of this story changes.
  final ValueChanged<int> onClusterIndexChanged;

  /// A timestamp of the last time this story was interacted with.  This is used
  /// for sorting the story list and for determining the size of the story's
  /// widget in the story list.
  DateTime lastInteraction;

  /// The culmultaive interaction duration the user has had with is story.  This
  /// is used for determining the size of the story's widget in the story list.
  Duration cumulativeInteractionDuration;

  /// True if the story is inactive and should not be displayed in the story
  /// list.
  bool inactive;

  /// The key of the container that position's the story's widget within its
  /// cluster.
  GlobalKey<SimulatedFractionalState> positionedKey;

  /// The location of the story's widget within its cluster.
  Panel panel;

  /// The importance of the story relative to other stories.
  double importance;

  /// The index of the cluster this story is in.
  int _clusterIndex;

  /// Constructor.
  Story({
    this.id,
    this.builder,
    this.title: '',
    this.icons: const <OpacityBuilder>[],
    this.avatar,
    this.lastInteraction,
    this.cumulativeInteractionDuration,
    this.themeColor,
    this.inactive: false,
    this.importance: 1.0,
    this.onClusterIndexChanged,
  })
      : this.clusterId = new StoryClusterId(),
        this.storyBarKey =
            new GlobalKey<StoryBarState>(debugLabel: '$id storyBarKey'),
        this.storyBarPaddingKey =
            new GlobalKey(debugLabel: '$id storyBarPaddingKey'),
        this.clusterDraggableKey =
            new GlobalKey(debugLabel: '$id clusterDraggableKey'),
        this.positionedKey = new GlobalKey(debugLabel: '$id positionedKey'),
        this.shadowPositionedKey =
            new GlobalKey(debugLabel: '$id shadowPositionedKey'),
        this.containerKey = new GlobalKey(debugLabel: '$id containerKey'),
        this.tabSizerKey = new GlobalKey<SimulatedFractionallySizedBoxState>(
            debugLabel: '$id tabSizerKey'),
        this.panel = new Panel();

  /// Returns true if the [Story] has no content and should just take up empty
  /// space.
  bool get isPlaceHolder => false;

  /// Maximizes the story's story bar.  See [StoryBarState.maximize].
  void maximizeStoryBar({bool jumpToFinish: false}) =>
      storyBarKey.currentState?.maximize(jumpToFinish: jumpToFinish);

  /// Minimizes the story's story bar.  See [StoryBarState.minimize].
  void minimizeStoryBar() => storyBarKey.currentState?.minimize();

  /// Hides the story's story bar.  See [StoryBarState.hide].
  void hideStoryBar() => storyBarKey.currentState?.hide();

  /// Shows the story's story bar.  See [StoryBarState.show].
  void showStoryBar() => storyBarKey.currentState?.show();

  /// Sets the cluster index of this story.
  set clusterIndex(int clusterIndex) {
    if (_clusterIndex != clusterIndex) {
      _clusterIndex = clusterIndex;
      onClusterIndexChanged?.call(_clusterIndex);
    }
  }

  @override
  int get hashCode => id.hashCode;

  @override
  bool operator ==(dynamic other) => (other is Story && other.id == id);

  @override
  String toString() => 'Story( id: $id, title: $title, panel: $panel )';
}
