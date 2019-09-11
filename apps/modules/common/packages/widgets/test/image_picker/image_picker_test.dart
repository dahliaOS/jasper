// Copyright 2017 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:widgets/image_picker.dart';

final List<String> _images = <String>[
  'https://github.com/dvdwasibi/DogsOfFuchsia/blob/master/coco.jpg?raw=true&i=1',
  'https://github.com/dvdwasibi/DogsOfFuchsia/blob/master/coco.jpg?raw=true&i=2',
  'https://github.com/dvdwasibi/DogsOfFuchsia/blob/master/coco.jpg?raw=true&i=3',
  'https://github.com/dvdwasibi/DogsOfFuchsia/blob/master/coco.jpg?raw=true&i=4',
];

void main() {
  testWidgets(
      'The "Add Images" footer should not appear when no images are selected',
      (WidgetTester tester) async {
    await tester.pumpWidget(new Material(
      child: new ImagePicker(
        imageUrls: _images,
      ),
    ));
    expect(find.text('ADD'), findsNothing);
  });

  testWidgets(
      'Tapping on a ImageEntry should set it as SELECTED and the "Add Images" '
      'footer should appear when at least one image is selected',
      (WidgetTester tester) async {
    await tester.pumpWidget(new Material(
      child: new ImagePicker(
        imageUrls: _images,
      ),
    ));
    Finder firstImage = find.byWidgetPredicate((Widget widget) =>
        widget is ImageEntry && widget.imageUrl == _images.first);
    await tester.tap(firstImage);
    await tester.pump();
    ImageEntry image = tester.widget(firstImage);
    expect(image.selected, true);
    expect(find.text('ADD'), findsOneWidget);
  });

  testWidgets('Tapping on a selected image should unselect it ',
      (WidgetTester tester) async {
    await tester.pumpWidget(new Material(
      child: new ImagePicker(
        imageUrls: _images,
      ),
    ));
    Finder firstImage = find.byWidgetPredicate((Widget widget) =>
        widget is ImageEntry && widget.imageUrl == _images.first);
    await tester.tap(firstImage);
    await tester.pump();
    ImageEntry image = tester.widget(firstImage);
    expect(image.selected, true);
    await tester.tap(firstImage);
    await tester.pump();
    image = tester.widget(firstImage);
    expect(image.selected, false);
  });

  testWidgets(
      'Tapping on the "ADD" button should call the onAdd callback with all the '
      'selected images ', (WidgetTester tester) async {
    List<String> selectedImages;
    await tester.pumpWidget(new Material(
      child: new ImagePicker(
        imageUrls: _images,
        onAdd: (List<String> images) => selectedImages = images,
      ),
    ));
    Finder firstImage = find.byWidgetPredicate((Widget widget) =>
        widget is ImageEntry && widget.imageUrl == _images.first);
    Finder secondImage = find.byWidgetPredicate((Widget widget) =>
        widget is ImageEntry && widget.imageUrl == _images[1]);
    await tester.tap(firstImage);
    await tester.tap(secondImage);
    await tester.pump();
    await tester.tap(find.text('ADD'));
    await tester.pump();
    expect(selectedImages.length, 2);
    expect(selectedImages.contains(_images[0]), true);
    expect(selectedImages.contains(_images[1]), true);
  });
}
