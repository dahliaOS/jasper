// Copyright 2016 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:widget_explorer_widgets/widget_explorer_widgets.dart';

import 'app.dart';
import 'drawer.dart';
import 'src/generated/index.dart';

/// This [Widget] displays the homepage of the gallery.
class Home extends StatefulWidget {
  /// Creates an instance of [Home].
  Home({
    Key key,
    bool showPerformanceOverlay,
    this.onShowPerformanceOverlayChanged,
  })
      : showPerformanceOverlay = showPerformanceOverlay ?? false,
        super(key: key);

  /// Indicates whether the performance overlay should be shown.
  final bool showPerformanceOverlay;

  /// A callback function to be called when the 'Performance Overlay' checkbox
  /// value is changed.
  final ValueChanged<bool> onShowPerformanceOverlayChanged;

  @override
  _HomeState createState() => new _HomeState();
}

class _HomeState extends State<Home> {
  @override
  Widget build(BuildContext context) {
    App app = context.ancestorWidgetOfExactType(App);

    return new Scaffold(
      appBar: new AppBar(title: new Text('FX Live Widget Gallery')),
      body: new WidgetExplorer(
        config: app?.config?.toJSON(),
        widgetSpecs: kWidgetSpecs,
        stateBuilders: kStateBuilders,
      ),
      drawer: new GalleryDrawer(
        showPerformanceOverlay: widget.showPerformanceOverlay,
        onShowPerformanceOverlayChanged: widget.onShowPerformanceOverlayChanged,
      ),
    );
  }
}
