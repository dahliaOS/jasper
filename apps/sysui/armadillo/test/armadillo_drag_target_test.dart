// Copyright 2016 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:armadillo/armadillo_drag_target.dart';
import 'package:armadillo/armadillo_overlay.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/widgets.dart';

void main() {
  testWidgets('Dragging an ArmadilloLongPressDraggable',
      (WidgetTester tester) async {
    int ongoingDrags = 0;

    // Create all the widgets.
    GlobalKey overlayKey = new GlobalKey();
    ArmadilloOverlay overlay = new ArmadilloOverlay(key: overlayKey);
    GlobalKey draggableKey = new GlobalKey();
    GlobalKey childKey = new GlobalKey();
    GlobalKey childWhenDraggingKey = new GlobalKey();
    ArmadilloLongPressDraggable<int> draggable =
        new ArmadilloLongPressDraggable<int>(
      key: draggableKey,
      overlayKey: overlayKey,
      child: new Container(
        key: childKey,
        width: 100.0,
        height: 100.0,
        color: new Color(0xFFFFFF00),
      ),
      feedbackBuilder: (
        Offset localDragStartPoint,
        Rect initialBoundsOnDrag,
      ) {},
      data: 1,
      childWhenDragging: new Container(
        key: childWhenDraggingKey,
        width: 100.0,
        height: 100.0,
        color: new Color(0xFFFFFF00),
      ),
      onDragStarted: () {
        ongoingDrags++;
      },
      onDragEnded: () {
        ongoingDrags--;
      },
    );

    // Pump the widgets.
    await tester.pumpWidget(
      new Stack(
        fit: StackFit.passthrough,
        children: <Widget>[
          new Center(child: draggable),
          overlay,
        ],
      ),
    );

    // Initially only child is in the tree.
    expect(find.byKey(overlayKey), findsOneWidget);
    expect(find.byKey(draggableKey), findsOneWidget);
    expect(find.byKey(childKey), findsOneWidget);
    expect(find.byKey(childWhenDraggingKey), findsNothing);
    expect(ongoingDrags, 0);

    TestGesture gesture = await tester.startGesture(
      tester.getCenter(find.byKey(draggableKey)),
    );

    await tester.pump(new Duration(milliseconds: 150));

    // Verify the drag hasn't started yet.
    expect(find.byKey(overlayKey), findsOneWidget);
    expect(find.byKey(draggableKey), findsOneWidget);
    expect(find.byKey(childKey), findsOneWidget);
    expect(find.byKey(childWhenDraggingKey), findsNothing);
    expect(ongoingDrags, 0);

    await tester.pump(new Duration(milliseconds: 150));

    // Verify the drag has started and childWhenDragging replaces child in the tree.
    expect(ongoingDrags, 1);
    expect(find.byKey(overlayKey), findsOneWidget);
    expect(find.byKey(draggableKey), findsOneWidget);
    expect(find.byKey(childKey), findsNothing);
    expect(find.byKey(childWhenDraggingKey), findsOneWidget);

    await gesture.up();

    // Verify the drag has ended but we haven't removed the childWhenDragging yet.
    expect(ongoingDrags, 0);
    expect(find.byKey(overlayKey), findsOneWidget);
    expect(find.byKey(draggableKey), findsOneWidget);

    expect(find.byKey(childKey), findsNothing);
    expect(find.byKey(childWhenDraggingKey), findsOneWidget);

    // Start and finish 'animate back' animation.
    await tester.pump();

    await tester.pump(new Duration(milliseconds: 350));

    // Still animating...
    expect(find.byKey(childKey), findsNothing);
    expect(find.byKey(childWhenDraggingKey), findsOneWidget);

    await tester.pump(new Duration(milliseconds: 350));

    // Verify we have replaced childWhenDragging with child.
    expect(find.byKey(childKey), findsOneWidget);
    expect(find.byKey(childWhenDraggingKey), findsNothing);
  });

  testWidgets('Dragging multiple ArmadilloLongPressDraggables is not possible',
      (WidgetTester tester) async {
    int ongoingDrags = 0;

    // Create all the widgets.
    GlobalKey overlayKey = new GlobalKey();
    ArmadilloOverlay overlay = new ArmadilloOverlay(key: overlayKey);
    GlobalKey draggableKey = new GlobalKey();
    ArmadilloLongPressDraggable<int> draggable =
        new ArmadilloLongPressDraggable<int>(
      key: draggableKey,
      overlayKey: overlayKey,
      child: new Container(
        width: 100.0,
        height: 100.0,
        color: new Color(0xFFFFFF00),
      ),
      feedbackBuilder: (
        Offset localDragStartPoint,
        Rect initialBoundsOnDrag,
      ) {},
      data: 1,
      childWhenDragging: new Container(
        width: 100.0,
        height: 100.0,
        color: new Color(0xFFFFFF00),
      ),
      onDragStarted: () {
        ongoingDrags++;
      },
      onDragEnded: () {
        ongoingDrags--;
      },
    );

    // Pump the widgets.
    await tester.pumpWidget(
      new Stack(
        fit: StackFit.passthrough,
        children: <Widget>[
          new Center(child: draggable),
          overlay,
        ],
      ),
    );

    expect(ongoingDrags, 0);

    // Start one drag.
    TestGesture gesture1 = await tester.startGesture(
      tester.getCenter(find.byKey(draggableKey)),
      pointer: 1,
    );

    await tester.pump(new Duration(milliseconds: 1));

    // Start a second drag.
    TestGesture gesture2 = await tester.startGesture(
      tester.getCenter(find.byKey(draggableKey)),
      pointer: 2,
    );

    await tester.pump(new Duration(milliseconds: 300));

    // Verify only one of the drags triggers dragging.
    expect(ongoingDrags, 1);

    await tester.pump(new Duration(milliseconds: 300));

    // Still only one drag.
    expect(ongoingDrags, 1);

    await gesture2.up();

    // The second drag attempt was ignored so lifting that pointer doesn't
    // trigger onDragEnded.
    expect(ongoingDrags, 1);

    await gesture1.up();

    // The first drag attempt correctly triggers onDragEnded.
    expect(ongoingDrags, 0);
  });

  testWidgets(
      'Dragging an ArmadilloLongPressDraggable over an ArmadilloDragTarget',
      (WidgetTester tester) async {
    // Create all the widgets.
    GlobalKey overlayKey = new GlobalKey();
    ArmadilloOverlay overlay = new ArmadilloOverlay(key: overlayKey);

    GlobalKey draggableKey = new GlobalKey();
    ArmadilloLongPressDraggable<int> draggable =
        new ArmadilloLongPressDraggable<int>(
      key: draggableKey,
      overlayKey: overlayKey,
      child: new Container(
        width: 100.0,
        height: 100.0,
        color: new Color(0xFFFFFF00),
      ),
      feedbackBuilder: (
        Offset localDragStartPoint,
        Rect initialBoundsOnDrag,
      ) {},
      data: 1,
    );

    GlobalKey acceptingDragTargetKey = new GlobalKey();
    Map<int, Offset> acceptingCandidateData;
    Map<dynamic, Offset> acceptingRejectedData;
    ArmadilloDragTarget<int> acceptingDragTarget = new ArmadilloDragTarget<int>(
      key: acceptingDragTargetKey,
      onWillAccept: (int data, Offset point) {
        assert(data == 1);
        return true;
      },
      onAccept: (int data, Offset point, Velocity velocity) {
        assert(data == 1);
      },
      builder: (
        BuildContext context,
        Map<int, Offset> candidateData,
        Map<dynamic, Offset> rejectedData,
      ) {
        acceptingCandidateData = candidateData;
        acceptingRejectedData = rejectedData;
        return new Container(
          width: 100.0,
          height: 100.0,
          color: new Color(0xFFFFFF00),
        );
      },
    );

    GlobalKey unacceptingDragTargetKey = new GlobalKey();
    Map<int, Offset> unacceptingCandidateData;
    Map<dynamic, Offset> unacceptingRejectedData;
    ArmadilloDragTarget<int> unacceptingDragTarget =
        new ArmadilloDragTarget<int>(
      key: unacceptingDragTargetKey,
      onWillAccept: (int data, Offset point) {
        assert(data == 1);
        return false;
      },
      onAccept: (int data, Offset point, Velocity velocity) {
        throw new AssertionError('onAccept shouldn\'t have been called!');
      },
      builder: (
        BuildContext context,
        Map<int, Offset> candidateData,
        Map<dynamic, Offset> rejectedData,
      ) {
        unacceptingCandidateData = candidateData;
        unacceptingRejectedData = rejectedData;
        return new Container(
          width: 100.0,
          height: 100.0,
          color: new Color(0xFFFFFF00),
        );
      },
    );

    // Pump the widgets.
    await tester.pumpWidget(
      new Container(
        width: 300.0,
        height: 300.0,
        child: new Stack(
          fit: StackFit.passthrough,
          children: <Widget>[
            new Align(
              alignment: FractionalOffset.topLeft,
              child: unacceptingDragTarget,
            ),
            new Align(
              alignment: FractionalOffset.bottomRight,
              child: acceptingDragTarget,
            ),
            new Center(child: draggable),
            overlay,
          ],
        ),
      ),
    );

    expect(find.byKey(overlayKey), findsOneWidget);
    expect(find.byKey(draggableKey), findsOneWidget);
    expect(find.byKey(acceptingDragTargetKey), findsOneWidget);
    expect(find.byKey(unacceptingDragTargetKey), findsOneWidget);

    // Start dragging the draggable.
    TestGesture gesture = await tester.startGesture(
      tester.getCenter(find.byKey(draggableKey)),
    );

    await tester.pump(new Duration(milliseconds: 300));

    expect(unacceptingCandidateData.isEmpty, isTrue);
    expect(unacceptingRejectedData.isEmpty, isTrue);
    expect(acceptingCandidateData.isEmpty, isTrue);
    expect(acceptingRejectedData.isEmpty, isTrue);

    // Move over the accepting target.
    await gesture.moveTo(tester.getCenter(find.byKey(acceptingDragTargetKey)));

    // Verify we've accepted it.
    expect(unacceptingCandidateData.isEmpty, isTrue);
    expect(unacceptingRejectedData.isEmpty, isTrue);
    expect(acceptingCandidateData.isEmpty, isFalse);
    expect(acceptingRejectedData.isEmpty, isTrue);
    expect(
      acceptingCandidateData.values.single - Offset.zero,
      tester.getCenter(find.byKey(acceptingDragTargetKey)) -
          tester.getTopLeft(find.byKey(acceptingDragTargetKey)),
    );

    // Move over the unaccepting target.
    await gesture.moveTo(
      tester.getCenter(find.byKey(unacceptingDragTargetKey)),
    );

    // Verify we haven't accepted it.
    expect(unacceptingCandidateData.isEmpty, isTrue);
    expect(unacceptingRejectedData.isEmpty, isFalse);
    expect(acceptingCandidateData.isEmpty, isTrue);
    expect(acceptingRejectedData.isEmpty, isTrue);
    expect(
      unacceptingRejectedData.values.single - Offset.zero,
      tester.getCenter(find.byKey(unacceptingDragTargetKey)) -
          tester.getTopLeft(find.byKey(unacceptingDragTargetKey)),
    );
  });

  testWidgets(
      'Dragging an ArmadilloLongPressDraggable over overlapping ArmadilloDragTargets',
      (WidgetTester tester) async {
    // Create all the widgets.
    GlobalKey overlayKey = new GlobalKey();
    ArmadilloOverlay overlay = new ArmadilloOverlay(key: overlayKey);

    GlobalKey draggableKey = new GlobalKey();
    ArmadilloLongPressDraggable<int> draggable =
        new ArmadilloLongPressDraggable<int>(
      key: draggableKey,
      overlayKey: overlayKey,
      child: new Container(
        width: 100.0,
        height: 100.0,
        color: new Color(0xFFFFFF00),
      ),
      feedbackBuilder: (
        Offset localDragStartPoint,
        Rect initialBoundsOnDrag,
      ) {},
      data: 1,
    );

    // NOTE: the three drag targets are all transparent to hit testing
    // (transparent containers). So all will have a chance to accept or reject
    // the candidate.
    GlobalKey acceptingDragTargetKey1 = new GlobalKey();
    Map<int, Offset> acceptingCandidateData1;
    Map<dynamic, Offset> acceptingRejectedData1;
    ArmadilloDragTarget<int> acceptingDragTarget1 =
        new ArmadilloDragTarget<int>(
      key: acceptingDragTargetKey1,
      onWillAccept: (int data, Offset point) {
        assert(data == 1);
        return true;
      },
      onAccept: (int data, Offset point, Velocity velocity) {
        assert(data == 1);
      },
      builder: (
        BuildContext context,
        Map<int, Offset> candidateData,
        Map<dynamic, Offset> rejectedData,
      ) {
        acceptingCandidateData1 = candidateData;
        acceptingRejectedData1 = rejectedData;
        return new Container(
          width: 100.0,
          height: 100.0,
        );
      },
    );

    GlobalKey acceptingDragTargetKey2 = new GlobalKey();
    Map<int, Offset> acceptingCandidateData2;
    Map<dynamic, Offset> acceptingRejectedData2;
    ArmadilloDragTarget<int> acceptingDragTarget2 =
        new ArmadilloDragTarget<int>(
      key: acceptingDragTargetKey2,
      onWillAccept: (int data, Offset point) {
        assert(data == 1);
        return true;
      },
      onAccept: (int data, Offset point, Velocity velocity) {
        assert(data == 1);
      },
      builder: (
        BuildContext context,
        Map<int, Offset> candidateData,
        Map<dynamic, Offset> rejectedData,
      ) {
        acceptingCandidateData2 = candidateData;
        acceptingRejectedData2 = rejectedData;
        return new Container(
          width: 100.0,
          height: 100.0,
        );
      },
    );

    GlobalKey unacceptingDragTargetKey = new GlobalKey();
    Map<int, Offset> unacceptingCandidateData;
    Map<dynamic, Offset> unacceptingRejectedData;
    ArmadilloDragTarget<int> unacceptingDragTarget =
        new ArmadilloDragTarget<int>(
      key: unacceptingDragTargetKey,
      onWillAccept: (int data, Offset point) {
        assert(data == 1);
        return false;
      },
      onAccept: (int data, Offset point, Velocity velocity) {
        throw new AssertionError('onAccept shouldn\'t have been called!');
      },
      builder: (
        BuildContext context,
        Map<int, Offset> candidateData,
        Map<dynamic, Offset> rejectedData,
      ) {
        unacceptingCandidateData = candidateData;
        unacceptingRejectedData = rejectedData;
        return new Container(
          width: 100.0,
          height: 100.0,
        );
      },
    );

    // Pump the widgets.  Place all drag targets on top of each other.
    await tester.pumpWidget(
      new Container(
        width: 300.0,
        height: 300.0,
        child: new Stack(
          fit: StackFit.passthrough,
          children: <Widget>[
            new Align(
              alignment: FractionalOffset.topLeft,
              child: unacceptingDragTarget,
            ),
            new Align(
              alignment: FractionalOffset.topLeft,
              child: acceptingDragTarget1,
            ),
            new Align(
              alignment: FractionalOffset.topLeft,
              child: acceptingDragTarget2,
            ),
            new Center(child: draggable),
            overlay,
          ],
        ),
      ),
    );

    expect(find.byKey(overlayKey), findsOneWidget);
    expect(find.byKey(draggableKey), findsOneWidget);
    expect(find.byKey(acceptingDragTargetKey1), findsOneWidget);
    expect(find.byKey(acceptingDragTargetKey2), findsOneWidget);
    expect(find.byKey(unacceptingDragTargetKey), findsOneWidget);

    // Begin dragging the draggable.
    TestGesture gesture = await tester.startGesture(
      tester.getCenter(find.byKey(draggableKey)),
    );

    await tester.pump(new Duration(milliseconds: 300));

    expect(unacceptingCandidateData.isEmpty, isTrue);
    expect(unacceptingRejectedData.isEmpty, isTrue);
    expect(acceptingCandidateData1.isEmpty, isTrue);
    expect(acceptingRejectedData1.isEmpty, isTrue);
    expect(acceptingCandidateData2.isEmpty, isTrue);
    expect(acceptingRejectedData2.isEmpty, isTrue);

    // Move over the drag targets.
    await gesture.moveTo(tester.getCenter(find.byKey(acceptingDragTargetKey1)));

    // Verify all the drag targets have either accepted or rejected the
    // draggable.
    expect(unacceptingCandidateData.isEmpty, isTrue);
    expect(unacceptingRejectedData.isEmpty, isFalse);
    expect(acceptingCandidateData1.isEmpty, isFalse);
    expect(acceptingRejectedData1.isEmpty, isTrue);
    expect(acceptingCandidateData2.isEmpty, isFalse);
    expect(acceptingRejectedData2.isEmpty, isTrue);
    expect(
      acceptingCandidateData1.values.single - Offset.zero,
      tester.getCenter(find.byKey(acceptingDragTargetKey1)) -
          tester.getTopLeft(find.byKey(acceptingDragTargetKey1)),
    );
    expect(
      acceptingCandidateData2.values.single - Offset.zero,
      tester.getCenter(find.byKey(acceptingDragTargetKey2)) -
          tester.getTopLeft(find.byKey(acceptingDragTargetKey2)),
    );
    expect(
      unacceptingRejectedData.values.single - Offset.zero,
      tester.getCenter(find.byKey(unacceptingDragTargetKey)) -
          tester.getTopLeft(find.byKey(unacceptingDragTargetKey)),
    );
  });
}
