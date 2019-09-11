// Copyright 2017 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'volume_model.dart';

/// By default does nothing but store a double [level].
class DummyVolumeModel extends VolumeModel {
  double _level = 0.0;

  @override
  double get level => _level;

  @override
  set level(double level) {
    if (level == _level) {
      return;
    }
    _level = level;
    notifyListeners();
  }
}
