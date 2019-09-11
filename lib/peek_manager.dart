// Copyright 2017 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

import 'now_model.dart';
import 'peeking_overlay.dart';
import 'story_cluster_drag_state_model.dart';

/// Manages if the [PeekingOverlay] with the [peekingOverlayKey] should
/// be peeking or not.
class PeekManager {
  /// The peeking overlay managed by this manager.
  final GlobalKey<PeekingOverlayState> peekingOverlayKey;

  /// Provides whether or not a drag is happening.
  final StoryClusterDragStateModel storyClusterDragStateModel;

  /// Indicates if quick settings is active or not.
  final NowModel nowModel;

  bool _nowMinimized = false;
  bool _isDragging = false;
  bool _quickSettingsOpen = false;
  double _lastQuickSettingsProgress = 0.0;

  /// Constructor.
  PeekManager({
    this.peekingOverlayKey,
    this.storyClusterDragStateModel,
    this.nowModel,
  }) {
    storyClusterDragStateModel.addListener(_onStoryClusterDragStateChanged);
    nowModel.addListener(_onNowModelChanged);
  }

  /// Sets whether now is minimized or not.
  set nowMinimized(bool value) {
    if (_nowMinimized != value) {
      _nowMinimized = value;
      _updatePeek();
    }
  }

  void _onStoryClusterDragStateChanged() {
    if (_isDragging != storyClusterDragStateModel.isDragging) {
      _isDragging = storyClusterDragStateModel.isDragging;
      _updatePeek();
    }
  }

  void _onNowModelChanged() {
    if (_lastQuickSettingsProgress != nowModel.quickSettingsProgress) {
      bool quickSettingsOpen =
          nowModel.quickSettingsProgress > _lastQuickSettingsProgress;
      _lastQuickSettingsProgress = nowModel.quickSettingsProgress;
      if (_quickSettingsOpen != quickSettingsOpen) {
        _quickSettingsOpen = quickSettingsOpen;
        _updatePeek();
      }
    }
  }

  void _updatePeek() {
    peekingOverlayKey.currentState.peek =
        (!_nowMinimized && !_isDragging && !_quickSettingsOpen);
  }
}
