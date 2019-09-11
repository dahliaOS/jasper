// Copyright 2017 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/widgets.dart';
import 'package:widget_explorer_meta/widgets_meta.dart';

/// This is a public [StatefulWidget].
@ExampleSize(200.0, 300.0)
class Widget01 extends StatefulWidget {
  /// An example [int] parameter for testing code generation.
  final int intParam;

  /// An example [bool] parameter for testing code generation.
  final bool boolParam;

  /// An example [double] parameter for testing code generation.
  final double doubleParam;

  /// An example [String] parameter for testing code generation.
  final String stringParam;

  /// An example parameter without a provided example value.
  final dynamic noExampleValueParam;

  Widget01({
    Key key,
    @ExampleValue(42) this.intParam,
    @ExampleValue(true) this.boolParam,
    @ExampleValue(10.0) this.doubleParam,
    @ExampleValue('example string value!') this.stringParam,
    this.noExampleValueParam,
  }) : super(key: key);
}

/// This is a private [StatefulWidget].
class _Widget02 extends StatefulWidget {}

/// A callback function with no parameters.
typedef CallbackWithNoParams = void Function();

/// A callback function with two parameters.
typedef CallbackWithParams = void Function(int foo, String bar);

/// This is a public [StatelessWidget].
class Widget03 extends StatelessWidget {
  /// An example callback function with no parameters.
  final CallbackWithNoParams callbackWithNoParams;

  /// An example callback function with parameters;
  final CallbackWithParams callbackWithParams;

  /// Creates a new instance of [Widget03].
  Widget03({
    Key key,
    this.callbackWithNoParams,
    this.callbackWithParams,
  }) : super(key: key);
}

/// This is a private [StatelessWidget].
class _Widget04 extends StatelessWidget {}

/// This is the [State] class for [Widget01].
class Widget01State extends State<Widget01> {}

class NoCommentWidget extends StatelessWidget {}
