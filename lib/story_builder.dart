// Copyright 2016 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

import 'default_scroll_configuration.dart';
import 'story.dart';

Widget _widgetBuilder(String module, Map<String, Object> state) {
  switch (module) {
    case 'image':
      return new LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) =>
            new Image.asset(
          (constraints.maxWidth > constraints.maxHeight)
              ? state['imageWide'] ?? state['image']
              : state['image'],
          alignment: FractionalOffset.topCenter,
          fit: BoxFit.cover,
        ),
      );
    default:
      return new Center(child: new Text('BAD MODULE!!!'));
  }
}

/// Construct a story object from a decoded json story config.
Story storyBuilder(Map<String, dynamic> story) {
  Map<String, Object> state = story['state'];
  List icons = story['icons'];
  return new Story(
    id: new StoryId(story['id']),
    builder: (_) => new DefaultScrollConfiguration(
      child: _widgetBuilder(story['module'], state),
    ),
    title: story['title']?.toUpperCase(),
    icons: icons
        .map(
          (icon) => (BuildContext context, double opacity) => new Image.asset(
                icon,
                fit: BoxFit.cover,
                color: Colors.white.withOpacity(opacity),
              ),
        )
        .toList(),
    avatar: (_, double opacity) => new Opacity(
      opacity: opacity,
      child: new Image.asset(
        story['avatar'],
        fit: BoxFit.cover,
      ),
    ),
    lastInteraction: new DateTime.now().subtract(
      new Duration(
        seconds: int.parse(story['lastInteraction']),
      ),
    ),
    cumulativeInteractionDuration: new Duration(
      minutes: int.parse(story['culmulativeInteraction']),
    ),
    themeColor: new Color(int.parse(story['color'])),
    inactive: 'true' == (story['inactive'] ?? 'false'),
  );
}
