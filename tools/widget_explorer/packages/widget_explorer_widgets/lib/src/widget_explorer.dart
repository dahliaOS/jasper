// Copyright 2017 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:meta/meta.dart';
import 'package:widget_explorer_core/widget_specs.dart';
import 'package:widget_explorer_widgets/widget_explorer_widgets.dart';

const double _kMaxWidth = 1000.0;
const double _kMaxHeight = 1000.0;
const double _kMaxSize = 1000.0;
const double _kDefaultWidth = 500.0;
const double _kDefaultHeight = 500.0;

/// The main screen of a Widget Explorer app that lists all the widgets and
/// their specs.
class WidgetExplorer extends StatefulWidget {
  /// Config provider.
  final Map<String, dynamic> config;

  /// Map of all the widget names and their widget specs.
  ///
  /// This value should be the `kWidgetSpecs` variable, which can be found in
  /// the `index.dart` file in the `widget_explorer_gen` tool's output dir.
  final Map<String, WidgetSpecs> widgetSpecs;

  /// Map of all the widget names and their generated state builders.
  ///
  /// This value should be the `kStateBuilders` variable, which can be found in
  /// the `index.dart` file in the `widget_explorer_gen` tool's output dir.
  final Map<String, GeneratedStateBuilder> stateBuilders;

  /// Creates a new instance of [WidgetExplorer].
  const WidgetExplorer({
    @required this.widgetSpecs,
    @required this.stateBuilders,
    Key key,
    this.config,
  })  : assert(widgetSpecs != null),
        assert(stateBuilders != null),
        super(key: key);

  @override
  _WidgetExplorerState createState() => new _WidgetExplorerState();
}

class _WidgetExplorerState extends State<WidgetExplorer> {
  String selectedWidget;
  Key contentKey;
  Size size;
  Map<String, Size> widgetSizes;

  _WidgetExplorerState() {
    contentKey = new UniqueKey();
    size = const Size(_kDefaultWidth, _kDefaultHeight);
    widgetSizes = <String, Size>{};
  }

  @override
  Widget build(BuildContext context) {
    return new Row(
      children: <Widget>[
        _buildMenu(),
        new Expanded(child: _buildContents()),
      ],
    );
  }

  Widget _buildMenu() {
    List<String> widgetNames = widget.widgetSpecs.keys.toList()..sort();
    List<ListTile> tiles = widgetNames
        .map((String name) => widget.widgetSpecs[name])
        .map((WidgetSpecs specs) => new ListTile(
              title: new Text(specs.name),
              subtitle: new Text(specs.doc?.split('\n')?.first),
              onTap: () => _selectWidget(specs),
            ))
        .toList();

    return new Drawer(
      child: new ListView(children: tiles),
      elevation: 4.0,
    );
  }

  Widget _buildContents() {
    WidgetSpecs specs = widget.widgetSpecs[selectedWidget];
    if (specs == null) {
      return const Center(
        child: const Text('Please select a widget from the left pane.'),
      );
    }

    // Display the widget name as heading 1, follwed by the dartdoc comments.
    String markdownText = '''# ${specs.name}

${specs.doc}

#### Location

${specs.pathFromFuchsiaRoot != null ? '**Defined In**: `FUCHSIA_ROOT/${specs.pathFromFuchsiaRoot}`' : ''}

**Import Path**: `package:${specs.packageName}/${specs.path}`

''';

    return new Align(
      alignment: FractionalOffset.topLeft,
      child: new ListView(
        key: contentKey,
        children: <Widget>[
          new Container(
            padding: const EdgeInsets.all(16.0),
            child: new MarkdownBody(
              data: markdownText,
              styleSheet:
                  new MarkdownStyleSheet.largeFromTheme(Theme.of(context)),
            ),
          ),
          _buildSizeControl(),
          new WidgetExplorerWrapper(
            config: widget.config,
            width: size.width,
            height: size.height,
            stateBuilder: widget.stateBuilders[specs.name],
          ),
        ],
      ),
    );
  }

  Widget _buildSizeControl() {
    return new Container(
      decoration: new BoxDecoration(
        border: new Border.all(color: Colors.grey[500]),
        borderRadius: const BorderRadius.all(const Radius.circular(4.0)),
      ),
      margin: const EdgeInsets.all(16.0),
      child: new Container(
        alignment: FractionalOffset.topLeft,
        margin: const EdgeInsets.all(16.0),
        child: new Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: widget.widgetSpecs[selectedWidget].hasSizeParam
              ? <Widget>[
                  _buildSizeRow(
                    'Size',
                    size.width,
                    _adjustWidthAndHeight,
                    _kMaxSize,
                  ),
                ]
              : <Widget>[
                  _buildSizeRow(
                    'Width',
                    size.width,
                    _adjustWidth,
                    _kMaxWidth,
                  ),
                  _buildSizeRow(
                    'Height',
                    size.height,
                    _adjustHeight,
                    _kMaxHeight,
                  ),
                ],
        ),
      ),
    );
  }

  Widget _buildSizeRow(
    String rowName,
    double value,
    ValueChanged<double> onChanged,
    double max,
  ) {
    return new Row(
      children: <Widget>[
        new Container(
          width: 100.0,
          child: new Text('$rowName: ${value.toStringAsFixed(1)}'),
        ),
        new Expanded(
          child: new Slider(
            value: value,
            onChanged: onChanged,
            min: 0.0,
            max: max,
          ),
        ),
      ],
    );
  }

  void _selectWidget(WidgetSpecs specs) {
    if (selectedWidget == specs.name) {
      return;
    }

    setState(() {
      selectedWidget = specs.name;

      /// This key used to force the top-level ListView state to be recreated
      /// and initialized, when the user selects a new widget from the menu.
      ///
      /// Without this key, the ListView state is unintentionally reused and
      /// thus incorrectly displays the previous widget information.
      contentKey = new UniqueKey();

      // If there is a size remembered for this widget, restore that value.
      // Otherwise, use the default size for this widget.
      size = widgetSizes[selectedWidget] ?? _getDefaultSize(specs);
    });
  }

  Size _getDefaultSize(WidgetSpecs specs) {
    double width = specs.exampleWidth ?? _kDefaultWidth;
    double height = specs.exampleHeight ?? _kDefaultHeight;
    return new Size(width, height);
  }

  void _adjustWidth(double width) {
    _adjustSize(width: width);
  }

  void _adjustHeight(double height) {
    _adjustSize(height: height);
  }

  void _adjustWidthAndHeight(double size) {
    _adjustSize(width: size, height: size);
  }

  void _adjustSize({double width, double height}) {
    setState(() {
      double newWidth = width ?? size.width;
      double newHeight = height ?? size.height;
      size = new Size(newWidth, newHeight);
      widgetSizes[selectedWidget] = size;
    });
  }
}
