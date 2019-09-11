// Copyright 2016 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/widgets.dart';
import 'package:lib.widgets/model.dart';

export 'package:lib.widgets/model.dart'
    show ScopedModel, Model, ScopedModelDescendant;

/// Determines which stories can be hit testable.
class HitTestModel extends Model {
  /// Wraps [ModelFinder.of] for this [Model]. See [ModelFinder.of] for more
  /// details.
  static HitTestModel of(BuildContext context) =>
      new ModelFinder<HitTestModel>().of(context);

  List<String> _visibleStoryIds = <String>[];
  bool _storiesObscuredBySuggestionOverlay = false;
  bool _storiesObscuredByQuickSettingsOverlay = false;

  /// Sets the stories visible to the user.
  /// See [isStoryHitTestable] for details.
  void onVisibleStoriesChanged(List<String> visibleStoryIds) {
    _visibleStoryIds = visibleStoryIds;
    notifyListeners();
  }

  /// Sets the quick settings overlay's [active] status.
  /// See [isStoryHitTestable] for details.
  void onQuickSettingsOverlayChanged(bool active) {
    if (_storiesObscuredByQuickSettingsOverlay != active) {
      _storiesObscuredByQuickSettingsOverlay = active;
      notifyListeners();
    }
  }

  /// Sets the suggestion overlay's [active] status.
  /// See [isStoryHitTestable] for details.
  void onSuggestionsOverlayChanged(bool active) {
    if (_storiesObscuredBySuggestionOverlay != active) {
      _storiesObscuredBySuggestionOverlay = active;
      notifyListeners();
    }
  }

  /// Returns whether a story is hitable or not.  A story is hitable if:
  /// 1) It's not obscured by the quick settings overlay.
  /// 2) It's not obscured by the suggestions overlay.
  /// 3) It's visible.
  bool isStoryHitTestable(String storyId) =>
      !_storiesObscuredBySuggestionOverlay &&
      !_storiesObscuredByQuickSettingsOverlay &&
      _visibleStoryIds.contains(storyId);
}
