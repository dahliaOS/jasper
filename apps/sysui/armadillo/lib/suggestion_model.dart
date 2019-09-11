// Copyright 2016 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/widgets.dart';
import 'package:lib.widgets/model.dart';

import 'story_cluster.dart';
import 'suggestion.dart';

export 'package:lib.widgets/model.dart'
    show ScopedModel, Model, ScopedModelDescendant;

/// The base class for suggestion models.
abstract class SuggestionModel extends Model {
  /// Wraps [ModelFinder.of] for this [Model]. See [ModelFinder.of] for more
  /// details.
  static SuggestionModel of(BuildContext context) =>
      new ModelFinder<SuggestionModel>().of(context);

  /// Returns the list of suggestions to be displayed.
  List<Suggestion> get suggestions;

  /// Sets the ask text to [text].
  set askText(String text);

  /// Sets the asking state to [asking].
  set asking(bool asking);

  /// Updates the [suggestions] based on the currently focused storyCluster].  If no
  /// story is in focus, [storyCluster] should be null.
  void storyClusterFocusChanged(StoryCluster storyCluster);

  /// Called when a suggestion is selected by the user.
  void onSuggestionSelected(Suggestion suggestion);
}
