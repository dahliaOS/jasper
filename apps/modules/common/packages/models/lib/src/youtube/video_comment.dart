// Copyright 2016 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

/// Represents a comment on a Youtube video
class VideoComment {
  /// Display name of comment author
  final String authorDisplayName;

  /// URL of author profile image/avatar
  final String authorProfileImageUrl;

  /// Text of comment
  final String text;

  /// Number of likes given to comment
  final int likeCount;

  /// Number of total replies given to comment
  final int totalReplyCount;

  /// Constructor
  VideoComment({
    this.authorDisplayName,
    this.authorProfileImageUrl,
    this.text,
    this.likeCount,
    this.totalReplyCount,
  });

  /// Constructs [VideoComment] model from Youtube api json data
  factory VideoComment.fromJson(dynamic json) {
    dynamic topLevelSnippet = json['snippet']['topLevelComment']['snippet'];
    return new VideoComment(
      authorDisplayName: topLevelSnippet['authorDisplayName'],
      authorProfileImageUrl: topLevelSnippet['authorProfileImageUrl'],
      text: topLevelSnippet['textDisplay'],
      likeCount: topLevelSnippet['likeCount'],
      totalReplyCount: json['snippet']['totalReplyCount'],
    );
  }
}
