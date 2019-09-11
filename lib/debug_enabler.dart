// Copyright 2017 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/widgets.dart';

import 'debug_model.dart';

/// Adds a button to enable debug features.
class DebugEnabler extends StatelessWidget {
  /// The model used for enabling/disabling debugging features.
  final DebugModel debugModel;

  /// The child whose bottom left will have the button overlaid on top of.
  final Widget child;

  /// Constructor.
  DebugEnabler({this.debugModel, this.child});

  @override
  Widget build(BuildContext context) => new Stack(
        fit: StackFit.passthrough,
        children: <Widget>[
          child,
          new Positioned(
            left: 0.0,
            bottom: 0.0,
            width: 50.0,
            height: 50.0,
            child: new GestureDetector(
              behavior: HitTestBehavior.translucent,
              onTap: debugModel.twiddle,
            ),
          ),
        ],
      );
}
