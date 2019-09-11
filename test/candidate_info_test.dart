// Copyright 2017 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:math' as math;

import 'package:armadillo/candidate_info.dart';
import 'package:armadillo/drag_direction.dart';
import 'package:armadillo/line_segment.dart';
import 'package:flutter/widgets.dart';
import 'package:test/test.dart';

void main() {
  test('toPoint', () {
    math.Random random = new math.Random();
    Offset point = new Offset(random.nextDouble(), random.nextDouble());
    CandidateInfo candidateInfo = new CandidateInfo(initialLockPoint: point);
    expect(CandidateInfo.toPoint(candidateInfo), equals(point));
  });

  test('dragDirection & updateVelocity', () {
    DateTime now = new DateTime.now();
    CandidateInfo candidateInfo = new CandidateInfo(
      initialLockPoint: Offset.zero,
      timestampEmitter: () => now,
    );

    expect(candidateInfo.dragDirection, equals(DragDirection.none));

    candidateInfo.updateVelocity(Offset.zero);
    expect(candidateInfo.dragDirection, equals(DragDirection.none));

    // Move quickly to right, we think we're going right.
    now = now.add(const Duration(milliseconds: 10));
    candidateInfo.updateVelocity(new Offset(100.0, 0.0));
    expect(candidateInfo.dragDirection, equals(DragDirection.right));

    // Stop for a while, we still think we're going right.
    now = now.add(const Duration(milliseconds: 1000));
    candidateInfo.updateVelocity(new Offset(100.0, 0.0));
    expect(candidateInfo.dragDirection, equals(DragDirection.right));

    // Move quickly to left, we think we're going left.
    now = now.add(const Duration(milliseconds: 10));
    candidateInfo.updateVelocity(new Offset(0.0, 0.0));
    expect(candidateInfo.dragDirection, equals(DragDirection.left));

    // Stop for a while, we still think we're going left.
    now = now.add(const Duration(milliseconds: 1000));
    candidateInfo.updateVelocity(new Offset(0.0, 0.0));
    expect(candidateInfo.dragDirection, equals(DragDirection.left));

    // Move quickly down, we think we're going down.
    now = now.add(const Duration(milliseconds: 10));
    candidateInfo.updateVelocity(new Offset(0.0, 100.0));
    expect(candidateInfo.dragDirection, equals(DragDirection.down));

    // Stop for a while, we still think we're going down.
    now = now.add(const Duration(milliseconds: 1000));
    candidateInfo.updateVelocity(new Offset(0.0, 100.0));
    expect(candidateInfo.dragDirection, equals(DragDirection.down));

    // Move quickly up, we think we're going up.
    now = now.add(const Duration(milliseconds: 10));
    candidateInfo.updateVelocity(new Offset(0.0, 0.0));
    expect(candidateInfo.dragDirection, equals(DragDirection.up));

    // Stop for a while, we still think we're going up.
    now = now.add(const Duration(milliseconds: 1000));
    candidateInfo.updateVelocity(new Offset(0.0, 0.0));
    expect(candidateInfo.dragDirection, equals(DragDirection.up));
  });

  test('lock & closestTarget', () {
    CandidateInfo candidateInfo =
        new CandidateInfo(initialLockPoint: Offset.zero);

    expect(CandidateInfo.toPoint(candidateInfo), equals(Offset.zero));
    expect(candidateInfo.closestTarget, isNull);

    math.Random random = new math.Random();
    Offset point = new Offset(random.nextDouble(), random.nextDouble());
    LineSegment line = new LineSegment(
      new Offset(100.0, 0.0),
      new Offset(100.0, 100.0),
    );
    candidateInfo.lock(point, line);

    expect(CandidateInfo.toPoint(candidateInfo), equals(point));
    expect(candidateInfo.closestTarget, equals(line));
  });

  test('canLock', () {
    DateTime now = new DateTime.now();
    Duration minLockDuration = new Duration(milliseconds: 777);

    CandidateInfo candidateInfo = new CandidateInfo(
      initialLockPoint: Offset.zero,
      timestampEmitter: () => now,
      minLockDuration: minLockDuration,
    );

    LineSegment line1 = new LineSegment.vertical(
      x: 100.0,
      top: 0.0,
      bottom: 100.0,
      name: 'line1',
    );

    LineSegment line2 = new LineSegment.vertical(
      x: 200.0,
      top: 0.0,
      bottom: 100.0,
      name: 'line2',
    );

    /// Can't lock until we've moved the min distance away from
    /// initialLockPoint.
    expect(candidateInfo.canLock(line1, Offset.zero), isFalse);
    expect(candidateInfo.canLock(line1, new Offset(25.0, 0.0)), isFalse);
    expect(candidateInfo.canLock(line1, new Offset(50.0, 0.0)), isTrue);

    candidateInfo.lock(new Offset(50.0, 0.0), line1);

    /// Can't lock to a new line within minLockDuration.
    expect(candidateInfo.canLock(line2, new Offset(200.0, 0.0)), isFalse);
    now = now.add(minLockDuration);
    expect(candidateInfo.canLock(line2, new Offset(200.0, 0.0)), isFalse);
    now = now.add(const Duration(milliseconds: 1));
    expect(candidateInfo.canLock(line2, new Offset(200.0, 0.0)), isTrue);

    /// Can't lock to same line ever.
    candidateInfo.lock(new Offset(200.0, 0.0), line2);
    now = now.add(minLockDuration);
    now = now.add(const Duration(milliseconds: 1));
    expect(candidateInfo.canLock(line2, new Offset(200.0, 0.0)), isFalse);
    expect(candidateInfo.canLock(line2, new Offset(200.0, 200.0)), isFalse);
    expect(candidateInfo.canLock(line2, new Offset(200.0, 400.0)), isFalse);
    expect(candidateInfo.canLock(line2, new Offset(0.0, 400.0)), isFalse);
  });
}
