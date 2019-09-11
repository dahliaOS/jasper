// Copyright 2017 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

/// Central place to start new adventures.
class Launcher extends StatelessWidget {
  @override
  Widget build(BuildContext context) => new Container(
      width: 500.0,
      height: 300.0,
      decoration: const BoxDecoration(
        color: Colors.white,
      ),
      child: new Center(
        child: new Text(
          "I provide options",
          style: const TextStyle(
            color: Colors.black,
          ),
        ),
      ));
}
