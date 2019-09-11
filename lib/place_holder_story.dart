// Copyright 2016 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/widgets.dart';

import 'nothing.dart';
import 'panel_drag_targets.dart';
import 'story.dart';
import 'story_cluster.dart';
import 'story_panels.dart';

const Color _kBackgroundColor = const Color(0x40E6E6E6);

/// A [Story] with no content.  This is used in place of a real story within a
/// [StoryCluster] to take up empty visual space in [StoryPanels] when
/// [PanelDragTargets] has a hovering cluster (ie. we're previewing the
/// combining of two clusters).
class PlaceHolderStory extends Story {
  /// The [StoryId] of the [Story] this place holder replacing.
  final StoryId associatedStoryId;

  /// True if the [Widget] representing this [Story] should be invisible.
  final bool transparent;

  /// Constructor.
  PlaceHolderStory({this.associatedStoryId, bool transparent: false})
      : this.transparent = transparent,
        super(
          id: new StoryId('PlaceHolder $associatedStoryId'),
          builder: (_) => transparent
              ? Nothing.widget
              : new Container(color: _kBackgroundColor),
        );

  @override
  bool get isPlaceHolder => true;
}
