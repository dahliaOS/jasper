// Copyright 2016 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/rendering.dart';

import 'render_story_list_body.dart';
import 'story_list_layout.dart';

/// Holds progress information for a child of a story list.  See
/// [RenderStoryListBody] for more information about how this is used.
class StoryListBodyParentData extends ListBodyParentData {
  /// The [RenderObject] associated with this parent data.  This object will
  /// be marked for layout whenever progress changes.
  final RenderObject owner;

  StoryLayout _storyLayout;
  double _focusProgress;
  double _inlinePreviewScaleProgress;
  double _inlinePreviewHintScaleProgress;

  /// Constructor.
  StoryListBodyParentData(this.owner);

  set storyLayout(StoryLayout storyLayout) {
    if (_storyLayout != storyLayout) {
      _storyLayout = storyLayout;
      owner.markNeedsLayout();
    }
  }

  /// The story layout of the child.
  StoryLayout get storyLayout => _storyLayout;

  set focusProgress(double focusProgress) {
    if (_focusProgress != focusProgress) {
      _focusProgress = focusProgress;
      owner.markNeedsLayout();
    }
  }

  /// The progress of the child being focused from 0.0 to 1.0.
  double get focusProgress => _focusProgress;

  set inlinePreviewScaleProgress(double inlinePreviewScaleProgress) {
    if (_inlinePreviewScaleProgress != inlinePreviewScaleProgress) {
      _inlinePreviewScaleProgress = inlinePreviewScaleProgress;
      owner.markNeedsLayout();
    }
  }

  /// The progress of the inline preview transition from 0.0 to 1.0.
  double get inlinePreviewScaleProgress => _inlinePreviewScaleProgress;

  set inlinePreviewHintScaleProgress(double inlinePreviewHintScaleProgress) {
    if (_inlinePreviewHintScaleProgress != inlinePreviewHintScaleProgress) {
      _inlinePreviewHintScaleProgress = inlinePreviewHintScaleProgress;
      owner.markNeedsLayout();
    }
  }

  /// The progress of the inline preview hint transition from 0.0 to 1.0.
  double get inlinePreviewHintScaleProgress => _inlinePreviewHintScaleProgress;
}
