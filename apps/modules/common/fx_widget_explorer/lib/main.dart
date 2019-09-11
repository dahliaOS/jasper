// Copyright 2016 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:config_flutter/config.dart';
import 'package:flutter/material.dart';

import 'app.dart';
import 'embedded_child_builders.dart';

Future<Null> main() async {
  FlutterConfig config = await FlutterConfig.read('assets/config.json');
  addEmbeddedChildBuilders(config);
  runApp(new App(config: config));
}
