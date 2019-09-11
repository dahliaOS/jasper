// Copyright 2016 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/widgets.dart';

import 'story_cluster.dart';
import 'story_list.dart';

/// Generates [StoryCluster]s for the [StoryList].
abstract class StoryGenerator {
  /// [listener] will be called when [storyClusters] changes.
  void addListener(VoidCallback listener);

  /// [listener] will no longer be called when [storyClusters] changes.
  void removeListener(VoidCallback listener);

  /// The list of [StoryCluster]s.
  List<StoryCluster> get storyClusters;
}
