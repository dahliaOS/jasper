// Copyright 2017 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:widgets_meta/widgets_meta.dart';

import 'extras/mock_models.dart';
import 'mock_generator.dart';
import 'mock_models.dart';

/// Sample widget for demonstrating the use of model classes annotated with
/// @Generator annotation.
class GeneratorWidget extends StatelessWidget {
  final ModelFoo foo;
  final ModelFoo foo2;
  final ModelBar bar;
  final ModelBaz baz;
  final ModelQux qux;

  GeneratorWidget({
    Key key,
    this.foo,
    // The @Generator annotation on this parameter should take precedence over
    // the one specified on the ModelFoo class.
    @Generator(MockGenerator, 'foo2') this.foo2,
    this.bar,
    @Generator(MockGenerator, 'baz') this.baz,
    this.qux,
  })
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return new Container();
  }
}
