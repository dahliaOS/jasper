// Copyright 2016 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:armadillo/story.dart';
import 'package:armadillo/story_cluster.dart';
import 'package:armadillo/story_list_layout.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/widgets.dart';

/// Set this to true to see what the actual bounds will be in the case you need
/// to update the expected bounds.  The output should be copy-pastable into the
/// expected bounds array.
const bool _kPrintBounds = false;

final DateTime _kCurrentTime = new DateTime.now();
final List<Story> _kDummyStories = <Story>[
  new Story(
    lastInteraction: _kCurrentTime,
    cumulativeInteractionDuration: const Duration(minutes: 7),
  ),
  new Story(
    lastInteraction: _kCurrentTime.subtract(const Duration(minutes: 7)),
    cumulativeInteractionDuration: const Duration(minutes: 34),
  ),
  new Story(
    lastInteraction: _kCurrentTime.subtract(const Duration(minutes: 41)),
    cumulativeInteractionDuration: const Duration(minutes: 24),
  ),
  new Story(
    lastInteraction: _kCurrentTime.subtract(const Duration(minutes: 65)),
    cumulativeInteractionDuration: const Duration(minutes: 24),
  ),
  new Story(
    lastInteraction: _kCurrentTime.subtract(const Duration(minutes: 89)),
    cumulativeInteractionDuration: const Duration(minutes: 18),
  ),
  new Story(
    lastInteraction: _kCurrentTime.subtract(const Duration(minutes: 107)),
    cumulativeInteractionDuration: const Duration(minutes: 1),
  ),
  new Story(
    lastInteraction: _kCurrentTime.subtract(const Duration(minutes: 108)),
    cumulativeInteractionDuration: const Duration(minutes: 29),
  ),
  new Story(
    lastInteraction: _kCurrentTime.subtract(const Duration(minutes: 152)),
    cumulativeInteractionDuration: const Duration(minutes: 20),
  ),
  new Story(
    lastInteraction: _kCurrentTime.subtract(const Duration(minutes: 198)),
    cumulativeInteractionDuration: const Duration(minutes: 9),
  ),
  new Story(
    lastInteraction: _kCurrentTime.subtract(const Duration(minutes: 207)),
    cumulativeInteractionDuration: const Duration(minutes: 6),
  ),
  new Story(
    lastInteraction: _kCurrentTime.subtract(const Duration(minutes: 213)),
    cumulativeInteractionDuration: const Duration(minutes: 28),
  ),
  new Story(
    lastInteraction: _kCurrentTime.subtract(const Duration(minutes: 241)),
    cumulativeInteractionDuration: const Duration(minutes: 26),
  ),
  new Story(
    lastInteraction: _kCurrentTime.subtract(const Duration(minutes: 272)),
    cumulativeInteractionDuration: const Duration(minutes: 1),
  ),
  new Story(
    lastInteraction: _kCurrentTime.subtract(const Duration(minutes: 273)),
    cumulativeInteractionDuration: const Duration(minutes: 3),
  ),
  new Story(
    lastInteraction: _kCurrentTime.subtract(const Duration(minutes: 276)),
    cumulativeInteractionDuration: const Duration(minutes: 20),
  ),
  new Story(
    lastInteraction: _kCurrentTime.subtract(const Duration(minutes: 296)),
    cumulativeInteractionDuration: const Duration(minutes: 28),
  ),
  new Story(
    lastInteraction: _kCurrentTime.subtract(const Duration(minutes: 324)),
    cumulativeInteractionDuration: const Duration(minutes: 3),
  ),
  new Story(
    lastInteraction: _kCurrentTime.subtract(const Duration(minutes: 327)),
    cumulativeInteractionDuration: const Duration(minutes: 18),
  ),
  new Story(
    lastInteraction: _kCurrentTime.subtract(const Duration(minutes: 369)),
    cumulativeInteractionDuration: const Duration(minutes: 18),
  ),
  new Story(
    lastInteraction: _kCurrentTime.subtract(const Duration(minutes: 387)),
    cumulativeInteractionDuration: const Duration(minutes: 16),
  ),
  new Story(
    lastInteraction: _kCurrentTime.subtract(const Duration(minutes: 403)),
    cumulativeInteractionDuration: const Duration(minutes: 17),
  ),
  new Story(
    lastInteraction: _kCurrentTime.subtract(const Duration(minutes: 420)),
    cumulativeInteractionDuration: const Duration(minutes: 26),
  ),
  new Story(
    lastInteraction: _kCurrentTime.subtract(const Duration(minutes: 446)),
    cumulativeInteractionDuration: const Duration(minutes: 29),
  ),
  new Story(
    lastInteraction: _kCurrentTime.subtract(const Duration(minutes: 475)),
    cumulativeInteractionDuration: const Duration(minutes: 8),
  ),
];

final Size _k1280x900Size = new Size(1280.0, 800.0);
final List<Rect> _kExpectedRectsFor1280x800 = <Rect>[
  new Rect.fromLTWH(-480.0, -192.0, 240.0, 150.0),
  new Rect.fromLTWH(-192.0, -192.0, 336.0, 210.0),
  new Rect.fromLTWH(192.0, -192.0, 288.0, 180.0),
  new Rect.fromLTWH(-480.0, -456.0, 336.0, 210.0),
  new Rect.fromLTWH(-96.0, -456.0, 288.0, 180.0),
  new Rect.fromLTWH(240.0, -480.0, 240.0, 150.0),
  new Rect.fromLTWH(-384.0, -720.0, 336.0, 210.0),
  new Rect.fromLTWH(0.0, -768.0, 336.0, 210.0),
  new Rect.fromLTWH(-336.0, -960.0, 288.0, 180.0),
  new Rect.fromLTWH(0.0, -1008.0, 288.0, 180.0),
  new Rect.fromLTWH(-336.0, -1200.0, 288.0, 180.0),
  new Rect.fromLTWH(0.0, -1248.0, 288.0, 180.0),
  new Rect.fromLTWH(-336.0, -1440.0, 288.0, 180.0),
  new Rect.fromLTWH(0.0, -1488.0, 288.0, 180.0),
  new Rect.fromLTWH(-336.0, -1680.0, 288.0, 180.0),
  new Rect.fromLTWH(0.0, -1728.0, 288.0, 180.0),
  new Rect.fromLTWH(-288.0, -1896.0, 240.0, 150.0),
  new Rect.fromLTWH(0.0, -1944.0, 240.0, 150.0),
  new Rect.fromLTWH(-288.0, -2112.0, 240.0, 150.0),
  new Rect.fromLTWH(0.0, -2160.0, 240.0, 150.0),
  new Rect.fromLTWH(-288.0, -2328.0, 240.0, 150.0),
  new Rect.fromLTWH(0.0, -2376.0, 240.0, 150.0),
  new Rect.fromLTWH(-288.0, -2544.0, 240.0, 150.0),
  new Rect.fromLTWH(0.0, -2592.0, 240.0, 150.0),
];

final Size _k360x640Size = new Size(360.0, 640.0);
final List<Rect> _kExpectedRectsFor360x640 = <Rect>[
  new Rect.fromLTWH(-172.0, -155.5, 344.0, 107.5),
  new Rect.fromLTWH(-172.0, -311.0, 344.0, 107.5),
  new Rect.fromLTWH(-172.0, -466.5, 344.0, 107.5),
  new Rect.fromLTWH(-172.0, -622.0, 344.0, 107.5),
  new Rect.fromLTWH(-172.0, -777.5, 344.0, 107.5),
  new Rect.fromLTWH(-172.0, -933.0, 344.0, 107.5),
  new Rect.fromLTWH(-172.0, -1088.5, 344.0, 107.5),
  new Rect.fromLTWH(-172.0, -1244.0, 344.0, 107.5),
  new Rect.fromLTWH(-172.0, -1399.5, 344.0, 107.5),
  new Rect.fromLTWH(-172.0, -1555.0, 344.0, 107.5),
  new Rect.fromLTWH(-172.0, -1710.5, 344.0, 107.5),
  new Rect.fromLTWH(-172.0, -1866.0, 344.0, 107.5),
  new Rect.fromLTWH(-172.0, -2021.5, 344.0, 107.5),
  new Rect.fromLTWH(-172.0, -2177.0, 344.0, 107.5),
  new Rect.fromLTWH(-172.0, -2332.5, 344.0, 107.5),
  new Rect.fromLTWH(-172.0, -2488.0, 344.0, 107.5),
  new Rect.fromLTWH(-172.0, -2643.5, 344.0, 107.5),
  new Rect.fromLTWH(-172.0, -2799.0, 344.0, 107.5),
  new Rect.fromLTWH(-172.0, -2954.5, 344.0, 107.5),
  new Rect.fromLTWH(-172.0, -3110.0, 344.0, 107.5),
  new Rect.fromLTWH(-172.0, -3265.5, 344.0, 107.5),
  new Rect.fromLTWH(-172.0, -3421.0, 344.0, 107.5),
  new Rect.fromLTWH(-172.0, -3576.5, 344.0, 107.5),
  new Rect.fromLTWH(-172.0, -3732.0, 344.0, 107.5),
];

void main() {
  test('Single column, null stories in, no stories out.', () {
    Size size = new Size(100.0, 100.0);
    StoryListLayout layout = new StoryListLayout(size: size);
    List<StoryLayout> stories = layout.layout(
      storyClustersToLayout: null,
      currentTime: _kCurrentTime,
    );
    expect(stories.isEmpty, true);
  });

  test('Multi column, null stories in, no stories out.', () {
    Size size = new Size(1000.0, 100.0);
    StoryListLayout layout = new StoryListLayout(size: size);
    List<StoryLayout> stories = layout.layout(
      storyClustersToLayout: null,
      currentTime: _kCurrentTime,
    );
    expect(stories.isEmpty, true);
  });

  test('Single column, no stories in, no stories out.', () {
    Size size = new Size(100.0, 100.0);
    StoryListLayout layout = new StoryListLayout(size: size);
    List<StoryLayout> stories = layout.layout(
      storyClustersToLayout: <StoryCluster>[],
      currentTime: _kCurrentTime,
    );
    expect(stories.isEmpty, true);
  });

  test('Multi column, no stories in, no stories out.', () {
    Size size = new Size(1000.0, 100.0);
    StoryListLayout layout = new StoryListLayout(size: size);
    List<StoryLayout> stories = layout.layout(
      storyClustersToLayout: <StoryCluster>[],
      currentTime: _kCurrentTime,
    );
    expect(stories.isEmpty, true);
  });

  test('Single column, some stories in, some stories out.', () {
    StoryListLayout layout = new StoryListLayout(size: _k360x640Size);
    List<StoryLayout> stories = layout.layout(
      storyClustersToLayout: _kDummyStories
          .map((Story story) => new StoryCluster(stories: <Story>[story]))
          .toList(),
      currentTime: _kCurrentTime,
    );
    expect(stories.length, _kDummyStories.length);

    if (_kPrintBounds) {
      _printBounds(stories);
    }

    for (int i = 0; i < stories.length; i++) {
      Rect bounds = stories[i].bounds;
      expect(
        bounds.width,
        equals(_kExpectedRectsFor360x640[i].width),
        reason: "Story $i has incorrect width!",
      );
      expect(
        bounds.height,
        equals(_kExpectedRectsFor360x640[i].height),
        reason: "Story $i has incorrect height!",
      );
    }
    for (int i = 0; i < stories.length; i++) {
      Rect bounds = stories[i].bounds;
      expect(
        bounds.left,
        equals(_kExpectedRectsFor360x640[i].left),
        reason: "Story $i has incorrect left!",
      );
      expect(
        bounds.top,
        equals(_kExpectedRectsFor360x640[i].top),
        reason: "Story $i has incorrect top!",
      );
    }
  });

  test('Multi column, some stories in, some stories out.', () {
    StoryListLayout layout = new StoryListLayout(size: _k1280x900Size);
    List<StoryLayout> stories = layout.layout(
      storyClustersToLayout: _kDummyStories
          .map((Story story) => new StoryCluster(stories: <Story>[story]))
          .toList(),
      currentTime: _kCurrentTime,
    );
    expect(stories.length, _kDummyStories.length);

    if (_kPrintBounds) {
      _printBounds(stories);
    }

    for (int i = 0; i < stories.length; i++) {
      Rect bounds = stories[i].bounds;
      expect(
        bounds.width,
        equals(_kExpectedRectsFor1280x800[i].width),
        reason: "Story $i has incorrect width!",
      );
      expect(
        bounds.height,
        equals(_kExpectedRectsFor1280x800[i].height),
        reason: "Story $i has incorrect height!",
      );
    }
    for (int i = 0; i < stories.length; i++) {
      Rect bounds = stories[i].bounds;
      expect(
        bounds.left,
        equals(_kExpectedRectsFor1280x800[i].left),
        reason: "Story $i has incorrect left!",
      );
      expect(
        bounds.top,
        equals(_kExpectedRectsFor1280x800[i].top),
        reason: "Story $i has incorrect top!",
      );
    }
  });
}

/// Call this before checking bounds in tests to print out what the
/// actual bounds will be.  Use the output to update the expected bounds
/// array when you're sure it's what you want.
void _printBounds(List<StoryLayout> stories) {
  for (int i = 0; i < stories.length; i++) {
    Rect bounds = stories[i].bounds;
    print(
        'new Rect.fromLTWH(${bounds.left},${bounds.top},${bounds.width},${bounds.height}),');
  }
}
