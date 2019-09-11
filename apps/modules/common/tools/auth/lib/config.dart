// Copyright 2016 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:config/config.dart';

/// Configuration interface for CLI tools.
class ToolsConfig extends Config {
  /// The file for reading and saving configuration values.
  File file;

  /// Convienence method for creating a config object by loading a
  /// configuration file at [src].
  static Future<ToolsConfig> read(String src) async {
    ToolsConfig config = new ToolsConfig();
    await config.load(src);
    return config;
  }

  @override
  Future<Null> load(String filename) async {
    this.file = new File(filename);

    if (!(await file.exists())) {
      throw new StateError('''
Config file does not exist:

    $file
      ''');
    }

    String data = await file.readAsString();
    dynamic json = json.decode(data);
    json.forEach((String key, String value) => this.put(key, value));
  }

  /// Save the current configuration values to [this.file].
  Future<Null> save() async {
    JsonEncoder encoder = new JsonEncoder.withIndent('  ');
    Map<String, dynamic> json = this.toJSON();
    String data = encoder.convert(json);
    await this.file.writeAsString(data);
  }
}
