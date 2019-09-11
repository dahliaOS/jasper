// Copyright 2016 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';

import 'display_mode.dart';
import 'panel.dart';
import 'panel_resizing_model.dart';
import 'simulated_fractional.dart';
import 'story.dart';
import 'story_panels.dart';

const double _kUnfocusedStoryMargin = 1.0;
const double _kStoryMargin = 4.0;
const double _kStoryMarginWhenResizing = 24.0;
const double _kUnfocusedCornerRadius = 4.0;
const double _kFocusedCornerRadius = 8.0;

/// Positions the [child] in a [StoryPanels] within the given [currentSize] with
/// a [SimulatedFractional] based on [panel], [displayMode], and
/// [isFocused].
class StoryPositioned extends StatelessWidget {
  /// The current display mode of the cluster the story is within.
  final DisplayMode displayMode;

  /// True if the story is focused.
  final bool isFocused;

  /// The position of the story within its cluster in panel mode.
  final Panel panel;

  /// The size of the cluster.
  final Size currentSize;

  /// The progress of the cluster's focus simulation.
  final double focusProgress;

  /// The [Widget] representation of the [Story].
  final Widget child;

  /// The height of the [Story]'s story bar when maximized.
  final double storyBarMaximizedHeight;

  /// If key to use for the [SimulatedFractional] containing [child].
  final Key childContainerKey;

  /// If true, the corners of [child] will be rounded with a clip.
  final bool clip;

  /// Constructor.
  StoryPositioned({
    this.storyBarMaximizedHeight,
    this.displayMode,
    this.isFocused,
    this.panel,
    this.currentSize,
    this.focusProgress,
    this.childContainerKey,
    this.clip: true,
    this.child,
  }) {
    assert(child != null);
  }

  @override
  Widget build(BuildContext context) =>
      new ScopedModelDescendant<PanelResizingModel>(
          child: child,
          builder: (
            BuildContext context,
            Widget child,
            PanelResizingModel panelResizingModel,
          ) {
            EdgeInsets margins = getFractionalMargins(
              panel,
              currentSize,
              focusProgress,
              panelResizingModel,
            );

            Widget fractionalChild = !clip
                ? child
                : new ClipRRect(
                    borderRadius: new BorderRadius.vertical(
                      top: new Radius.circular(lerpDouble(
                        _kUnfocusedCornerRadius,
                        _kFocusedCornerRadius,
                        focusProgress,
                      )),
                      bottom: new Radius.circular(lerpDouble(
                        _kUnfocusedCornerRadius,
                        isFocused ? _kFocusedCornerRadius : 0.0,
                        focusProgress,
                      )),
                    ),
                    child: child);

            return displayMode == DisplayMode.panels
                ? new SimulatedFractional(
                    key: childContainerKey,
                    fractionalTop: panel.top + margins.top,
                    fractionalLeft: panel.left + margins.left,
                    fractionalWidth:
                        panel.width - (margins.left + margins.right),
                    fractionalHeight:
                        panel.height - (margins.top + margins.bottom),
                    size: currentSize,
                    child: fractionalChild,
                  )
                // If we're not in 'panel' displaymode we're in 'tabs' display
                // mode.  When that's the case, if we're focused we expand to
                // fit the entire area, otherwise we shrink our height to the height
                // of our story bar.
                : new SimulatedFractional(
                    key: childContainerKey,
                    fractionalTop: 0.0,
                    fractionalLeft: 0.0,
                    fractionalWidth: 1.0,
                    fractionalHeight: (isFocused)
                        ? 1.0
                        : storyBarMaximizedHeight / currentSize.height,
                    size: currentSize,
                    child: fractionalChild,
                  );
          });

  /// Returns the margins to use between [panel] and its neighbors within a
  /// cluster in fractions of the parent's [currentSize] and depending on
  /// the cluster's [focusProgress].  [panelResizingModel] indicates if a
  /// particular side of [panel] is in the process of being resized which
  /// effects the width of the margin on that side.
  static EdgeInsets getFractionalMargins(
    Panel panel,
    Size currentSize,
    double focusProgress,
    PanelResizingModel panelResizingModel,
  ) {
    double scale =
        lerpDouble(_kUnfocusedStoryMargin, _kStoryMargin, focusProgress) /
            _kStoryMargin;
    double leftScaledMargin = lerpDouble(
          _kStoryMargin,
          _kStoryMarginWhenResizing,
          panelResizingModel.getLeftProgress(panel),
        ) /
        2.0 *
        scale;
    double rightScaledMargin = lerpDouble(
          _kStoryMargin,
          _kStoryMarginWhenResizing,
          panelResizingModel.getRightProgress(panel),
        ) /
        2.0 *
        scale;
    double topScaledMargin = lerpDouble(
          _kStoryMargin,
          _kStoryMarginWhenResizing,
          panelResizingModel.getTopProgress(panel),
        ) /
        2.0 *
        scale;
    double bottomScaledMargin = lerpDouble(
          _kStoryMargin,
          _kStoryMarginWhenResizing,
          panelResizingModel.getBottomProgress(panel),
        ) /
        2.0 *
        scale;
    double topMargin =
        panel.top == 0.0 ? 0.0 : topScaledMargin / currentSize.height;
    double leftMargin =
        panel.left == 0.0 ? 0.0 : leftScaledMargin / currentSize.width;
    double bottomMargin =
        panel.bottom == 1.0 ? 0.0 : bottomScaledMargin / currentSize.height;
    double rightMargin =
        panel.right == 1.0 ? 0.0 : rightScaledMargin / currentSize.width;
    return new EdgeInsets.only(
      top: topMargin,
      left: leftMargin,
      bottom: bottomMargin,
      right: rightMargin,
    );
  }
}
