// Copyright 2017 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

/// The time to wait before triggering a long press.
const Duration _kLongPressTimeout = const Duration(milliseconds: 300);

/// Triggers drag callbacks after a long press.
class LongPressGestureDetector extends StatefulWidget {
  /// Long press gestures are listened for on this [Widget].
  final Widget child;

  /// Called when a drag starts after a long press.
  final GestureDragStartCallback onDragStart;

  /// Called when the dragging updates.
  final GestureDragUpdateCallback onDragUpdate;

  /// Called when the dragging ends.
  final GestureDragEndCallback onDragEnd;

  /// Called when the dragging is canceled.
  final GestureDragCancelCallback onDragCancel;

  /// Constructor.
  LongPressGestureDetector({
    Key key,
    this.onDragStart,
    this.onDragUpdate,
    this.onDragEnd,
    this.onDragCancel,
    this.child,
  })
      : super(key: key);

  @override
  _LongPressGestureDetectorState createState() =>
      new _LongPressGestureDetectorState();
}

class _LongPressGestureDetectorState extends State<LongPressGestureDetector> {
  GestureRecognizer _recognizer;
  bool _active = false;

  @override
  void initState() {
    super.initState();
    _recognizer =
        new DelayedMultiDragGestureRecognizer(delay: _kLongPressTimeout)
          ..onStart = (Offset position) {
            widget.onDragStart(
              new DragStartDetails(
                globalPosition: position,
              ),
            );
            HapticFeedback.vibrate();
            return new _LongPressGestureDetectorDrag(
              onDragUpdate: widget.onDragUpdate,
              onDragEnd: (DragEndDetails details) {
                _active = false;
                widget.onDragEnd(details);
              },
              onDragCancel: () {
                _active = false;
                widget.onDragCancel();
              },
            );
          };
  }

  @override
  void dispose() {
    _recognizer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => new Listener(
        onPointerDown: (PointerEvent event) {
          if (!_active) {
            _recognizer.addPointer(event);
            _active = true;
          }
        },
        behavior: HitTestBehavior.opaque,
        child: widget.child,
      );
}

class _LongPressGestureDetectorDrag extends Drag {
  final GestureDragUpdateCallback onDragUpdate;
  final GestureDragEndCallback onDragEnd;
  final GestureDragCancelCallback onDragCancel;

  _LongPressGestureDetectorDrag({
    this.onDragUpdate,
    this.onDragEnd,
    this.onDragCancel,
  });

  @override
  void update(DragUpdateDetails details) => onDragUpdate(details);

  @override
  void end(DragEndDetails details) => onDragEnd(details);

  @override
  void cancel() => onDragCancel();
}
