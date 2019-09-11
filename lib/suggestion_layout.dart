// Copyright 2017 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

import 'suggestion.dart';

/// The suggestion text and icons are horizontally inset by this amount.
const double _kHorizontalMargin = 24.0;

/// Gives each suggestion a slight rounded edge.
/// TODO(apwilson): We may want to animate this to zero when expanding the card
/// to fill the screen.
const double _kSuggestionCornerRadius = 8.0;

/// The height of a small suggestion.
const double _kSmallSuggestionHeight = 80.0;

/// The height of a medium suggestion.
const double _kMediumSuggestionHeight = 96.0;

/// The height of a large suggestion.
const double _kLargeSuggestionHeight = 120.0;

/// The width of a suggestion.
const double kSuggestionWidth = 296.0;

/// The width of the image area within a suggestion.
const double kSuggestionImageWidth = 80.0;

const double _kHeadline1FontSize = 18.0;
const double _kHeadline1LineHeight = 22.0;
const double _kHeadline2FontSize = 14.0;
const double _kHeadline2LineHeight = 20.0;
const double _kSubHeadlineFontSize = 14.0;
const double _kSubHeadlineLineHeight = 20.0;

/// Used if there's only a headline and it fits in two or fewer lines.
const TextStyle _kHeadline1Style = const TextStyle(
  color: Colors.black,
  fontSize: _kHeadline1FontSize,
  fontWeight: FontWeight.w400,
  height: _kHeadline1LineHeight / _kHeadline1FontSize,
);

/// Used if there's only a headline and it fits in three or more lines or there
/// is a sub-headline.
const TextStyle _kHeadline2Style = const TextStyle(
  color: Colors.black,
  fontSize: _kHeadline2FontSize,
  fontWeight: FontWeight.w500,
  height: _kHeadline2LineHeight / _kHeadline2FontSize,
);

/// Used if there's a sub-headline.
const TextStyle _kSubHeadlineStyle = const TextStyle(
  color: Colors.black,
  fontSize: _kSubHeadlineFontSize,
  fontWeight: FontWeight.w400,
  height: _kSubHeadlineLineHeight / _kSubHeadlineFontSize,
);

const double _kApproximateHeadline2Height = _kHeadline2LineHeight + 2.0;

/// Holds the layout information for the suggestion.  [layout] must be called
/// for a given width before [suggestionText] or [suggestionHeight] are valid.
class SuggestionLayout {
  final Suggestion _suggestion;
  final TextPainter _headline1TextPainter;
  final TextPainter _headline2TextPainter;
  final TextPainter _subHeadlineTextPainter;
  double _suggestionHeight;
  double _suggestionWidth;
  Widget _suggestionText;

  /// Constructor.
  SuggestionLayout({Suggestion suggestion})
      : _suggestion = suggestion,
        _headline1TextPainter = (suggestion.title?.isEmpty ?? true) ||
                (suggestion.description?.isNotEmpty ?? false)
            ? null
            : new TextPainter(
                textDirection: TextDirection.ltr,
                text: new TextSpan(
                    style: _kHeadline1Style, text: suggestion.title),
                textAlign: TextAlign.left,
                maxLines: 2,
              ),
        _headline2TextPainter = suggestion.title?.isEmpty ?? true
            ? null
            : new TextPainter(
                textDirection: TextDirection.ltr,
                text: new TextSpan(
                    style: _kHeadline2Style, text: suggestion.title),
                textAlign: TextAlign.left,
                maxLines: 3,
              ),
        _subHeadlineTextPainter = suggestion.description?.isEmpty ?? true
            ? null
            : new TextPainter(
                textDirection: TextDirection.ltr,
                text: new TextSpan(
                  style: _kSubHeadlineStyle,
                  text: suggestion.description,
                ),
                textAlign: TextAlign.left,
                maxLines: 3,
              );

  /// Sets [suggestionText] or [suggestionHeight] up for the given [maxWidth].
  void layout(double maxWidth) {
    double suggestionWidth = math.min(kSuggestionWidth, maxWidth);
    if (_suggestionWidth == suggestionWidth) {
      return;
    }
    _suggestionWidth = suggestionWidth;

    double textMaxWidth = suggestionWidth -
        (_suggestion.image == null ? 0.0 : kSuggestionImageWidth) -
        ((isCircularSuggestionImage ? 1 : 2) * _kHorizontalMargin);

    _headline1TextPainter?.layout(maxWidth: textMaxWidth);
    _headline2TextPainter?.layout(maxWidth: textMaxWidth);
    _subHeadlineTextPainter?.layout(maxWidth: textMaxWidth);

    _suggestionHeight = _kSmallSuggestionHeight;
    if (_headline1TextPainter != null &&
        !_headline1TextPainter.didExceedMaxLines) {
      /// Display only headline 1.
      _suggestionText = new Text(
        _suggestion.title,
        style: _kHeadline1Style,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      );
    } else if (_suggestion.description?.isNotEmpty ?? false) {
      /// Display headline 2 and sub headline.
      int maxSubHeadlineLines = (_headline2TextPainter.height <
              _kApproximateHeadline2Height)
          ? 3
          : (_headline2TextPainter.height < (2 * _kApproximateHeadline2Height))
              ? 2
              : 1;
      _suggestionText = new Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          new Text(
            _suggestion.title,
            style: _kHeadline2Style,
            maxLines: 3,
            textAlign: TextAlign.left,
            overflow: TextOverflow.ellipsis,
          ),
          new Text(
            _suggestion.description,
            style: _kSubHeadlineStyle,
            maxLines: maxSubHeadlineLines,
            textAlign: TextAlign.left,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      );

      double textHeight =
          _headline2TextPainter.height + _subHeadlineTextPainter.height;
      if (textHeight > 3 * _kApproximateHeadline2Height) {
        _suggestionHeight = _kLargeSuggestionHeight;
      } else if (textHeight > 2 * _kApproximateHeadline2Height) {
        _suggestionHeight = _kMediumSuggestionHeight;
      }
    } else {
      /// Display only headline 2.
      _suggestionText = new Text(
        _suggestion.title,
        style: _kHeadline2Style,
        maxLines: 3,
        overflow: TextOverflow.ellipsis,
      );

      if (_headline2TextPainter.height > 2 * _kApproximateHeadline2Height) {
        _suggestionHeight = _kMediumSuggestionHeight;
      }
    }
  }

  /// The height the suggestion should be for the last [layout] call.
  double get suggestionHeight => _suggestionHeight;

  /// The width the suggestion should be for the last [layout] call.
  double get suggestionWidth => _suggestionWidth;

  /// The text widget the suggestion should have for the last [layout] call.
  Widget get suggestionText => _suggestionText;

  /// Returns true if the image should be circular.
  bool get isCircularSuggestionImage =>
      _suggestion.imageType == ImageType.circular;

  /// Returns the left text padding.
  double get leftTextPadding =>
      _suggestion.imageSide == ImageSide.left && isCircularSuggestionImage
          ? 0.0
          : _kHorizontalMargin;

  /// Returns the right text padding.
  double get rightTextPadding => _suggestion.imageSide == ImageSide.right &&
          isCircularSuggestionImage
      ? 0.0
      : _suggestion.imageSide == ImageSide.right && !isCircularSuggestionImage
          ? 16.0
          : _kHorizontalMargin;
}
