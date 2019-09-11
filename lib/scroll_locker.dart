// Copyright 2016 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/physics.dart';
import 'package:flutter/widgets.dart';

/// Locks and unlocks scrolling in its [child] and its descendants.
class ScrollLocker extends StatefulWidget {
  /// The Widget whose scrolling will be locked.
  final Widget child;

  /// Constructor.
  ScrollLocker({Key key, this.child}) : super(key: key);

  @override
  ScrollLockerState createState() => new ScrollLockerState();
}

/// The [State] of [ScrollLocker].
class ScrollLockerState extends State<ScrollLocker> {
  /// When true, list scrolling is disabled.
  bool _lockScrolling = false;

  @override
  Widget build(BuildContext context) => new ScrollConfiguration(
        behavior: new _LockingScrollBehavior(lock: _lockScrolling),
        child: widget.child,
      );

  /// Locks the scrolling of [ScrollLocker.child].
  void lock() {
    setState(() {
      _lockScrolling = true;
    });
  }

  /// Unlocks the scrolling of [ScrollLocker.child].
  void unlock() {
    setState(() {
      _lockScrolling = false;
    });
  }
}

class _LockingScrollBehavior extends ScrollBehavior {
  final bool lock;
  const _LockingScrollBehavior({this.lock: false});

  @override
  ScrollPhysics getScrollPhysics(BuildContext context) => lock
      ? const _LockedScrollPhysics(parent: const BouncingScrollPhysics())
      : const BouncingScrollPhysics();

  @override
  bool shouldNotify(_LockingScrollBehavior old) {
    return lock != old.lock;
  }
}

class _LockedScrollPhysics extends ScrollPhysics {
  const _LockedScrollPhysics({ScrollPhysics parent}) : super(parent: parent);

  @override
  _LockedScrollPhysics applyTo(ScrollPhysics parent) =>
      new _LockedScrollPhysics(parent: parent);

  @override
  Simulation createBallisticSimulation(
    ScrollMetrics position,
    double velocity,
  ) =>
      null;

  @override
  double applyPhysicsToUserOffset(ScrollMetrics position, double offset) => 0.0;
}
