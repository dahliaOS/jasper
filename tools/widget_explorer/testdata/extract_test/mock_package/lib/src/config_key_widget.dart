// Copyright 2017 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:widget_explorer_meta/widgets_meta.dart';

/// Sample widget for demonstrating the use of @ConfigKey annotation.
class ConfigKeyWidget extends StatelessWidget {
  final String apiKey;

  ConfigKeyWidget({
    Key key,
    @ConfigKey('api_key') this.apiKey,
  })
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return new Container();
  }
}
