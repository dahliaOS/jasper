// Copyright 2017 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:apps.modular.services.user/focus.fidl.dart';

/// Calling this causes [storyId] to be focused.
typedef void StoryFocuser(String storyId);

/// Manages initial story focus after launch.
class InitialFocusSetter {
  StoryFocuser _storyFocuser;
  FocusProviderProxy _focusProvider;

  /// Set from an external source - typically the UserShell.
  set focusProvider(FocusProviderProxy focusProvider) {
    _focusProvider = focusProvider;
  }

  /// Set from an external source - typically main.
  set storyFocuser(StoryFocuser storyFocuser) {
    _storyFocuser = storyFocuser;
  }

  /// If there is a focused stories stored, focus on it.
  void onStoriesFirstAvailable() {
    _focusProvider.query((List<FocusInfo> focusedStories) {
      if (focusedStories?.isNotEmpty ?? false) {
        _storyFocuser(focusedStories.first.focusedStoryId);
      }
    });
  }
}
