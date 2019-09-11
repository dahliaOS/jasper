// Copyright 2016 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/widgets.dart';
import 'package:meta/meta.dart';

import 'story.dart';
import 'suggestion_layout.dart';

/// Specifies the type of action to perform when the suggestion is selected.
enum SelectionType {
  /// [launchStory] will trigger the [Story] specified by
  /// [Suggestion.selectionStoryId] to come into focus.
  launchStory,

  /// [modifyStory] will modify the [Story] specified by
  /// [Suggestion.selectionStoryId] in some way.
  modifyStory,

  /// [doNothing] does nothing and is only provided for testing purposes.
  doNothing,

  /// [closeSuggestions] closes the suggestion overlay.
  closeSuggestions
}

/// Determines what the suggestion looks like with respect to
/// [Suggestion.image].
enum ImageType {
  /// A [circular] image is expected to be clipped as a circle.
  circular,

  /// A [rectangular] image is not clipped.
  rectangular
}

/// Determines what the suggestion looks like with respect to
/// [Suggestion.image].
enum ImageSide {
  /// The image should display to the right.
  right,

  /// The image should display to the left.
  left,
}

/// The unique id of a [Suggestion].
class SuggestionId extends ValueKey<String> {
  /// Constructor.
  SuggestionId(String value) : super(value);
}

/// The model for displaying a suggestion in the suggestion overlay.
class Suggestion {
  /// The unique id of this suggestion.
  final SuggestionId id;

  /// The suggestion's title.
  final String title;

  /// The suggestion's description.
  final String description;

  /// The color to use for the suggestion's background.
  final Color themeColor;

  /// The action to take when the suggestion is selected.
  final SelectionType selectionType;

  /// The story id related to this suggestion.
  final StoryId selectionStoryId;

  /// The icons representing the source for this suggestion.
  final List<WidgetBuilder> icons;

  /// The main image of the suggestion.
  final WidgetBuilder image;

  /// The type of [image].
  final ImageType imageType;

  /// The side the image should appear on.
  final ImageSide imageSide;

  SuggestionLayout _suggestionLayout;

  GlobalKey _suggestionKey;

  /// Constructor.
  Suggestion({
    @required this.id,
    this.title,
    this.description,
    this.themeColor,
    this.selectionType,
    this.selectionStoryId,
    this.icons: const <WidgetBuilder>[],
    this.image,
    this.imageType,
    this.imageSide: ImageSide.right,
  }) {
    _suggestionLayout = new SuggestionLayout(suggestion: this);
    _suggestionKey = new GlobalObjectKey(this);
  }

  /// How the suggestion should be laid out.
  SuggestionLayout get suggestionLayout => _suggestionLayout;

  @override
  int get hashCode => id.hashCode;

  @override
  bool operator ==(dynamic other) => (other is Suggestion && other.id == id);

  @override
  String toString() => 'Suggestion(title: $title)';

  /// The global key to use when this suggestion is in a widget.
  GlobalKey get globalKey => _suggestionKey;
}
