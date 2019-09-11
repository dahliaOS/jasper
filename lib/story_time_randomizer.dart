// Copyright 2016 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/widgets.dart';

import 'story_model.dart';

/// Adds a button to randomize story times.
class StoryTimeRandomizer extends StatelessWidget {
  /// The model whose stories will have their times randomized.
  final StoryModel storyModel;

  /// The child the button overlays.
  final Widget child;

  /// Constructor.
  StoryTimeRandomizer({this.storyModel, this.child});

  @override
  Widget build(BuildContext context) => new Stack(
        fit: StackFit.passthrough,
        children: <Widget>[
          child,
          new Positioned(
            left: 0.0,
            top: 0.0,
            width: 50.0,
            height: 50.0,
            child: new GestureDetector(
              behavior: HitTestBehavior.translucent,
              onTap: storyModel.randomizeStoryTimes,
            ),
          ),
        ],
      );
}
