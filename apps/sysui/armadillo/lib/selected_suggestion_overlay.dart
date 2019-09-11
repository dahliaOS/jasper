// Copyright 2016 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:sysui_widgets/ticking_state.dart';

import 'suggestion.dart';

/// Called when the [Widget] representing [Suggestion] has fully expanded to
/// fill its parent.
typedef void OnSuggestionExpanded(Suggestion suggestion);

/// When a Suggestion is selected, the suggestion is brought into this overlay
/// and an animation fills the overlay such that we can prepare the story that
/// will be displayed after the overlay animation finishes.
class SelectedSuggestionOverlay extends StatefulWidget {
  /// Called when a suggestion fully expands within the overlay.
  final OnSuggestionExpanded onSuggestionExpanded;

  /// Constructor.
  SelectedSuggestionOverlay({Key key, this.onSuggestionExpanded})
      : super(key: key);

  @override
  SelectedSuggestionOverlayState createState() =>
      new SelectedSuggestionOverlayState();
}

/// Holds the state associated with an expanding suggestion within the overlay.
class SelectedSuggestionOverlayState
    extends TickingState<SelectedSuggestionOverlay> {
  ExpansionBehavior _expansionBehavior;

  /// Expands the suggestion to fill the screen, using the effect specified in
  /// [expansionBehavior].
  /// Returns true if the overlay successfully initiates suggestion expansion.
  /// Returns false if an expansion is already taking place.
  bool suggestionSelected({ExpansionBehavior expansionBehavior}) {
    if (_expansionBehavior != null) {
      return false;
    }
    _expansionBehavior = expansionBehavior;
    _expansionBehavior.start();
    startTicking();
    return true;
  }

  @override
  Widget build(BuildContext context) => new LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) =>
          (_expansionBehavior == null)
              ? new Offstage(offstage: true)
              : _expansionBehavior.build(context, constraints));

  @override
  bool handleTick(double elapsedSeconds) {
    if (_expansionBehavior == null) {
      return false;
    }

    bool shouldContinue = _expansionBehavior.handleTick(elapsedSeconds);
    if (!shouldContinue) {
      _expansionBehavior = null;
    }
    return shouldContinue;
  }
}

/// How an expansion should occur.
abstract class ExpansionBehavior {
  /// Called to initialize the expansion.
  void start();

  /// Ticks any simulations associated with the expansion.
  bool handleTick(double elapsedSeconds);

  /// Creates the expanded [Widget].
  Widget build(BuildContext context, BoxConstraints constraints);
}
