// Copyright 2017 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:widget_explorer_meta/widgets_meta.dart';

import 'mock_generator.dart';

@Generator(MockGenerator, 'foo')
class ModelFoo {
  final String fooValue;

  ModelFoo({this.fooValue});
}

@Generator(MockGenerator, 'bar')
class ModelBar {
  final String barValue;

  ModelBar({this.barValue});
}

class ModelBaz {
  final String bazValue;

  ModelBaz({this.bazValue});
}
