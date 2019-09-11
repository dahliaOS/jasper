// Copyright 2016 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:io';

/// Abstract class providing a basic configuration to be implemented in both
/// Flutter and CLI/tooling environements.
class Config {
  /// OAuth Scopes.
  /// SEE: https://developers.google.com/identity/protocols/googlescopes
  List<String> scopes = <String>[
    'https://www.googleapis.com/auth/gmail.modify',
    'https://www.googleapis.com/auth/userinfo.email',
    'https://www.googleapis.com/auth/userinfo.profile',
    'https://www.googleapis.com/auth/youtube.readonly',
    'https://www.googleapis.com/auth/contacts',
    'https://www.googleapis.com/auth/plus.login',
    'https://www.googleapis.com/auth/firebase.database',
  ];

  final Map<String, dynamic> _data = <String, dynamic>{};

  /// Convienence method for creating a config object by loading a
  /// configuration file at [src].
  static Future<Config> read(String src) async {
    Config config = new Config();
    await config.load(src);
    return config;
  }

  /// Load configuration from the filesystem.
  Future<Null> load(String src) async {
    File file = new File(src);

    String data;
    dynamic json;

    try {
      data = await file.readAsString();
    } catch (err) {
      String message = 'unable to read file "$src"';
      throw new StateError(message);
    }

    try {
      json = json.decode(data);
    } catch (err) {
      String message = 'unable to decode JSON \n$data';
      throw new StateError(message);
    }

    json.forEach((String key, String value) => this.put(key, value));
  }

  /// Check is the configuration has a value for [key].
  bool has(String key) {
    return _data.containsKey(key);
  }

  /// Retrieve a config value.
  String get(String key) {
    return _data[key];
  }

  /// Add or update a config value.
  void put(String key, String value) {
    _data[key] = value;
  }

  /// Validates the config against [keys]. Will throw an infomrative
  /// [StateError] if any of the given keys are missing.
  void validate(List<String> keys) {
    bool isValid = true;
    List<String> message = <String>[
      'Config is missing one or more required keys:',
      '',
    ];

    keys.forEach((String key) {
      if (!has(key) || get(key) == null) {
        isValid = false;
        message.add('* $key');
      }
    });

    message.add('');

    if (!isValid) {
      throw new StateError(message.join('\n'));
    }
  }

  /// Create a [Map] for use in JSON encoding.
  Map<String, dynamic> toJSON() {
    return _data;
  }
}
