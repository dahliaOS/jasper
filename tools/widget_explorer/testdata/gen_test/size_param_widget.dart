// Copyright 2017 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// THIS IS A GENERATED FILE. DO NOT MODIFY MANUALLY.

import 'package:flutter/material.dart';
import 'package:widget_explorer_core/widget_specs.dart';
import 'package:widget_explorer_widgets/widget_explorer_widgets.dart';
import 'package:mock_package/exported.dart';

/// Name of the widget.
const String kName = 'SizeParamWidget';

/// [WidgetSpecs] of this widget.
final WidgetSpecs kSpecs = new WidgetSpecs(
  packageName: 'mock_package',
  name: 'SizeParamWidget',
  path: 'exported.dart',
  pathFromFuchsiaRoot:
      'topaz/tools/widget_explorer/testdata/extract_test/mock_package/lib/src/size_param_widget.dart',
  doc: '''
Sample widget for demonstrating the use of @sizeParam annotation.''',
  exampleWidth: null,
  exampleHeight: null,
  hasSizeParam: true,
);

/// Generated state object for this widget.
class _GeneratedSizeParamWidgetState extends GeneratedState {
  double size;

  _GeneratedSizeParamWidgetState(SetStateFunc setState) : super(setState);

  @override
  void initState(Map<String, dynamic> config) {
    size = 0.0;
  }

  @override
  Widget buildWidget(
    BuildContext context,
    Key key,
    double width,
    double height,
  ) {
    return new SizeParamWidget(
      key: key,
      size: width,
    );
  }

  @override
  List<TableRow> buildParameterTableRows(BuildContext context) {
    return <TableRow>[
      buildTableRow(
        context,
        <Widget>[
          new Text('double'),
          new Text('size'),
          new InfoText('size value is used'),
        ],
      ),
    ];
  }
}

/// State builder for this widget.
final GeneratedStateBuilder kBuilder =
    (SetStateFunc setState) => new _GeneratedSizeParamWidgetState(setState);
