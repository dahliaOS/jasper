// Copyright 2017 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:fixtures/fixtures.dart';
import 'package:flutter/widgets.dart';

export 'package:fixtures/fixtures.dart';

/// [Fixtures] extension class for FX widgets.
class WidgetFixtures extends Fixtures {
  /// Returns a [Text] widget with a randomly generated sentence in it.
  Text sentenceText() {
    return new Text(lorem.createSentence());
  }
}
