// Copyright 2016 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:widgets/youtube.dart';

void main() {
  testWidgets(
      'Test to see if tapping on a YoutubeThumbnail will call the'
      'appropiate callback with given videoId', (WidgetTester tester) async {
    Key thumbnailKey = new UniqueKey();
    String videoId = '9DNFzHTUAM4';
    int taps = 0;

    await tester.pumpWidget(new StatefulBuilder(
        builder: (BuildContext context, StateSetter setState) {
      return new Material(
        child: new YoutubeThumbnail(
          key: thumbnailKey,
          videoId: videoId,
          onSelect: (String id) {
            expect(id, videoId);
            taps++;
          },
        ),
      );
    }));

    expect(taps, 0);
    await tester.tap(find.byKey(thumbnailKey));
    expect(taps, 1);
  });
}
