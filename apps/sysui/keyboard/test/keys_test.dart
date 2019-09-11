// Copyright 2016 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:keyboard/keys.dart';

final AssetBundle _defaultBundle = new NetworkAssetBundle(Uri.base);

void main() {
  testWidgets(
      'tapping background around text in TextKey registers as key being pressed',
      (WidgetTester tester) async {
    String onTextText;

    GlobalKey textKeyKey = new GlobalKey();
    TextKey textKey = new TextKey('A',
        key: textKeyKey, onText: (String text) => onTextText = text);

    await tester.pumpWidget(new Row(children: <Widget>[textKey]));
    expect(onTextText, isNull);

    await _tap(tester, _getMiddleOfLeftSide(tester, textKeyKey));
    expect(onTextText, "A");
  });

  testWidgets(
      'tapping background around text in ImageKey registers as key being pressed',
      (WidgetTester tester) async {
    bool pressed = false;

    GlobalKey imageKeyKey = new GlobalKey();
    ImageKey imageKey = new ImageKey(
      "doesn't matter",
      () => pressed = true,
      const Color(0xFFFFFFFF),
      54.0,
      key: imageKeyKey,
    );

    await tester.pumpWidget(new DefaultAssetBundle(
        bundle: _defaultBundle, child: new Row(children: <Widget>[imageKey])));
    expect(pressed, isFalse);

    await _tap(tester, _getMiddleOfLeftSide(tester, imageKeyKey));
    expect(pressed, isTrue);
  });
}

Offset _getMiddleOfLeftSide(WidgetTester tester, Key key) {
  Finder element = find.byKey(key);
  Offset topLeft = tester.getTopLeft(element);
  Offset center = tester.getCenter(element);
  return new Offset(topLeft.dx, center.dy);
}

Future<Null> _tap(WidgetTester tester, Offset point) async {
  TestGesture gesture = await tester.startGesture(point, pointer: 8);
  await tester.pump();
  await gesture.up();
  await tester.pump();
}
