// Copyright 2017 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/widgets.dart';

/// Used to allow [deviceExtensions] to push [child] up from the bottom (by
/// shrinking [child]'s height) when they grow in size.
///
/// An example of a device extension would be an IME or some other button bar
/// that should appear to be an extension of device hardware rather than a
/// software UI.
class DeviceExtender extends StatelessWidget {
  /// The [Widget] that will be resized when the device extensions are activated
  /// and deactivated.
  final Widget child;

  /// Device extensions which will push [child] up when activated.
  final List<Widget> deviceExtensions;

  /// Constructor.
  DeviceExtender({this.child, this.deviceExtensions: const <Widget>[]});

  @override
  Widget build(BuildContext context) {
    List<Widget> columnChildren = <Widget>[];
    columnChildren.add(new Expanded(child: child));
    columnChildren.addAll(deviceExtensions);
    return new Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: columnChildren,
    );
  }
}
