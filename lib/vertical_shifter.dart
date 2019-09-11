// Copyright 2016 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/widgets.dart';

/// Shifts by [verticalShift] as [VerticalShifterState.shiftProgress] goes to
/// 1.0.
class VerticalShifter extends StatefulWidget {
  /// The amount to shift [child] vertically by.
  final double verticalShift;

  /// The widget to shift vertically.
  final Widget child;

  /// Constructor.
  VerticalShifter({Key key, this.verticalShift, this.child}) : super(key: key);

  @override
  VerticalShifterState createState() => new VerticalShifterState();
}

/// Tracks the current progress of the shift for [VerticalShifter].
class VerticalShifterState extends State<VerticalShifter> {
  double _shiftProgress = 0.0;

  /// The distance to shift up.
  set shiftProgress(double shiftProgress) => setState(() {
        _shiftProgress = shiftProgress;
      });

  @override
  Widget build(BuildContext context) => new Stack(
        fit: StackFit.passthrough,
        children: <Widget>[
          // Recent List.
          new Positioned(
            left: 0.0,
            right: 0.0,
            top: -_shiftAmount,
            bottom: _shiftAmount,
            child: widget.child,
          ),
        ],
      );

  double get _shiftAmount => _shiftProgress * widget.verticalShift;
}
