// Copyright 2017 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// THIS IS A GENERATED FILE. DO NOT MODIFY MANUALLY.

import 'package:flutter/material.dart';
import 'package:widget_explorer_core/widget_specs.dart';
import 'package:widget_explorer_widgets/widget_explorer_widgets.dart';
import 'package:mock_package/exported.dart';

import 'package:mock_package/src/sample_widgets.dart' as sample_widgets;

/// Name of the widget.
const String kName = 'Widget03';

/// [WidgetSpecs] of this widget.
final WidgetSpecs kSpecs = new WidgetSpecs(
  packageName: 'mock_package',
  name: 'Widget03',
  path: 'exported.dart',
  pathFromFuchsiaRoot:
      'apps/modules/common/testdata/widget_specs/extract_test/mock_package/lib/src/sample_widgets.dart',
  doc: '''
This is a public [StatelessWidget].''',
  exampleWidth: null,
  exampleHeight: null,
  hasSizeParam: false,
);

/// Generated state object for this widget.
class _GeneratedWidget03State extends GeneratedState {
  sample_widgets.CallbackWithNoParams callbackWithNoParams;
  sample_widgets.CallbackWithParams callbackWithParams;

  _GeneratedWidget03State(SetStateFunc setState) : super(setState);

  @override
  void initState(Map<String, dynamic> config) {
    callbackWithNoParams = () => print('Widget03.callbackWithNoParams called');
    callbackWithParams = (dynamic foo, dynamic bar) => print(
        'Widget03.callbackWithParams called with parameters: ${<dynamic>[foo, bar]}');
  }

  @override
  Widget buildWidget(
    BuildContext context,
    Key key,
    double width,
    double height,
  ) {
    return new Widget03(
      key: key,
      callbackWithNoParams: this.callbackWithNoParams,
      callbackWithParams: this.callbackWithParams,
    );
  }

  @override
  List<TableRow> buildParameterTableRows(BuildContext context) {
    return <TableRow>[
      buildTableRow(
        context,
        <Widget>[
          new Text('CallbackWithNoParams'),
          new Text('callbackWithNoParams'),
          new InfoText('Default implementation'),
        ],
      ),
      buildTableRow(
        context,
        <Widget>[
          new Text('CallbackWithParams'),
          new Text('callbackWithParams'),
          new InfoText('Default implementation'),
        ],
      ),
    ];
  }
}

/// State builder for this widget.
final GeneratedStateBuilder kBuilder =
    (SetStateFunc setState) => new _GeneratedWidget03State(setState);
