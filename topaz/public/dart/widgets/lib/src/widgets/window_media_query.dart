// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:ui' as ui;

import 'package:flutter/widgets.dart';

/// Uses [ui.window] to create a [MediaQuery] parent for [child].
class WindowMediaQuery extends StatefulWidget {
  /// The [Widget] to be given a [MediaQuery] parent.
  final Widget child;

  /// Constructor.
  WindowMediaQuery({this.child});

  @override
  _WindowMediaQueryState createState() => new _WindowMediaQueryState();
}

class _WindowMediaQueryState extends State<WindowMediaQuery>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => new MediaQuery(
        data: new MediaQueryData.fromWindow(ui.window),
        child: widget.child,
      );

  @override
  void didChangeMetrics() => setState(() {});
}
