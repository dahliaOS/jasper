// Copyright 2017 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'story_cluster.dart';

/// The display mode of a [StoryCluster].
enum DisplayMode {
  /// [tabs] indicates the stories of the [StoryCluster] should be displayed one
  /// at a time in seperate tabs.
  tabs,

  /// [panels] indicates the stories of the [StoryCluster] should be displayed
  /// together on screen in separate panels.
  panels
}
