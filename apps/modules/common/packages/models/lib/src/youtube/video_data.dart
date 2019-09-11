// Copyright 2016 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:util/parse_int.dart';

/// Represents Video Data from a single Youtube video
class VideoData {
  /// ID of video
  final String id;

  /// Title of video
  final String title;

  /// Description of video
  final String description;

  /// Title of channel that published the video
  final String channelTitle;

  /// Time when video was published
  final DateTime publishedAt;

  /// Number of times the video has been viewed
  final int viewCount;

  /// Number of times the video has been liked
  final int likeCount;

  /// Number of times the video has been disliked
  final int dislikeCount;

  /// Constructor
  VideoData({
    this.id,
    this.title,
    this.description,
    this.channelTitle,
    this.publishedAt,
    this.viewCount,
    this.likeCount,
    this.dislikeCount,
  });

  /// Constructs [VideoData] model from Youtube api json data
  factory VideoData.fromJson(dynamic json) {
    // Check for ID and Snippet
    assert(json['id'] != null);
    assert(json['id'] is String ||
        json['id'] is Map && json['id']['videoId'] is String);
    assert(json['snippet'] != null);

    int viewCount;
    int likeCount;
    int dislikeCount;

    final dynamic stats = json['statistics'];
    if (stats is Map) {
      viewCount = parseInt(stats['viewCount']);
      likeCount = parseInt(stats['likeCount']);
      dislikeCount = parseInt(stats['dislikeCount']);
    }

    return new VideoData(
      id: json['id'] is String ? json['id'] : json['id']['videoId'],
      title: json['snippet']['title'],
      description: json['snippet']['description'],
      publishedAt: DateTime.parse(json['snippet']['publishedAt']),
      channelTitle: json['snippet']['channelTitle'],
      viewCount: viewCount,
      likeCount: likeCount,
      dislikeCount: dislikeCount,
    );
  }
}
