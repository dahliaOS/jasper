// Copyright 2017 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:meta/meta.dart';

const double _kTableRowVerticalMargin = 5.0;
const double _kMargin = 16.0;
const double _kBoxRadius = 4.0;

final TextStyle _kInfoStyle = new TextStyle(
  color: Colors.grey[600],
  fontStyle: FontStyle.italic,
);

const TextStyle _kCodeStyle = const TextStyle(
  fontFamily: 'monospace',
  fontWeight: FontWeight.bold,
);

/// A function type to be used as setState() function.
typedef SetStateFunc = void Function(VoidCallback fn);

/// A class containing all the generated state values and widget builders.
///
/// The concrete implementations of this class should be provided by the
/// `gen_widget_specs` tool.
abstract class GeneratedState {
  /// The `setState` function provided by the [WidgetExplorerWrapperState].
  final SetStateFunc setState;

  /// Creates a new instance of [GeneratedState] object with the given
  /// [setState] function.
  GeneratedState(this.setState);

  /// Initialize all the parameter values.
  void initState(Map<String, dynamic> config);

  /// Builds the target widget with the current values.
  Widget buildWidget(
    BuildContext context,
    Key key,
    double width,
    double height,
  );

  /// Builds the [TableRow]s, each of which represents a parameter description
  /// and its controller widgets.
  List<TableRow> buildParameterTableRows(BuildContext context);
}

/// Builder function for the [GeneratedState].
typedef GeneratedStateBuilder = GeneratedState Function(SetStateFunc setState);

/// A widget that wraps the target widget and its size control panel.
class WidgetExplorerWrapper extends StatefulWidget {
  /// Configuration map.
  final Map<String, dynamic> config;

  /// Current width value.
  final double width;

  /// Current height value.
  final double height;

  /// The state builder provided for the target widget.
  final GeneratedStateBuilder stateBuilder;

  /// Creates a new instance of [WidgetExplorerWrapper].
  const WidgetExplorerWrapper({
    @required this.config,
    @required this.width,
    @required this.height,
    @required this.stateBuilder,
    Key key,
  }) : super(key: key);

  @override
  WidgetExplorerWrapperState createState() => new WidgetExplorerWrapperState();
}

/// The [State] class for the [WidgetExplorerWrapper].
///
/// The most important states are in fact stored in the [genState] field.
class WidgetExplorerWrapperState extends State<WidgetExplorerWrapper> {
  /// A [UniqueKey] to be used for the target widget.
  Key uniqueKey = new UniqueKey();

  /// An internal, generated state object that manages widget-specific states.
  GeneratedState genState;

  @override
  void initState() {
    super.initState();

    genState = widget.stateBuilder((VoidCallback fn) {
      setState(() {
        fn?.call();
        _updateKey();
      });
    })
      ..initState(widget.config);
  }

  @override
  Widget build(BuildContext context) {
    Widget targetWidget;
    try {
      targetWidget = genState.buildWidget(
        context,
        uniqueKey,
        widget.width,
        widget.height,
      );
    } on Exception catch (e) {
      targetWidget = new Text('Failed to build the widget.\n'
          'See the error message below:\n\n'
          '$e');
    }

    return new ListBody(
      children: <Widget>[
        new Container(
          decoration: new BoxDecoration(
            border: new Border.all(color: Colors.grey[500]),
            borderRadius:
                const BorderRadius.all(const Radius.circular(_kBoxRadius)),
          ),
          margin: const EdgeInsets.all(_kMargin),
          child: new Container(
            child: new Container(
              margin: const EdgeInsets.all(_kMargin),
              child: new ListBody(
                children: <Widget>[
                  const Text(
                    'Parameters',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  new Table(
                    children: genState.buildParameterTableRows(context),
                    columnWidths: const <int, TableColumnWidth>{
                      0: const IntrinsicColumnWidth(),
                      1: const FixedColumnWidth(_kMargin),
                      2: const IntrinsicColumnWidth(),
                      3: const FixedColumnWidth(_kMargin),
                      4: const FlexColumnWidth(1.0),
                    },
                    defaultVerticalAlignment: TableCellVerticalAlignment.middle,
                  ),
                ],
              ),
            ),
          ),
        ),
        new Container(
          decoration: new BoxDecoration(
            border: new Border.all(color: Colors.grey[500]),
            borderRadius:
                const BorderRadius.all(const Radius.circular(_kBoxRadius)),
          ),
          margin: const EdgeInsets.all(_kMargin),
          child: new Container(
            margin: const EdgeInsets.all(_kMargin),
            child: new Row(
              children: <Widget>[
                new Container(
                  width: widget.width,
                  height: widget.height,
                  child: targetWidget,
                ),
                new Expanded(child: new Container()),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _updateKey() {
    uniqueKey = new UniqueKey();
  }
}

/// Wrapper widget which gives some top margin to a given child.
class _TopMargined extends StatelessWidget {
  const _TopMargined({
    @required this.child,
    Key key,
  }) : super(key: key);

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return new Container(
      margin: const EdgeInsets.symmetric(vertical: _kTableRowVerticalMargin),
      child: child,
    );
  }
}

/// Builds a [TableRow] representing a parameter for a widget.
TableRow buildTableRow(BuildContext context, List<Widget> children) {
  assert(context != null);
  assert(children.length == 3);

  return new TableRow(
    children: <Widget>[
      new _TopMargined(
        child: DefaultTextStyle.merge(
          style: _kCodeStyle,
          child: children[0],
        ),
      ),
      new Container(), // Empty column
      new _TopMargined(
        child: DefaultTextStyle.merge(
          style: _kCodeStyle,
          child: children[1],
        ),
      ),
      new Container(), // Empty column
      new _TopMargined(
        child: children[2],
      )
    ],
  );
}

/// Regenerate button.
class RegenerateButton extends StatelessWidget {
  /// A callback function to be called when this button is pressed.
  final VoidCallback onPressed;

  /// A code snippet to display along with the button.
  final String codeToDisplay;

  /// Creates a new instance of [RegenerateButton].
  const RegenerateButton({
    @required this.onPressed,
    Key key,
    this.codeToDisplay,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    String text =
        codeToDisplay != null ? 'Regenerate ($codeToDisplay)' : 'Regenerate';
    return new Row(
      children: <Widget>[
        new RaisedButton(
          onPressed: onPressed,
          child: new Text(text),
        ),
        new Expanded(child: new Container()),
      ],
    );
  }
}

/// A text widget for information displayed in the parameter tuning panel.
class InfoText extends StatelessWidget {
  /// Text to display.
  final String text;

  /// Creates a new instance of [InfoText].
  const InfoText(this.text, {Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) => new Text(
        text,
        key: key,
        style: _kInfoStyle,
      );
}

/// A widget indicating whether a config value has been successfully retrieved.
class ConfigKeyText extends StatelessWidget {
  /// The key name of the config value specified in the `@ConfigKey` annotation.
  final String configKey;

  /// The value associated with the key.
  final String configValue;

  /// Creates a new instance of [ConfigKeyText].
  const ConfigKeyText({
    @required this.configKey,
    @required this.configValue,
    Key key,
  })  : assert(configKey != null),
        super(key: key);

  @override
  Widget build(BuildContext context) {
    if (configValue == null) {
      return new InfoText(
        "WARNING: Could not find the '$configKey' value "
            'from the config.json file.',
      );
    }

    return new InfoText(
      "'$configKey' value retrieved from the config.json file.",
    );
  }
}

/// A helper widget for text input, which can take an initial value string.
class TextFieldWithInitialValue extends StatefulWidget {
  /// Initial text value to be used (can be null).
  final String initialValue;

  /// Keyboard type.
  final TextInputType keyboardType;

  /// Callback for when the text value changes.
  final ValueChanged<String> onChanged;

  /// Callback for when the current text is submitted.
  final ValueChanged<String> onSubmitted;

  /// Creates a new instance of [TextFieldWithInitialValue].
  const TextFieldWithInitialValue({
    // ignore: avoid_unused_constructor_parameters
    Key key,
    this.initialValue,
    this.keyboardType,
    this.onChanged,
    this.onSubmitted,
  });

  @override
  _TextFieldWithInitialValueState createState() =>
      new _TextFieldWithInitialValueState();
}

class _TextFieldWithInitialValueState extends State<TextFieldWithInitialValue> {
  TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = new TextEditingController(text: widget.initialValue ?? '');
  }

  @override
  Widget build(BuildContext context) {
    return new TextField(
      controller: _controller,
      decoration: const InputDecoration(isDense: true),
      keyboardType: widget.keyboardType,
      onChanged: widget.onChanged,
      onSubmitted: widget.onSubmitted,
    );
  }
}
