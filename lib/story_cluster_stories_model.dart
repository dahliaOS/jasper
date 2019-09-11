// Copyright 2016 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:lib.widgets/model.dart';

import 'story_cluster.dart';

export 'package:lib.widgets/model.dart'
    show ScopedModel, Model, ScopedModelDescendant;

/// Tracks a [StoryCluster], notifying listeners when it changes.
/// Using a [StoryClusterStoriesModel] allows the [StoryCluster]'s story list
/// it tracks to be passed down the widget tree using an [ScopedModel].
///
/// NOTE: [StoryCluster] ensures [notifyListeners] gets called.
class StoryClusterStoriesModel extends Model {
  final StoryCluster _storyCluster;

  /// Constructs a model for the given story cluster.
  StoryClusterStoriesModel(this._storyCluster);

  /// The [StoryCluster] associated with this model.
  StoryCluster get storyCluster => _storyCluster;
}
