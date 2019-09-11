// Copyright 2016 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:meta/meta.dart';
import 'package:widgets_meta/widgets_meta.dart';

import 'example_video_id.dart';

/// Callback function signature for selecting a Youtube video
typedef void YoutubeSelectCallback(String videoId);

/// [YoutubeThumbnail] is a [StatelessWidget]
///
/// Widget that shows a static Youtube thumbnail given a video id
/// The thumbnail will stretch to fit its parent widget
class YoutubeThumbnail extends StatelessWidget {
  /// ID for given youtube video
  final String videoId;

  /// Callback if thumbnail video is selected
  final YoutubeSelectCallback onSelect;

  /// Constructor
  YoutubeThumbnail({
    Key key,
    @required @ExampleValue(kExampleVideoId) this.videoId,
    this.onSelect,
  })
      : super(key: key) {
    assert(videoId != null);
  }

  void _handleSelect() {
    onSelect?.call(videoId);
  }

  /// Retrieves Youtube thumbnail from the video ID
  String _getYoutubeThumbnailUrl() {
    return 'http://img.youtube.com/vi/$videoId/0.jpg';
  }

  @override
  Widget build(BuildContext context) {
    return new Material(
      color: Colors.white,
      child: new InkWell(
        onTap: _handleSelect,
        child: new Image.network(
          _getYoutubeThumbnailUrl(),
          fit: BoxFit.cover,
        ),
      ),
    );
  }
}
