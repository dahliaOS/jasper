// Copyright 2016 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:meta/meta.dart';
import 'package:widgets_meta/widgets_meta.dart';

import 'youtube_comments_list.dart';
import 'youtube_player.dart';
import 'youtube_video_overview.dart';

/// UI Widget that represents a single Youtube "Video View"
/// Includes:
/// 1. Video Player
/// 2. Video Overview
/// 3. Video Comments
class YoutubeVideo extends StatelessWidget {
  /// ID for given youtube video
  final String videoId;

  /// Youtube API key needed to access the Youtube Public APIs
  final String apiKey;

  /// Constructor
  YoutubeVideo({
    Key key,
    @required @ExampleValue('a6KGPBflhiM') this.videoId,
    @required @ConfigKey('google_api_key') this.apiKey,
  })
      : super(key: key) {
    assert(videoId != null);
    assert(apiKey != null);
  }

  @override
  Widget build(BuildContext context) {
    return new ListView(
      children: <Widget>[
        new YoutubePlayer(
          videoId: videoId,
          apiKey: apiKey,
        ),
        new YoutubeVideoOverview(
          videoId: videoId,
          apiKey: apiKey,
        ),
        new YoutubeCommentsList(
          videoId: videoId,
          apiKey: apiKey,
        ),
      ],
    );
  }
}
