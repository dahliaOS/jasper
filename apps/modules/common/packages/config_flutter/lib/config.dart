// Copyright 2016 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert';

import 'package:config/config.dart';
import 'package:flutter/services.dart' show rootBundle;

/// Config implementation for flutter environment.
class FlutterConfig extends Config {
  /// Convienence method for creating a config object by loading a
  /// configuration file at [src].
  static Future<Config> read(String src) async {
    FlutterConfig config = new FlutterConfig();
    await config.load(src);
    return config;
  }

  @override
  Future<Null> load(String src) async {
    String data;

    try {
      data = await rootBundle.loadString(src);
    } catch (err) {
      throw new StateError('error loading "$src"');
    }

    dynamic json = json.decode(data);
    json.forEach((String key, String value) => this.put(key, value));
  }
}
