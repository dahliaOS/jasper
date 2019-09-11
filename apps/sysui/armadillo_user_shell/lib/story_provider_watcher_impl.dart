// Copyright 2016 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:apps.modular.services.story/story_info.fidl.dart';
import 'package:apps.modular.services.story/story_provider.fidl.dart';
import 'package:apps.modular.services.story/story_state.fidl.dart';

/// Called when the story with [storyInfo] has changed.
typedef void OnStoryChanged(StoryInfo storyInfo, StoryState state);

/// Called when the story with [storyId] has been deleted.
typedef void OnStoryDeleted(String storyId);

/// Watches for changes to the [StoryProvider].
class StoryProviderWatcherImpl extends StoryProviderWatcher {
  /// Called when a story has changed.
  final OnStoryChanged onStoryChanged;

  /// Called when a story has been deleted.
  final OnStoryDeleted onStoryDeleted;

  /// Constructor.
  StoryProviderWatcherImpl({this.onStoryChanged, this.onStoryDeleted});

  @override
  void onChange(StoryInfo storyInfo, StoryState storyState) {
    onStoryChanged?.call(storyInfo, storyState);
  }

  @override
  void onDelete(String storyId) {
    onStoryDeleted?.call(storyId);
  }
}
