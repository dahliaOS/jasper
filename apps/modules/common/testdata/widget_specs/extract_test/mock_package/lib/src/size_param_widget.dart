// Copyright 2017 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:widgets_meta/widgets_meta.dart';

/// Sample widget for demonstrating the use of @sizeParam annotation.
class SizeParamWidget extends StatelessWidget {
  final double size;

  SizeParamWidget({
    Key key,
    @sizeParam double size,
  })
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return new Container();
  }
}
