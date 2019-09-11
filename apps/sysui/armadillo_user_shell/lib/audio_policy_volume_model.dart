// Copyright 2017 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:apps.media.lib.dart/audio_policy.dart';
import 'package:armadillo/volume_model.dart';

/// Uses an [AudioPolicy] to set and get volume.
class AudioPolicyVolumeModel extends VolumeModel {
  /// Used to get and set the volume.
  final AudioPolicy audioPolicy;

  /// Ranges from 0.0 to 1.0.
  double _level = 0.0;

  /// Constructor.
  AudioPolicyVolumeModel({this.audioPolicy}) {
    _setLevelFromAudioPolicy();
    audioPolicy.updateCallback = _setLevelFromAudioPolicy;
  }

  @override
  double get level => _level;

  @override
  set level(double level) {
    if (level == _level) {
      return;
    }
    _level = level;
    audioPolicy.systemAudioPerceivedLevel = level;
    notifyListeners();
  }

  void _setLevelFromAudioPolicy() {
    level = audioPolicy.systemAudioMuted
        ? 0.0
        : audioPolicy.systemAudioPerceivedLevel;
  }
}
