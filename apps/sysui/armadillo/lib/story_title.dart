// Copyright 2016 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

/// The title of a story.
class StoryTitle extends StatelessWidget {
  /// The text for the title.
  final String title;

  /// The opacity for this [Widget].
  final double opacity;

  /// The font color to use.  This color's alpha will be modified.
  final Color baseColor;

  /// Constructor.
  StoryTitle({this.title, this.opacity: 1.0, this.baseColor: Colors.white});

  @override
  Widget build(BuildContext context) => new Opacity(
        opacity: opacity,
        child: new Text(
          title,
          style: new TextStyle(
            fontSize: 11.0,
            color: baseColor.withAlpha(160),
            fontWeight: FontWeight.w500,
            letterSpacing: 1.2,
          ),
          softWrap: false,
          overflow: TextOverflow.ellipsis,
        ),
      );
}
