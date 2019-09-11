// Copyright 2017 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:widgets/image_picker.dart';

const String _imageUrl =
    'https://github.com/dvdwasibi/DogsOfFuchsia/blob/master/coco.jpg?raw=true';

void main() {
  testWidgets('Tapping on the ImageEntry should call the appropriate callback',
      (WidgetTester tester) async {
    Key imageEntryKey = new UniqueKey();

    int taps = 0;

    await tester.pumpWidget(new Material(
      child: new ImageEntry(
        key: imageEntryKey,
        onTap: () => taps++,
        imageUrl: _imageUrl,
      ),
    ));

    expect(taps, 0);
    await tester.tap(find.byKey(imageEntryKey));
    expect(taps, 1);
  });

  testWidgets(
      'A check icon should appear and the image should shrink when SELECTED is '
      'set as true', (WidgetTester tester) async {
    double size = 150.0;
    await tester.pumpWidget(new Material(
      child: new ImageEntry(
        imageUrl: _imageUrl,
        selected: true,
        size: size,
      ),
    ));
    expect(
        find.byWidgetPredicate(
            (Widget widget) => widget is Icon && widget.icon == Icons.check),
        findsOneWidget);
    final RenderBox box = tester.renderObject(find.byType(Image));
    expect(box.constraints.maxWidth < size, true);
    expect(box.constraints.maxHeight < size, true);
  });
}
