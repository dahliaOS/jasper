// Copyright 2017 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:lib.widgets/model.dart';
import 'package:sysui_widgets/time_stringer.dart';

export 'package:lib.widgets/model.dart'
    show ScopedModel, Model, ScopedModelDescendant;

const String _kBackgroundImage = 'packages/armadillo/res/Background.jpg';

/// Provides assets and text based on context.
class ContextModel extends Model {
  final TimeStringer _timeStringer = new TimeStringer();

  /// The current background image to use.
  ImageProvider get backgroundImageProvider => new AssetImage(
        _kBackgroundImage,
      );

  /// The current battery percentage.
  String get batteryPercentage => '84%';

  /// The current wifi network.
  String get wifiNetwork => 'GoogleGuest';

  /// The current contextual location.
  String get contextualLocation => 'in San Francisco';

  /// The current time.
  String get timeOnly => _timeStringer.timeOnly;

  /// The current date.
  String get dateOnly => _timeStringer.dateOnly;

  /// The user's name.
  String get userName => 'Jane Doe';

  /// The user's image url.
  String get userImageUrl => 'packages/armadillo/res/User.png';

  @override
  void addListener(VoidCallback listener) {
    super.addListener(listener);
    if (listenerCount == 1) {
      _timeStringer.addListener(notifyListeners);
    }
  }

  @override
  void removeListener(VoidCallback listener) {
    super.removeListener(listener);
    if (listenerCount == 0) {
      _timeStringer.removeListener(notifyListeners);
    }
  }
}
