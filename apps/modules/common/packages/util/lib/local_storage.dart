// Copyright 2016 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert' show JSON;
import 'dart:io';

import 'package:flutter/services.dart';

const String _dataFileName = 'storage.json';

/// The default [LocalStorage] instance that other packages can import and use.
const LocalStorage localStorage = const LocalStorage(_dataFileName);

/// A class for locally persist data on device. This class can store any string
/// key-value pairs and retrieve them later. The current implementation is not
/// particularly efficient, and this is intended.
class LocalStorage {
  /// The file name to be used for the local storage instance.
  final String dataFileName;

  /// Create a new local storage instance with the given file name.
  const LocalStorage(this.dataFileName);

  /// Gets the value for the given [key].
  Future<String> get(String key) async {
    _Store store = await _load();
    return store[key];
  }

  /// Associates the given [value] with the given [key].
  Future<Null> put(String key, String value) async {
    _Store store = await _load();
    store[key] = value;
    await store.save();
  }

  /// Deletes the given [key] and its associated value.
  Future<Null> remove(String key) async {
    _Store store = await _load();
    store.remove(key);
    await store.save();
  }

  /// Creates and initialize the store.
  Future<_Store> _load() async {
    File file = new File(await _getFilePath());

    _Store store = new _Store(file);
    await store.init();

    return store;
  }

  /// Gets the full path of the data file.
  Future<String> _getFilePath() async {
    String dir = (await PathProvider.getApplicationDocumentsDirectory()).path;
    return '$dir/$dataFileName';
  }
}

class _Store {
  final File file;
  final Map<String, dynamic> _map = <String, dynamic>{};

  _Store(this.file);

  /// This [init] method must be called once before being used.
  Future<Null> init() async {
    if (!(await file.exists())) {
      return;
    }

    String data = await file.readAsString();
    dynamic dataMap = json.decode(data);
    dataMap.forEach((String k, String v) {
      _map[k] = v;
    });
  }

  Future<Null> save() async {
    await file.writeAsString(JSON.encode(_map));
  }

  void remove(String key) {
    _map.remove(key);
  }

  String operator [](String key) => _map[key];

  void operator []=(String key, String value) {
    _map[key] = value;
  }
}
