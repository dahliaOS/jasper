// Copyright 2017 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:lib.widgets/model.dart';

export 'package:lib.widgets/model.dart'
    show ScopedModel, Model, ScopedModelDescendant;

/// Tracks debug parameters, notifying listeners when they changes.
/// Using an [DebugModel] allows the debug parameters it tracks to be passed
/// down the widget tree using a [ScopedModel].
class DebugModel extends Model {
  bool _showTargetOverlay = false;
  bool _showTargetInfluenceOverlay = false;

  /// True if the target influence overlay should be shown.  This overlay shows
  /// which targets will be locked when a candidate is in a certain position.
  bool get showTargetInfluenceOverlay => _showTargetInfluenceOverlay;

  /// Set [showTargetInfluenceOverlay] to true to begin showing the
  /// target influence overlay.  This overlay shows which targets will be
  /// locked when a candidate is in a certain position.
  set showTargetInfluenceOverlay(bool showTargetInfluenceOverlay) {
    if (_showTargetInfluenceOverlay != showTargetInfluenceOverlay) {
      _showTargetInfluenceOverlay = showTargetInfluenceOverlay;
      notifyListeners();
    }
  }

  /// True if the visual representation of the targets should be shown.
  bool get showTargetOverlay => _showTargetOverlay;

  /// Set [showTargetOverlay] to true to begin showing a visual representation
  /// of the targets.
  set showTargetOverlay(bool showTargetOverlay) {
    if (_showTargetOverlay != showTargetOverlay) {
      _showTargetOverlay = showTargetOverlay;
      notifyListeners();
    }
  }

  /// Causes a switch between no overlays being shown, the visual representation
  /// of the targets being shown, and the target influence overlay being shown.
  void twiddle() {
    if (!showTargetOverlay && !showTargetInfluenceOverlay) {
      showTargetOverlay = true;
      showTargetInfluenceOverlay = false;
    } else if (!showTargetInfluenceOverlay) {
      showTargetOverlay = false;
      showTargetInfluenceOverlay = true;
    } else {
      showTargetOverlay = false;
      showTargetInfluenceOverlay = false;
    }
  }
}
