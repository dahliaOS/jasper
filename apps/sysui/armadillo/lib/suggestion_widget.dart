// Copyright 2016 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

import 'suggestion.dart';
import 'suggestion_layout.dart';

const bool _kIconsDisabled = true;

/// Spacing between lines of text and between the text and icon bar.
const double _kVerticalSpacing = 8.0;

/// A fudgefactor to add to the bottom of the icon bar to make the text with
/// icon bar appear centered.  This compensates for the ascender height of the
/// suggestion text font.
const double _kIconBarBottomMargin = 4.0;

/// Height of the icon bar and the size of its square icons.
const double _kIconSize = 16.0;

/// Spacing between icons in the icon bar.
const double _kIconSpacing = 8.0;

/// Gives each suggestion a slight rounded edge.
/// TODO(apwilson): We may want to animate this to zero when expanding the card
/// to fill the screen.
const double kSuggestionCornerRadius = 8.0;

/// The diameter of the person image.
const double _kPersonImageDiameter = 48.0;

/// Displays a [Suggestion].
class SuggestionWidget extends StatelessWidget {
  /// The suggestion to display.
  final Suggestion suggestion;

  /// Called with the suggestion is tapped.
  final VoidCallback onSelected;

  /// If false, the widget will be invisible.
  final bool visible;

  /// If true, the widget has a shadow under it.
  final bool shadow;

  /// Constructor.
  SuggestionWidget({
    Key key,
    this.suggestion,
    this.onSelected,
    this.visible: true,
    this.shadow: false,
  })
      : super(key: key);

  @override
  Widget build(BuildContext context) => new LayoutBuilder(
        builder: (BuildContext context, BoxConstraints boxConstraints) {
          suggestion.suggestionLayout.layout(boxConstraints.maxWidth);
          Widget image = _buildImage(
            context,
            suggestion.suggestionLayout.suggestionHeight,
          );
          Widget textAndIcons = _buildTextAndIcons(
            context,
            suggestion.suggestionLayout.suggestionText,
          );

          List<Widget> rowChildren = suggestion.imageSide == ImageSide.left
              ? <Widget>[image, textAndIcons]
              : <Widget>[textAndIcons, image];

          return new Container(
            height: suggestion.suggestionLayout.suggestionHeight,
            width: suggestion.suggestionLayout.suggestionWidth,
            child: new Offstage(
              offstage: !visible,
              child: new Material(
                color: Colors.white,
                borderRadius: new BorderRadius.circular(
                  kSuggestionCornerRadius,
                ),
                elevation: shadow ? 3.0 : 0.0,
                child: new GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: onSelected,
                  child: new Row(children: rowChildren),
                ),
              ),
            ),
          );
        },
      );

  Widget _buildTextAndIcons(BuildContext context, Widget suggestionText) =>
      new Expanded(
        child: new Align(
          alignment: FractionalOffset.centerLeft,
          child: new Padding(
            padding: new EdgeInsets.only(
              left: suggestion.suggestionLayout.leftTextPadding,
              right: suggestion.suggestionLayout.rightTextPadding,
            ),
            child: new Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                suggestionText,
                _buildIconBar(context),
              ],
            ),
          ),
        ),
      );

  Widget _buildIconBar(BuildContext context) => new Offstage(
        offstage: suggestion.icons.length == 0 || _kIconsDisabled,
        child: new Container(
          margin: const EdgeInsets.only(
            top: _kVerticalSpacing,
            bottom: _kIconBarBottomMargin,
          ),
          height: _kIconSize,
          child: new Row(
            children: suggestion.icons
                .map(
                  (WidgetBuilder builder) => new Container(
                        margin: const EdgeInsets.only(right: _kIconSpacing),
                        width: _kIconSize,
                        child: builder(context),
                      ),
                )
                .toList(),
          ),
        ),
      );

  Widget _buildImage(BuildContext context, double suggestionHeight) =>
      suggestion.image == null
          ? new Container(width: 0.0)
          : new Container(
              width: kSuggestionImageWidth,
              child: suggestion.imageType == ImageType.circular
                  ? new Padding(
                      padding: new EdgeInsets.symmetric(
                        vertical:
                            (suggestionHeight - _kPersonImageDiameter) / 2.0,
                        horizontal:
                            (kSuggestionImageWidth - _kPersonImageDiameter) /
                                2.0,
                      ),
                      child: new ClipOval(
                        child: new SizedBox(
                          width: _kPersonImageDiameter,
                          height: _kPersonImageDiameter,
                          child: suggestion.image.call(context),
                        ),
                      ),
                    )
                  : new ClipRRect(
                      borderRadius: new BorderRadius.only(
                        topRight: new Radius.circular(kSuggestionCornerRadius),
                        bottomRight: new Radius.circular(
                          kSuggestionCornerRadius,
                        ),
                      ),
                      child: new Container(
                        constraints: new BoxConstraints.expand(),
                        child: suggestion.image.call(context),
                      ),
                    ),
            );
}
