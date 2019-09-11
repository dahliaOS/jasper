// Copyright 2016 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/widgets.dart';

/// See [ThreeColumnAlignedLayoutDelegate] for details.
enum ThreeColumnAlignedLayoutDelegateParts {
  /// Indicates the widget is left aligned and can use up as much space as it
  /// wants.
  left,

  /// Indicates the widget is centered if it can do so without getting to close
  /// ([ThreeColumnAlignedLayoutDelegate.partMargin]) to the other
  /// [ThreeColumnAlignedLayoutDelegateParts].  If it cannot be centered, it
  /// will keep a minimum distance
  /// ([ThreeColumnAlignedLayoutDelegate.partMargin]) from [left] and [right]
  /// while trying to be as close to center as possible.
  center,

  /// Indicates the widget is right aligned and can use up as much space as it
  /// wants.
  right,
}

/// Lays out [ThreeColumnAlignedLayoutDelegateParts] as follows:
/// 1. All [ThreeColumnAlignedLayoutDelegateParts] are vertically centered.
/// 2. [ThreeColumnAlignedLayoutDelegateParts.left] is left aligned and can use
///    up as much space as it likes.
/// 3. [ThreeColumnAlignedLayoutDelegateParts.right] is right aligned and can
///    use up as much space as it likes.
/// 4. [ThreeColumnAlignedLayoutDelegateParts.center] is centered if it can do
///    so without getting to close ([partMargin]) to the other
///    [ThreeColumnAlignedLayoutDelegateParts].  If it cannot be centered, it
///    will keep a minimum distance ([partMargin]) from
///    [ThreeColumnAlignedLayoutDelegateParts.left] and
///    [ThreeColumnAlignedLayoutDelegateParts.right] while trying to be as close
///    to center as possible.
class ThreeColumnAlignedLayoutDelegate extends MultiChildLayoutDelegate {
  /// The minimum distance [ThreeColumnAlignedLayoutDelegateParts.center] can be
  /// to [ThreeColumnAlignedLayoutDelegateParts.left] and
  /// [ThreeColumnAlignedLayoutDelegateParts.right].
  final double partMargin;

  /// Constructor.
  ThreeColumnAlignedLayoutDelegate({this.partMargin});

  @override
  void performLayout(Size size) {
    // Lay out children.
    Size leftSize = layoutChild(ThreeColumnAlignedLayoutDelegateParts.left,
        new BoxConstraints.loose(size));
    Size rightSize = layoutChild(ThreeColumnAlignedLayoutDelegateParts.right,
        new BoxConstraints.loose(size));
    Size centerSize = layoutChild(
        ThreeColumnAlignedLayoutDelegateParts.center,
        new BoxConstraints.loose(size).deflate(new EdgeInsets.only(
            left: partMargin + leftSize.width,
            right: partMargin + rightSize.width)));

    // Position children.
    positionChild(ThreeColumnAlignedLayoutDelegateParts.left,
        new Offset(0.0, (size.height - leftSize.height) / 2.0));
    positionChild(
        ThreeColumnAlignedLayoutDelegateParts.right,
        new Offset(size.width - rightSize.width,
            (size.height - rightSize.height) / 2.0));
    double centerLeft = (size.width - centerSize.width) / 2.0;
    if (centerLeft < leftSize.width + partMargin) {
      // If we're too close to the left element, shift to the right.
      centerLeft = leftSize.width + partMargin;
    } else if (centerLeft + centerSize.width > size.width - rightSize.width) {
      // If we're too close to the right element, shift to the left.
      centerLeft = size.width - rightSize.width - centerSize.width;
    }
    positionChild(ThreeColumnAlignedLayoutDelegateParts.center,
        new Offset(centerLeft, (size.height - centerSize.height) / 2.0));
  }

  @override
  bool shouldRelayout(ThreeColumnAlignedLayoutDelegate oldDelegate) =>
      partMargin != oldDelegate.partMargin;
}
