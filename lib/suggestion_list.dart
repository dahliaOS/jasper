// Copyright 2016 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:math' as math;

import 'package:collection/collection.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

import 'elevation_constants.dart';
import 'suggestion.dart';
import 'suggestion_layout.dart';
import 'suggestion_model.dart';
import 'suggestion_widget.dart';

const String _kLogoSmall = 'packages/armadillo/res/logo_googleg_24dpx4.png';
const String _kLogoLarge =
    'packages/armadillo/res/googlelogo_color_62x24dp.png';
const String _kMicImage = 'packages/armadillo/res/googlemic_color_24dp.png';
const Duration _kFadeInDuration = const Duration(milliseconds: 500);

/// The height of the ask section of the suggerion list.
const double kAskHeight = 72.0;

/// The gap between suggestions.
const double _kSuggestionGap = 16.0;

const double _kThreeColumnWidthThreshold =
    kSuggestionWidth * 3 + _kSuggestionGap * 4;
const double _kTwoColumnWidthThreshold =
    kSuggestionWidth * 2 + _kSuggestionGap * 3;
const double _kOneColumnWidthThreshold = kSuggestionWidth + _kSuggestionGap * 2;
const double _kThreeColumnWidth = kSuggestionWidth * 3 + _kSuggestionGap * 2;
const double _kTwoColumnWidth = kSuggestionWidth * 2 + _kSuggestionGap;
const double _kOneColumnWidth = kSuggestionWidth;
const double _kSuggestionListBottomPadding = 32.0;

const ListEquality<Suggestion> _kSuggestionListEquality =
    const ListEquality<Suggestion>();

/// Called when a suggestion is selected.  [globalBounds] indicates the location
/// of the widget representing [suggestion] was on screen when it was selected.
typedef void OnSuggestionSelected(Suggestion suggestion, Rect globalBounds);

/// Displays a list of suggestions and provides a mechanism for asking for
/// new things to do.
class SuggestionList extends StatefulWidget {
  /// The controller to use for scrolling the list.
  final ScrollController scrollController;

  /// Called when the user begins asking.
  final VoidCallback onAskingStarted;

  /// Called when the user ends asking.
  final VoidCallback onAskingEnded;

  /// Called when a suggestion is selected.
  final OnSuggestionSelected onSuggestionSelected;

  /// Constructor.
  SuggestionList({
    Key key,
    this.scrollController,
    this.onAskingStarted,
    this.onAskingEnded,
    this.onSuggestionSelected,
  }) : super(key: key);

  @override
  SuggestionListState createState() => new SuggestionListState();
}

/// Manages the asking state for the [SuggestionList].
class SuggestionListState extends State<SuggestionList>
    with TickerProviderStateMixin {
  final TextEditingController _askTextController = new TextEditingController();
  final FocusNode _askFocusNode = new FocusNode();
  bool _asking = false;
  Suggestion _selectedSuggestion;
  DateTime _lastBuildTime;
  AnimationController _fadeInAnimation;
  CurvedAnimation _curvedFadeInAnimation;

  @override
  void initState() {
    super.initState();
    _fadeInAnimation = new AnimationController(
      vsync: this,
      value: 0.0,
      duration: _kFadeInDuration,
    );
    _curvedFadeInAnimation = new CurvedAnimation(
      parent: _fadeInAnimation,
      curve: Curves.fastOutSlowIn,
    );
    _askFocusNode.addListener(() {
      if (_askFocusNode.hasFocus) {
        if (_asking == false) {
          setState(() {
            _asking = true;
          });
          SuggestionModel.of(context).asking = _asking;
          widget.onAskingStarted?.call();
        }
      }
    });
  }

  /// Clears the ask text.
  void _clear() {
    _askTextController.clear();
    SuggestionModel.of(context).askText = null;
  }

  /// Clears the last selected suggestion.  The selected suggestion isn't drawn
  /// in favor of a splash transition drawing it.
  void resetSelection() {
    setState(() {
      _selectedSuggestion = null;
    });
  }

  /// Stops asking and clears the the ask text.
  void stopAsking() {
    _askFocusNode.unfocus();
    _clear();
    if (!_asking) {
      return;
    }
    setState(() {
      _asking = false;
      SuggestionModel.of(context).asking = _asking;
      widget.onAskingEnded?.call();
    });
  }

  /// Selects the first suggestion in the list as if it had been tapped.
  void selectFirstSuggestions() {
    List<Suggestion> suggestions = SuggestionModel.of(context).suggestions;
    if (suggestions.isNotEmpty) {
      _onSuggestionSelected(suggestions[0]);
    }
  }

  @override
  Widget build(BuildContext context) => new Overlay(
        initialEntries: <OverlayEntry>[
          new OverlayEntry(
            builder: (BuildContext context) => new LayoutBuilder(
              builder: (BuildContext context, BoxConstraints constraints) =>
                  new PhysicalModel(
                elevation: Elevations.suggestionList,
                color: Colors.white,
                borderRadius: const BorderRadius.only(
                  topLeft: const Radius.circular(8.0),
                  topRight: const Radius.circular(8.0),
                ),
                child: new ScopedModelDescendant<SuggestionModel>(
                  builder: (
                    BuildContext context,
                    Widget child,
                    SuggestionModel suggestionModel,
                  ) {
                    _lastBuildTime = new DateTime.now();
                    _fadeInAnimation.value = 0.0;
                    _fadeInAnimation.forward();
                    List<Suggestion> suggestions = suggestionModel.suggestions;
                    return new Stack(
                      children: <Widget>[
                        // We overlap a little to avoid aliasing issues.
                        new Positioned.fill(
                          top: kAskHeight - 8.0,
                          child: new Container(
                            color: const Color(0xFFDBE2E5),
                            padding: new EdgeInsets.only(
                              top: 32.0,
                            ),
                            child: new CustomScrollView(
                              controller: widget.scrollController,
                              slivers: <Widget>[
                                new SliverGrid(
                                  gridDelegate:
                                      new _SuggestionListSliverGridDelegate(
                                    suggestions: suggestions,
                                  ),
                                  delegate: new SliverChildBuilderDelegate(
                                    (BuildContext context, int index) =>
                                        _createSuggestion(
                                      suggestions[index],
                                    ),
                                    childCount: suggestions.length,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        new Positioned(
                          left: 0.0,
                          right: 0.0,
                          top: 0.0,
                          height: kAskHeight,
                          child: new Container(
                            decoration: new BoxDecoration(
                              color: Colors.white,
                            ),
                            padding: new EdgeInsets.symmetric(
                              horizontal: _getLeftOffset(
                                constraints.maxWidth,
                              ),
                            ),
                            child: _buildAsk(context),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ),
        ],
      );

  Widget _buildAsk(BuildContext context) => new GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          FocusScope.of(context).requestFocus(_askFocusNode);
        },
        child: new Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.start,
          children: <Widget>[
            new Image.asset(
              _askFocusNode.hasFocus ? _kLogoSmall : _kLogoLarge,
              height: 24.0,
              fit: BoxFit.fitHeight,
            ),
            new Container(width: 16.0),
            // Ask Anything text field.
            new Expanded(
              child: new Material(
                color: Colors.transparent,
                child: new TextField(
                  decoration: new InputDecoration(),
                  style: new TextStyle(
                    fontSize: 16.0,
                    color: Colors.grey[600],
                  ),
                  focusNode: _askFocusNode,
                  controller: _askTextController,
                  onChanged: (String text) {
                    SuggestionModel.of(context).askText = text;
                  },
                  onSubmitted: (String text) {
                    // Select the first suggestion on text commit (ie.
                    // Pressing enter or tapping 'Go').
                    List<Suggestion> suggestions =
                        SuggestionModel.of(context).suggestions;
                    if (suggestions.isNotEmpty) {
                      _onSuggestionSelected(suggestions.first);
                    }
                  },
                ),
              ),
            ),
            new Image.asset(
              _kMicImage,
              height: 24.0,
              fit: BoxFit.fitHeight,
            ),
          ],
        ),
      );

  void _onSuggestionSelected(Suggestion suggestion) {
    if (new DateTime.now().difference(_lastBuildTime) < _kFadeInDuration) {
      return;
    }
    switch (suggestion.selectionType) {
      case SelectionType.launchStory:
      case SelectionType.modifyStory:
      case SelectionType.closeSuggestions:
        setState(() {
          _selectedSuggestion = suggestion;
        });
        // We pass the bounds of the suggestion w.r.t.
        // global coordinates so it can be mapped back to
        // local coordinates when it's displayed in the
        // SelectedSuggestionOverlay.
        RenderBox box = suggestion.globalKey.currentContext.findRenderObject();
        widget.onSuggestionSelected(
          suggestion,
          box.localToGlobal(Offset.zero) & box.size,
        );
        break;
      case SelectionType.doNothing:
      default:
        break;
    }
  }

  Widget _createSuggestion(Suggestion suggestion) => new RepaintBoundary(
        child: new FadeTransition(
          opacity: _curvedFadeInAnimation,
          child: new SuggestionWidget(
            key: suggestion.globalKey,
            visible: _selectedSuggestion?.id != suggestion.id,
            suggestion: suggestion,
            onSelected: () => _onSuggestionSelected(suggestion),
          ),
        ),
      );

  /// Determines the width of a suggestion in the suggestion list.
  static double getSuggestionWidth(double maxWidth) =>
      math.min(kSuggestionWidth, maxWidth - 2 * _kSuggestionGap);

  /// Determines the horizontal margin of suggestions in the suggestion list.
  static double getSuggestionHorizontalMargin() => _kSuggestionGap;
}

class _SuggestionListSliverGridDelegate extends SliverGridDelegate {
  final List<Suggestion> suggestions;

  _SuggestionListSliverGridDelegate({this.suggestions});

  @override
  SliverGridLayout getLayout(SliverConstraints constraints) =>
      new _SuggestionListSliverGridLayout(
        suggestions: suggestions,
        width: constraints.crossAxisExtent,
      );

  @override
  bool shouldRelayout(_SuggestionListSliverGridDelegate oldDelegate) =>
      !_kSuggestionListEquality.equals(suggestions, oldDelegate.suggestions);
}

class _SuggestionListSliverGridLayout extends SliverGridLayout {
  final List<Suggestion> suggestions;
  final double width;

  _SuggestionListSliverGridLayout({this.suggestions, this.width});

  /// The minimum child index that is visible at (or after) this scroll offset.
  @override
  int getMinChildIndexForScrollOffset(double scrollOffset) =>
      suggestions.isEmpty ? -1 : 0;

  /// The maximum child index that is visible at (or before) this scroll offset.
  @override
  int getMaxChildIndexForScrollOffset(double scrollOffset) =>
      suggestions.isEmpty ? -1 : suggestions.length - 1;

  /// The size and position of the child with the given index.
  @override
  SliverGridGeometry getGeometryForChildIndex(int index) {
    if (index < 0 || index >= suggestions.length) {
      return new SliverGridGeometry(
        scrollOffset: 0.0,
        crossAxisOffset: 0.0,
        mainAxisExtent: 0.0,
        crossAxisExtent: 0.0,
      );
    }
    int columnCount = _getColumnCount(width);
    double leftOffset = _getLeftOffset(width);
    double crossAxisExtent = width >= kSuggestionWidth + 2 * _kSuggestionGap
        ? kSuggestionWidth
        : width - 2 * _kSuggestionGap;
    double crossAxisOffset = (columnCount == 1)
        ? leftOffset
        : (columnCount == 2 && ((index % 2) == 0))
            ? leftOffset
            : (columnCount == 2 && ((index % 2) == 1))
                ? leftOffset + _kSuggestionGap + kSuggestionWidth
                : ((index % 3) == 0)
                    ? leftOffset
                    : ((index % 3) == 1)
                        ? leftOffset + _kSuggestionGap + kSuggestionWidth
                        : leftOffset +
                            _kSuggestionGap * 2 +
                            kSuggestionWidth * 2;
    suggestions[index].suggestionLayout.layout(width);
    double mainAxisExtent =
        suggestions[index].suggestionLayout.suggestionHeight;
    double scrollOffset = 0.0;
    for (int i = index - columnCount; i >= 0; i -= columnCount) {
      scrollOffset += _kSuggestionGap;
      suggestions[i].suggestionLayout.layout(width);
      scrollOffset += suggestions[i].suggestionLayout.suggestionHeight;
    }
    return new SliverGridGeometry(
      scrollOffset: scrollOffset,
      crossAxisOffset: crossAxisOffset,
      mainAxisExtent: mainAxisExtent,
      crossAxisExtent: crossAxisExtent,
    );
  }

  @override
  double computeMaxScrollOffset(int childCount) {
    print('APW Dummy implementation!  Review!');
    return double.infinity;
  }

  /// An estimate of the scroll extent needed to fully display all the tiles if
  /// there are `childCount` children in total.
  @override
  double estimateMaxScrollOffset(int childCount) {
    int columnCount = _getColumnCount(width);
    double maxScrollOffset = 0.0;
    for (int i = 0; i < math.min(childCount, columnCount); i++) {
      SliverGridGeometry geometry =
          getGeometryForChildIndex(childCount - 1 - i);
      maxScrollOffset = math.max(
        maxScrollOffset,
        geometry.scrollOffset +
            geometry.mainAxisExtent +
            _kSuggestionListBottomPadding,
      );
    }
    return maxScrollOffset;
  }
}

double _getLeftOffset(double width) => width >= _kThreeColumnWidthThreshold
    ? (width - _kThreeColumnWidth) / 2.0
    : width >= _kTwoColumnWidthThreshold
        ? (width - _kTwoColumnWidth) / 2.0
        : width >= _kOneColumnWidthThreshold
            ? (width - _kOneColumnWidth) / 2.0
            : _kSuggestionGap;

int _getColumnCount(double width) => width >= _kThreeColumnWidthThreshold
    ? 3
    : width >= _kTwoColumnWidthThreshold ? 2 : 1;
