// Copyright 2017 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// THIS IS A GENERATED FILE. DO NOT MODIFY MANUALLY.

import 'package:flutter/material.dart';
import 'package:widget_explorer_core/widget_specs.dart';
import 'package:widget_explorer_widgets/widget_explorer_widgets.dart';
import 'package:mock_package/exported.dart';

import 'package:mock_package/src/extras/mock_models.dart' as mock_models2;
import 'package:mock_package/src/mock_generator.dart' as mock_generator;
import 'package:mock_package/src/mock_models.dart' as mock_models;

/// Name of the widget.
const String kName = 'GeneratorWidget';

/// [WidgetSpecs] of this widget.
final WidgetSpecs kSpecs = new WidgetSpecs(
  packageName: 'mock_package',
  name: 'GeneratorWidget',
  path: 'exported.dart',
  pathFromFuchsiaRoot:
      'apps/modules/common/testdata/widget_specs/extract_test/mock_package/lib/src/generator_widget.dart',
  doc: '''
Sample widget for demonstrating the use of model classes annotated with
@Generator annotation.''',
  exampleWidth: null,
  exampleHeight: null,
  hasSizeParam: false,
);

/// Generated state object for this widget.
class _GeneratedGeneratorWidgetState extends GeneratedState {
  mock_models.ModelFoo foo;
  mock_models.ModelFoo foo2;
  mock_models.ModelBar bar;
  mock_models.ModelBaz baz;
  mock_models2.ModelQux qux;
  mock_generator.MockGenerator mockGenerator =
      new mock_generator.MockGenerator();

  _GeneratedGeneratorWidgetState(SetStateFunc setState) : super(setState);

  @override
  void initState(Map<String, dynamic> config) {
    foo = mockGenerator.foo();
    foo2 = mockGenerator.foo2();
    bar = mockGenerator.bar();
    baz = mockGenerator.baz();
    qux = null;
  }

  @override
  Widget buildWidget(
    BuildContext context,
    Key key,
    double width,
    double height,
  ) {
    return new GeneratorWidget(
      key: key,
      foo: this.foo,
      foo2: this.foo2,
      bar: this.bar,
      baz: this.baz,
      qux: this.qux,
    );
  }

  @override
  List<TableRow> buildParameterTableRows(BuildContext context) {
    return <TableRow>[
      buildTableRow(
        context,
        <Widget>[
          new Text('ModelFoo'),
          new Text('foo'),
          new RegenerateButton(
            onPressed: () {
              setState(() {
                foo = mockGenerator.foo();
              });
            },
            codeToDisplay: 'mockGenerator.foo()',
          ),
        ],
      ),
      buildTableRow(
        context,
        <Widget>[
          new Text('ModelFoo'),
          new Text('foo2'),
          new RegenerateButton(
            onPressed: () {
              setState(() {
                foo2 = mockGenerator.foo2();
              });
            },
            codeToDisplay: 'mockGenerator.foo2()',
          ),
        ],
      ),
      buildTableRow(
        context,
        <Widget>[
          new Text('ModelBar'),
          new Text('bar'),
          new RegenerateButton(
            onPressed: () {
              setState(() {
                bar = mockGenerator.bar();
              });
            },
            codeToDisplay: 'mockGenerator.bar()',
          ),
        ],
      ),
      buildTableRow(
        context,
        <Widget>[
          new Text('ModelBaz'),
          new Text('baz'),
          new RegenerateButton(
            onPressed: () {
              setState(() {
                baz = mockGenerator.baz();
              });
            },
            codeToDisplay: 'mockGenerator.baz()',
          ),
        ],
      ),
      buildTableRow(
        context,
        <Widget>[
          new Text('ModelQux'),
          new Text('qux'),
          new InfoText('null (this type of parameter is not supported yet)'),
        ],
      ),
    ];
  }
}

/// State builder for this widget.
final GeneratedStateBuilder kBuilder =
    (SetStateFunc setState) => new _GeneratedGeneratorWidgetState(setState);
