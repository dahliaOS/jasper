// Copyright 2017 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';
import 'dart:io';

import 'package:apps.modular.services.story/story_provider.fidl.dart';
import 'package:flutter/services.dart';

const String _kJsonUrl =
    'packages/armadillo/res/initial_story_generator_config.json';

/// Creates the initial list of stories to be shown when no stories exist.
class InitialStoryGenerator {
  bool _loaded = false;
  bool _storyCreationPending = false;
  StoryProviderProxy _storyProvider;
  List<Map<String, String>> _decodedJson;

  /// Loads the initial stories to generate from the [_kJsonUrl] JSON file in
  /// [assetBundle].
  void load(AssetBundle assetBundle) {
    File configFile = new File(
      '/system/armadillo_initial_story_generator_config.json',
    );
    configFile.exists().then((bool exists) {
      if (exists) {
        print('reading from config file!');
        configFile.readAsString().then(_parseJson);
      } else {
        print('reading from asset bundle!');
        assetBundle.loadString(_kJsonUrl).then(_parseJson);
      }
    });
  }

  void _parseJson(String json) {
    _decodedJson = json.decode(json);

    _loaded = true;
    if (_storyCreationPending) {
      createStories(_storyProvider);
    }
  }

  /// Creates the initial stories with [storyProvider].
  void createStories(StoryProviderProxy storyProvider) {
    if (!_loaded) {
      _storyCreationPending = true;
      _storyProvider = storyProvider;
      return;
    }

    _decodedJson.forEach((Map<String, String> entry) {
      storyProvider.createStoryWithInfo(
        entry['url'],
        <String, String>{'color': entry['color']},
        JSON.encode(entry['rootJson'] ?? null),
        (String storyId) => null,
      );
    });
  }
}
