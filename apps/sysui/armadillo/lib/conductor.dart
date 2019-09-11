// Copyright 2016 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

import 'armadillo_overlay.dart';
import 'edge_scroll_drag_target.dart';
import 'expand_suggestion.dart';
import 'interruption_overlay.dart';
import 'quick_settings.dart';
import 'nothing.dart';
import 'now.dart';
import 'now_model.dart';
import 'peek_manager.dart';
import 'peeking_overlay.dart';
import 'scroll_locker.dart';
import 'selected_suggestion_overlay.dart';
import 'splash_suggestion.dart';
import 'story.dart';
import 'story_cluster.dart';
import 'story_cluster_drag_state_model.dart';
import 'story_list.dart';
import 'story_model.dart';
import 'suggestion.dart';
import 'suggestion_list.dart';
import 'suggestion_model.dart';
import 'vertical_shifter.dart';

/// The height of [Now] when maximized.
const double _kMaximizedNowHeight = 440.0;

/// How far [Now] should raise when quick settings is activated inline.
const double _kQuickSettingsHeightBump = 120.0;

/// How far above the bottom the suggestions overlay peeks.
const double _kSuggestionOverlayPeekHeight = 192.0;

/// If the width of the [Conductor] exceeds this value we will switch to
/// multicolumn mode for the [StoryList].
const double _kStoryListMultiColumnWidthThreshold = 500.0;

const double _kSuggestionOverlayPullScrollOffset = 100.0;
const double _kSuggestionOverlayScrollFactor = 1.2;

/// Target widths for the suggesiton section at different screen sizes.
const double _kTargetLargeSuggestionWidth = 736.0;
const double _kTargetSmallSuggestionWidth = 424.0;
const double _kSuggestionMinPadding = 40.0;

/// Called when an overlay becomes active or inactive.
typedef void OnOverlayChanged(bool active);

/// Manages the position, size, and state of the story list, user context,
/// suggestion overlay, device extensions. interruption overlay, and quick
/// settings overlay.
class Conductor extends StatefulWidget {
  /// Set to true to blur scrimmed children when performing an inline preview.
  final bool blurScrimmedChildren;

  /// Called when the quick settings overlay becomes active or inactive.
  final OnOverlayChanged onQuickSettingsOverlayChanged;

  /// Called when the suggestions overlay becomes active or inactive.
  final OnOverlayChanged onSuggestionsOverlayChanged;

  /// Called when the user taps log out from the quick settings.
  final VoidCallback onLogoutTapped;

  /// Called when the user long presses log out from the quick settings.
  final VoidCallback onLogoutLongPressed;

  /// Called when the user taps the user context.
  final VoidCallback onUserContextTapped;

  /// Used to manage peeking.
  final StoryClusterDragStateModel storyClusterDragStateModel;

  /// Used to manage peeking.
  final NowModel nowModel;

  /// The key of the interruption overlay.
  final GlobalKey<InterruptionOverlayState> interruptionOverlayKey;

  /// Called when an interruption is no longer showing.
  final OnInterruptionDismissed onInterruptionDismissed;

  /// Constructor.  [storyClusterDragStateModel] is used to create a
  /// [PeekManager] for the suggestion list's peeking overlay.
  Conductor({
    Key key,
    this.blurScrimmedChildren,
    this.onQuickSettingsOverlayChanged,
    this.onSuggestionsOverlayChanged,
    this.onLogoutTapped,
    this.onLogoutLongPressed,
    this.onUserContextTapped,
    this.storyClusterDragStateModel,
    this.nowModel,
    this.interruptionOverlayKey,
    this.onInterruptionDismissed,
  })
      : super(key: key);

  @override
  ConductorState createState() => new ConductorState();
}

/// Manages the state for [Conductor].
class ConductorState extends State<Conductor> {
  final GlobalKey<SuggestionListState> _suggestionListKey =
      new GlobalKey<SuggestionListState>();
  final ScrollController _suggestionListScrollController =
      new ScrollController();
  final GlobalKey<NowState> _nowKey = new GlobalKey<NowState>();
  final GlobalKey<QuickSettingsOverlayState> _quickSettingsOverlayKey =
      new GlobalKey<QuickSettingsOverlayState>();
  final GlobalKey<PeekingOverlayState> _suggestionOverlayKey =
      new GlobalKey<PeekingOverlayState>();

  /// The [VerticalShifter] is used to shift the [StoryList] up when [Now]'s
  /// inline quick settings are activated.
  final GlobalKey<VerticalShifterState> _verticalShifterKey =
      new GlobalKey<VerticalShifterState>();

  final ScrollController _scrollController = new ScrollController();
  final GlobalKey<ScrollLockerState> _scrollLockerKey =
      new GlobalKey<ScrollLockerState>();
  final GlobalKey<EdgeScrollDragTargetState> _edgeScrollDragTargetKey =
      new GlobalKey<EdgeScrollDragTargetState>();

  /// The key for adding [Suggestion]s to the [SelectedSuggestionOverlay].  This
  /// is to allow us to animate from a [Suggestion] in an open [SuggestionList]
  /// to a [Story] focused in the [StoryList].
  final GlobalKey<SelectedSuggestionOverlayState>
      _selectedSuggestionOverlayKey =
      new GlobalKey<SelectedSuggestionOverlayState>();

  final GlobalKey<ArmadilloOverlayState> _overlayKey =
      new GlobalKey<ArmadilloOverlayState>();

  final FocusScopeNode _conductorFocusNode = new FocusScopeNode();

  PeekManager _peekManager;

  bool _ignoreNextScrollOffsetChange = false;

  Timer _storyFocusTimer;

  @override
  void initState() {
    super.initState();
    _peekManager = new PeekManager(
      peekingOverlayKey: _suggestionOverlayKey,
      storyClusterDragStateModel: widget.storyClusterDragStateModel,
      nowModel: widget.nowModel,
    );
  }

  /// Note in particular the magic we're employing here to make the user
  /// state appear to be a part of the story list:
  /// By giving the story list bottom padding and clipping its bottom to the
  /// size of the final user state bar we have the user state appear to be
  /// a part of the story list and yet prevent the story list from painting
  /// behind it.
  @override
  Widget build(BuildContext context) => new LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          if (constraints.maxWidth == 0.0 || constraints.maxHeight == 0.0) {
            return new Offstage(offstage: true);
          }
          Size fullSize = new Size(
            constraints.maxWidth,
            constraints.maxHeight,
          );
          double minimizedNowHeight =
              constraints.maxHeight >= 640.0 ? 48.0 : 32.0;

          StoryModel storyModel = StoryModel.of(context);

          storyModel.updateLayouts(fullSize);

          // How sizing of the suggestion section works:
          // 1. Try to accommodate the large target width with mininum padding
          // 2. Try to accomodate the small target width with mininum padding
          // 3. Stretch to the full width of the screen
          double suggestionWidth;
          if (constraints.maxWidth >=
              _kTargetLargeSuggestionWidth + 2 * _kSuggestionMinPadding) {
            suggestionWidth = _kTargetLargeSuggestionWidth;
          } else if (constraints.maxWidth >
              _kTargetSmallSuggestionWidth + 2 * _kSuggestionMinPadding) {
            suggestionWidth = _kTargetSmallSuggestionWidth;
          } else {
            suggestionWidth = constraints.maxWidth;
          }

          Widget stack = new Stack(
            fit: StackFit.passthrough,
            children: <Widget>[
              /// Story List.
              new Positioned(
                left: 0.0,
                right: 0.0,
                top: 0.0,
                bottom: minimizedNowHeight,
                child: _getStoryList(
                  storyModel,
                  constraints.maxWidth,
                  new Size(
                    fullSize.width,
                    fullSize.height - minimizedNowHeight,
                  ),
                  minimizedNowHeight,
                ),
              ),

              // Now.
              _getNow(storyModel, constraints.maxWidth, minimizedNowHeight),

              // Suggestions Overlay.
              _getSuggestionOverlay(
                SuggestionModel.of(context),
                storyModel,
                suggestionWidth,
                (
                  BuildContext context,
                  double overlayHeight,
                  double suggestionWidth,
                  double suggestionHorizontalMargin,
                ) =>
                    new Stack(
                      children: <Widget>[
                        // Selected Suggestion Overlay.
                        _getSelectedSuggestionOverlay(),

                        // Interruption Overlay.
                        _buildInterruptionOverlay(
                          SuggestionModel.of(context),
                          storyModel,
                          context,
                          overlayHeight,
                          suggestionWidth,
                          suggestionHorizontalMargin,
                          minimizedNowHeight,
                        ),
                      ],
                    ),
                minimizedNowHeight,
              ),

              // Quick Settings Overlay.
              new QuickSettingsOverlay(
                key: _quickSettingsOverlayKey,
                minimizedNowBarHeight: minimizedNowHeight,
                onProgressChanged: (double progress) {
                  if (progress == 0.0) {
                    widget.onQuickSettingsOverlayChanged?.call(false);
                  } else {
                    widget.onQuickSettingsOverlayChanged?.call(true);
                  }
                },
                onLogoutTapped: widget.onLogoutTapped,
                onLogoutLongPressed: widget.onLogoutLongPressed,
              ),

              // Top and bottom edge scrolling drag targets.
              new Positioned.fill(
                child: new EdgeScrollDragTarget(
                  key: _edgeScrollDragTargetKey,
                  scrollController: _scrollController,
                ),
              ),

              // This layout builder tracks the size available for the
              // suggestion overlay and sets its maxHeight appropriately.
              // TODO(apwilson): refactor this to not be so weird.
              new LayoutBuilder(
                builder: (BuildContext context, BoxConstraints constraints) {
                  double targetMaxHeight = 0.8 * constraints.maxHeight;
                  if (_suggestionOverlayKey.currentState.maxHeight !=
                          targetMaxHeight &&
                      targetMaxHeight != 0.0) {
                    _suggestionOverlayKey.currentState.maxHeight =
                        targetMaxHeight;
                    if (!_suggestionOverlayKey.currentState.hiding) {
                      _suggestionOverlayKey.currentState.show();
                    }
                  }
                  return Nothing.widget;
                },
              ),
            ],
          );
          return new FocusScope(
            node: _conductorFocusNode,
            autofocus: true,
            child: stack,
          );
        },
      );

  Widget _getStoryList(
    StoryModel storyModel,
    double maxWidth,
    Size parentSize,
    double minimizedNowHeight,
  ) =>
      new VerticalShifter(
        key: _verticalShifterKey,
        verticalShift: _kQuickSettingsHeightBump,
        child: new ScrollLocker(
          key: _scrollLockerKey,
          child: new StoryList(
            scrollController: _scrollController,
            overlayKey: _overlayKey,
            blurScrimmedChildren: widget.blurScrimmedChildren,
            bottomPadding: _kMaximizedNowHeight + minimizedNowHeight,
            onScroll: (double scrollOffset) {
              if (_ignoreNextScrollOffsetChange) {
                _ignoreNextScrollOffsetChange = false;
                return;
              }
              _nowKey.currentState.scrollOffset = scrollOffset;

              // Peak suggestion overlay more when overscrolling.
              if (scrollOffset < -_kSuggestionOverlayPullScrollOffset &&
                  _suggestionOverlayKey.currentState.hiding) {
                _suggestionOverlayKey.currentState.setHeight(
                  _kSuggestionOverlayPeekHeight -
                      (scrollOffset + _kSuggestionOverlayPullScrollOffset) *
                          _kSuggestionOverlayScrollFactor,
                );
              }
            },
            onStoryClusterFocusStarted: () {
              // Lock scrolling.
              _scrollLockerKey.currentState.lock();
              _edgeScrollDragTargetKey.currentState.disable();
              _minimizeNow();
            },
            onStoryClusterFocusCompleted: (StoryCluster storyCluster) {
              _focusStoryCluster(storyModel, storyCluster);
            },
            parentSize: parentSize,
            onStoryClusterVerticalEdgeHover: () => goToOrigin(storyModel),
          ),
        ),
      );

  // We place Now in a RepaintBoundary as its animations
  // don't require its parent and siblings to redraw.
  Widget _getNow(
    StoryModel storyModel,
    double parentWidth,
    double minimizedNowHeight,
  ) =>
      new RepaintBoundary(
        child: new Now(
          key: _nowKey,
          parentWidth: parentWidth,
          minHeight: minimizedNowHeight,
          maxHeight: _kMaximizedNowHeight,
          quickSettingsHeightBump: _kQuickSettingsHeightBump,
          onQuickSettingsProgressChange: (double quickSettingsProgress) =>
              _verticalShifterKey.currentState.shiftProgress =
                  quickSettingsProgress,
          onMinimizedTap: () => goToOrigin(storyModel),
          onMinimizedLongPress: () =>
              _quickSettingsOverlayKey.currentState.show(),
          onQuickSettingsMaximized: () {
            // When quick settings starts being shown, scroll to 0.0.
            _scrollController.animateTo(
              0.0,
              duration: const Duration(milliseconds: 500),
              curve: Curves.fastOutSlowIn,
            );
          },
          onMinimize: () {
            _peekManager.nowMinimized = true;
            _suggestionOverlayKey.currentState.hide();
          },
          onMaximize: () {
            _peekManager.nowMinimized = false;
            _suggestionOverlayKey.currentState.hide();
          },
          onBarVerticalDragUpdate: (DragUpdateDetails details) =>
              _suggestionOverlayKey.currentState.onVerticalDragUpdate(details),
          onBarVerticalDragEnd: (DragEndDetails details) =>
              _suggestionOverlayKey.currentState.onVerticalDragEnd(details),
          onOverscrollThresholdRelease: () =>
              _suggestionOverlayKey.currentState.show(),
          scrollController: _scrollController,
          onLogoutTapped: widget.onLogoutTapped,
          onLogoutLongPressed: widget.onLogoutLongPressed,
          onUserContextTapped: widget.onUserContextTapped,
          onMinimizedContextTapped: () =>
              _suggestionOverlayKey.currentState.show(),
        ),
      );

  Widget _getSuggestionOverlay(
    SuggestionModel suggestionModel,
    StoryModel storyModel,
    double maxWidth,
    childAboveBuilder(
      BuildContext context,
      double overlayHeight,
      double suggestionWidth,
      double suggestionHorizontalMargin,
    ),
    double minimizedNowHeight,
  ) {
    return new PeekingOverlay(
      key: _suggestionOverlayKey,
      peekHeight: _kSuggestionOverlayPeekHeight,
      dragHandleHeight: kAskHeight,
      parentWidth: maxWidth,
      onHide: () {
        widget.onSuggestionsOverlayChanged?.call(false);
        if (_suggestionListScrollController.hasClients) {
          _suggestionListScrollController.animateTo(
            0.0,
            duration: const Duration(milliseconds: 1000),
            curve: Curves.fastOutSlowIn,
          );
        }
        _suggestionListKey.currentState?.stopAsking();
      },
      onShow: () {
        widget.onSuggestionsOverlayChanged?.call(true);
      },
      childAboveBuilder: (BuildContext context, double overlayHeight) =>
          childAboveBuilder(
            context,
            overlayHeight,
            SuggestionListState.getSuggestionWidth(
              maxWidth,
            ),
            SuggestionListState.getSuggestionHorizontalMargin(),
          ),
      child: new SuggestionList(
        key: _suggestionListKey,
        scrollController: _suggestionListScrollController,
        onAskingStarted: () {
          _suggestionOverlayKey.currentState.show();
        },
        onSuggestionSelected: (Suggestion suggestion, Rect globalBounds) =>
            _onSuggestionSelected(
              suggestionModel,
              storyModel,
              suggestion,
              globalBounds,
              minimizedNowHeight,
            ),
      ),
    );
  }

  void _onSuggestionSelected(
    SuggestionModel suggestionModel,
    StoryModel storyModel,
    Suggestion suggestion,
    Rect globalBounds,
    double minimizedNowHeight,
  ) {
    suggestionModel.onSuggestionSelected(suggestion);

    if (suggestion.selectionType == SelectionType.closeSuggestions) {
      _suggestionOverlayKey.currentState.hide();
    } else {
      _selectedSuggestionOverlayKey.currentState.suggestionSelected(
        expansionBehavior: suggestion.selectionType == SelectionType.launchStory
            ? new ExpandSuggestion(
                suggestion: suggestion,
                suggestionInitialGlobalBounds: globalBounds,
                bottomMargin: minimizedNowHeight,
                onSuggestionExpanded: (Suggestion suggestion) => _focusOnStory(
                  suggestion.selectionStoryId,
                  storyModel,
                ),
              )
            : new SplashSuggestion(
                suggestion: suggestion,
                suggestionInitialGlobalBounds: globalBounds,
                onSuggestionExpanded: (Suggestion suggestion) => _focusOnStory(
                  suggestion.selectionStoryId,
                  storyModel,
                ),
              ),
      );
      _minimizeNow();
    }
  }

  // This is only visible in transitoning the user from a Suggestion
  // in an open SuggestionList to a focused Story in the StoryList.
  Widget _getSelectedSuggestionOverlay() => new SelectedSuggestionOverlay(
        key: _selectedSuggestionOverlayKey,
      );

  Widget _buildInterruptionOverlay(
    SuggestionModel suggestionModel,
    StoryModel storyModel,
    BuildContext context,
    double overlayHeight,
    double suggestionWidth,
    double suggestionHorizontalMargin,
    double minimizedNowHeight,
  ) =>
      new InterruptionOverlay(
        key: widget.interruptionOverlayKey,
        overlayHeight: overlayHeight,
        onSuggestionSelected: (Suggestion suggestion, Rect globalBounds) =>
            _onSuggestionSelected(
              suggestionModel,
              storyModel,
              suggestion,
              globalBounds,
              minimizedNowHeight,
            ),
        suggestionWidth: suggestionWidth,
        suggestionHorizontalMargin: suggestionHorizontalMargin,
        onInterruptionDismissed: widget.onInterruptionDismissed,
      );

  void _defocus(StoryModel storyModel) {
    // Unfocus all story clusters.
    storyModel.activeSortedStoryClusters.forEach(
      (StoryCluster storyCluster) => storyCluster.unFocus(),
    );

    // Unlock scrolling.
    _scrollLockerKey.currentState.unlock();
    _edgeScrollDragTargetKey.currentState.enable();
    _scrollController.animateTo(
      0.0,
      duration: const Duration(milliseconds: 500),
      curve: Curves.fastOutSlowIn,
    );
  }

  void _focusStoryCluster(
    StoryModel storyModel,
    StoryCluster storyCluster,
  ) {
    // Tell the [StoryModel] the story is now in focus.  This will move the
    // [Story] to the front of the [StoryList].
    storyModel.interactionStarted(storyCluster);

    // We need to set the scroll offset to 0.0 to ensure the story
    // bars don't become untouchable when fully focused:
    // If we're at a scroll offset other than zero, the RenderStoryListBody
    // might not be as big as it would need to be to fully cover the screen and
    // thus would have areas where its painting but not receiving hit testing.
    // Right now the RenderStoryListBody ensures that its at least the size of
    // the screen when we're focused but doesn't take into account the scroll
    // offset.  It seems weird to size the RenderStoryListBody based on the
    // scroll offset and it also seems weird to scroll to offset 0.0 from some
    // arbitrary scroll offset when we defocus so this solves both issues with
    // one stone.
    //
    // If we don't ignore the onScroll resulting from setting the scroll offset
    // to 0.0 we will inadvertently maximize now and peek the suggestion
    // overlay.
    _ignoreNextScrollOffsetChange = true;
    _scrollController.jumpTo(0.0);

    _scrollLockerKey.currentState.lock();
    _edgeScrollDragTargetKey.currentState.disable();
  }

  void _minimizeNow() {
    _nowKey.currentState.minimize();
    _nowKey.currentState.hideQuickSettings();
    _peekManager.nowMinimized = true;
    _suggestionOverlayKey.currentState.hide();
  }

  /// Returns the state of the children to their initial values.
  /// This includes:
  /// 1) Unfocusing any focused stories.
  /// 2) Maximizing now.
  /// 3) Enabling scrolling of the story list.
  /// 4) Scrolling to the beginning of the story list.
  /// 5) Peeking the suggestion list.
  void goToOrigin(StoryModel storyModel) {
    _defocus(storyModel);
    _nowKey.currentState.maximize();
    storyModel.interactionStopped();
    storyModel.clearPlaceHolderStoryClusters();
  }

  /// Called to request the conductor focus on the cluster with [storyId].
  void requestStoryFocus(
    StoryId storyId,
    StoryModel storyModel, {
    bool jumpToFinish: true,
  }) {
    _scrollLockerKey.currentState.lock();
    _edgeScrollDragTargetKey.currentState.disable();
    _minimizeNow();
    _focusOnStory(storyId, storyModel, jumpToFinish: jumpToFinish);
  }

  void _focusOnStory(
    StoryId storyId,
    StoryModel storyModel, {
    bool jumpToFinish: true,
  }) {
    List<StoryCluster> targetStoryClusters =
        storyModel.storyClusters.where((StoryCluster storyCluster) {
      bool result = false;
      storyCluster.stories.forEach((Story story) {
        if (story.id == storyId) {
          result = true;
        }
      });
      return result;
    }).toList();

    // There should be only one story cluster with a story with this id.  If
    // that's not true, bail out.
    if (targetStoryClusters.length != 1) {
      print(
          'WARNING: Found ${targetStoryClusters.length} story clusters with a story with id $storyId. Returning to origin.');
      goToOrigin(storyModel);
    } else {
      // Unfocus all story clusters.
      storyModel.activeSortedStoryClusters.forEach(
        (StoryCluster storyCluster) => storyCluster.unFocus(),
      );

      // The story might have not been initiated when _focusOnStory is called.
      // This sets a periodic timer to wait for the story to be initiated
      // before running the animation.
      int timerCount = 0;
      _storyFocusTimer =
          new Timer.periodic(const Duration(milliseconds: 10), (Timer timer) {
        if (targetStoryClusters[0].focusSimulationKey.currentState != null &&
            mounted) {
          // Ensure the focused story is completely expanded.
          targetStoryClusters[0].focusSimulationKey.currentState.jump(1.0);

          // Ensure the focused story's story bar is full open.
          targetStoryClusters[0].maximizeStoryBars(jumpToFinish: jumpToFinish);

          // Focus on the story cluster.
          _focusStoryCluster(storyModel, targetStoryClusters[0]);

          timer.cancel();
        }

        // Give up if story has not been initiated after 1 second
        if (timerCount > 100) {
          timer.cancel();
        }

        timerCount++;
      });
    }

    // Unhide selected suggestion in suggestion list.
    _suggestionListKey.currentState.resetSelection();
  }

  @override
  void dispose() {
    super.dispose();
    if (_storyFocusTimer != null && _storyFocusTimer.isActive) {
      _storyFocusTimer.cancel();
    }
  }
}
