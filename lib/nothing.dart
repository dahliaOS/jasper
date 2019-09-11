// Copyright 2016 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/widgets.dart';

/// Holds [widget].
class Nothing {
  /// A [Widget] that displays nothing.
  static final Widget widget = new Offstage();

  Nothing._internal();
}
