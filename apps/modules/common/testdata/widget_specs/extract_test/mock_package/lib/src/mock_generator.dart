// Copyright 2017 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'mock_models.dart';

class MockGenerator {
  MockGenerator();

  static ModelFoo foo() => new ModelFoo(fooValue: 'fooValue');

  ModelFoo foo2() => new ModelFoo(fooValue: 'fooValue2');

  ModelBar bar() => new ModelBar(barValue: 'barValue');

  ModelBaz baz() => new ModelBaz(bazValue: 'bazValue');
}
