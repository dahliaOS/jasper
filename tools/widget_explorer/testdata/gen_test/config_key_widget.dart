// Copyright 2017 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// THIS IS A GENERATED FILE. DO NOT MODIFY MANUALLY.

import 'package:flutter/material.dart';
import 'package:widget_explorer_core/widget_specs.dart';
import 'package:widget_explorer_widgets/widget_explorer_widgets.dart';
import 'package:mock_package/exported.dart';

/// Name of the widget.
const String kName = 'ConfigKeyWidget';

/// [WidgetSpecs] of this widget.
final WidgetSpecs kSpecs = new WidgetSpecs(
  packageName: 'mock_package',
  name: 'ConfigKeyWidget',
  path: 'exported.dart',
  pathFromFuchsiaRoot:
      'topaz/tools/widget_explorer/testdata/extract_test/mock_package/lib/src/config_key_widget.dart',
  doc: '''
Sample widget for demonstrating the use of @ConfigKey annotation.''',
  exampleWidth: null,
  exampleHeight: null,
  hasSizeParam: false,
);

/// Generated state object for this widget.
class _GeneratedConfigKeyWidgetState extends GeneratedState {
  String apiKey;

  _GeneratedConfigKeyWidgetState(SetStateFunc setState) : super(setState);

  @override
  void initState(Map<String, dynamic> config) {
    apiKey = config['api_key'];
  }

  @override
  Widget buildWidget(
    BuildContext context,
    Key key,
    double width,
    double height,
  ) {
    return new ConfigKeyWidget(
      key: key,
      apiKey: this.apiKey,
    );
  }

  @override
  List<TableRow> buildParameterTableRows(BuildContext context) {
    return <TableRow>[
      buildTableRow(
        context,
        <Widget>[
          new Text('String'),
          new Text('apiKey'),
          new ConfigKeyText(
            configKey: 'api_key',
            configValue: apiKey,
          ),
        ],
      ),
    ];
  }
}

/// State builder for this widget.
final GeneratedStateBuilder kBuilder =
    (SetStateFunc setState) => new _GeneratedConfigKeyWidgetState(setState);
