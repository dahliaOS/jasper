// Copyright 2016 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/rendering.dart';
import 'package:meta/meta.dart';
import 'package:sysui_widgets/rk4_spring_simulation.dart';
import 'package:sysui_widgets/ticking_state.dart';

import 'armadillo_overlay.dart';

/// The time to wait before triggering a long press.
const Duration _kLongPressTimeout = const Duration(milliseconds: 300);

/// Much of this code is borrowed from the Flutter framework's inplementation
/// of [Draggable] and [DragTarget].  What is different about this
/// implementation is the addition of each piece of data having an associated
/// [Offset] which indicates where it is when hovering
/// (passed in via [ArmadilloDragTargetWillAccept]) and when dropped (passed in
/// via [ArmadilloDragTargetAccept]).  We also use [ArmadilloOverlay] instead of
/// [Overlay] to display draggable drag feedback so the drag feedback can be
/// displayed in any part of the widget tree (and not just in an ancestor of the
/// draggable).
///
/// Other than keeping track of points for all candidates, the bulk of Flutter's
/// code remains intact.

/// Signature for building children of a [ArmadilloDragTarget].
///
/// The `candidateData` argument contains the list of drag data that is hovering
/// over this [DragTarget] and that has passed [ArmadilloDragTarget.onWillAccept]. The
/// `rejectedData` argument contains the list of drag data that is hovering over
/// this [ArmadilloDragTarget] and that will not be accepted by the [ArmadilloDragTarget].
typedef Widget ArmadilloDragTargetBuilder<T>(
  BuildContext context,
  Map<T, Offset> candidateData,
  Map<dynamic, Offset> rejectedData,
);

/// Signature for determining whether the given data will be accepted by a [ArmadilloDragTarget].
typedef bool ArmadilloDragTargetWillAccept<T>(T data, Offset point);

/// Signature for causing a [ArmadilloDragTarget] to accept the given data.
typedef void ArmadilloDragTargetAccept<T>(
  T data,
  Offset point,
  Velocity velocity,
);

/// Builds the feedback that should be shown while a
/// [ArmadilloLongPressDraggable] is being dragged.
/// [localDragStartPoint] indicates where the drag started in the draggable's
/// local coordinate space.
typedef Widget FeedbackBuilder(
  Offset localDragStartPoint,
  Rect initialBoundsOnDrag,
);

/// Called when a drag starts.  The returned [Rect] should be the bounds of the
/// dragged widget.
typedef Rect OnDragStarted();

/// A widget that can be dragged from to a [ArmadilloDragTarget] starting from long press.
///
/// When a draggable widget recognizes the start of a drag gesture, it displays
/// a widget built by [feedbackBuilder] that tracks the user's finger across the
/// screen. If the user lifts their finger while on top of a
/// [ArmadilloDragTarget], that target is given the opportunity to accept the
/// [data] carried by the draggble.
///
/// See also:
///
///  * [ArmadilloDragTarget]
class ArmadilloLongPressDraggable<T> extends StatefulWidget {
  /// Creates a widget that can be dragged starting from long press.
  ///
  /// The [child] and [feedbackBuilder] arguments must not be null.
  ArmadilloLongPressDraggable({
    Key key,
    @required this.overlayKey,
    @required this.child,
    @required this.feedbackBuilder,
    @required this.data,
    this.childWhenDragging,
    this.onDragStarted,
    this.onDragEnded,
  })
      : super(key: key) {
    assert(overlayKey != null);
    assert(child != null);
    assert(feedbackBuilder != null);
  }

  /// The data that will be dropped by this draggable.
  final T data;

  /// The widget below this widget in the tree.
  final Widget child;

  /// The widget to show instead of [child] when a drag is under way.
  ///
  /// If this is null, then [child] will be used instead (and so the
  /// drag source representation will change while a drag is under
  /// way).
  final Widget childWhenDragging;

  /// The widget to show under the pointer when a drag is under way.
  final FeedbackBuilder feedbackBuilder;

  /// Called when a drag starts.  The bounds of the dragged widget should be
  /// returned by this callback.
  final OnDragStarted onDragStarted;

  /// Called when a drag ends.
  final VoidCallback onDragEnded;

  /// The key of the overlay the drag avatar will be built in.
  final GlobalKey<ArmadilloOverlayState> overlayKey;

  /// Creates a gesture recognizer that recognizes the start of the drag.
  ///
  /// Subclasses can override this function to customize when they start
  /// recognizing a drag.
  DelayedMultiDragGestureRecognizer createRecognizer(
          GestureMultiDragStartCallback onStart) =>
      new DelayedMultiDragGestureRecognizer(delay: _kLongPressTimeout)
        ..onStart = (Offset position) {
          Drag result = onStart(position);
          if (result != null) {
            HapticFeedback.vibrate();
          }
          return result;
        };

  @override
  _DraggableState<T> createState() => new _DraggableState<T>();
}

const RK4SpringDescription _kDefaultSimulationDesc =
    const RK4SpringDescription(tension: 450.0, friction: 50.0);

class _DraggableState<T> extends State<ArmadilloLongPressDraggable<T>> {
  final GlobalKey<_DragAvatarWidgetState> _dragAvatarKey =
      new GlobalKey<_DragAvatarWidgetState>();
  final GlobalKey _nonDraggedChildKey = new GlobalKey();
  GestureRecognizer _recognizer;
  int _activeCount = 0;

  @override
  void initState() {
    super.initState();
    _recognizer = widget.createRecognizer(_startDrag);
  }

  @override
  void dispose() {
    _recognizer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool showChild =
        (_activeCount == 0 || widget.childWhenDragging == null) &&
            (_dragAvatarKey.currentState?.isDone ?? true);
    return new Listener(
      key: _nonDraggedChildKey,
      onPointerDown: _routePointer,
      child: showChild ? widget.child : widget.childWhenDragging,
    );
  }

  bool get _canDrag =>
      (_activeCount < 1) &&
      !(widget.overlayKey.currentState?.hasBuilders ?? false);

  void _routePointer(PointerEvent event) {
    if (_canDrag) {
      _recognizer.addPointer(event);
    }
  }

  _DragAvatar<T> _startDrag(Offset position) {
    if (!_canDrag) {
      return null;
    }

    setState(() {
      _activeCount += 1;
    });

    final RenderBox box = context.findRenderObject();
    final Offset dragStartPoint = box.globalToLocal(position);
    final Rect initialBoundsOnDrag = widget.onDragStarted?.call();
    final WidgetBuilder builder =
        (BuildContext context) => new _DragAvatarWidget(
              key: _dragAvatarKey,
              returnTargetKey: _nonDraggedChildKey,
              overlayKey: widget.overlayKey,
              initialPosition: position,
              dragStartPoint: dragStartPoint,
              initialBoundsOnDrag: initialBoundsOnDrag,
              feedbackBuilder: widget.feedbackBuilder,
            );
    widget.overlayKey.currentState.addBuilder(builder);

    _DragAvatar<T> dragAvatar = new _DragAvatar<T>(
      data: widget.data,
      onDragUpdate: (Offset position) =>
          _dragAvatarKey.currentState?.updatePosition(position),
      onDragEnd: (bool wasAccepted) {
        setState(() {
          _activeCount -= 1;
          if (!wasAccepted) {
            _dragAvatarKey.currentState?.startReturnSimulation(
              () => setState(
                    () => widget.overlayKey.currentState.removeBuilder(builder),
                  ),
            );
          } else {
            widget.overlayKey.currentState.removeBuilder(builder);
          }
        });
        widget.onDragEnded?.call();
      },
    );

    dragAvatar.position = position;

    return dragAvatar;
  }
}

/// This widget represents the Draggable's Avatar that follows the pointer
/// around the overlay.  It encapsulates all the state necessary to animate
/// the avatar back to the Draggable's original position when dragging first
/// started.  These include: [initialPosition], [dragStartPoint], and
/// [initialBoundsOnDrag].
/// [overlayKey] is the key to the overlay this widget is a part of.  It's used
/// to properly position this widget to follow the pointer.
/// [feedbackBuilder] builds the widget that follows the pointer.
///  [returnTargetKey] is the key of the widget this widget will animate to
///  when it's dropped.
class _DragAvatarWidget extends StatefulWidget {
  final GlobalKey returnTargetKey;
  final GlobalKey<ArmadilloOverlayState> overlayKey;
  final Offset initialPosition;
  final Offset dragStartPoint;
  final Rect initialBoundsOnDrag;
  final FeedbackBuilder feedbackBuilder;

  _DragAvatarWidget({
    Key key,
    this.returnTargetKey,
    this.overlayKey,
    this.initialPosition,
    this.dragStartPoint,
    this.initialBoundsOnDrag,
    this.feedbackBuilder,
  })
      : super(key: key);

  @override
  _DragAvatarWidgetState createState() => new _DragAvatarWidgetState();
}

class _DragAvatarWidgetState extends TickingState<_DragAvatarWidget> {
  RK4SpringSimulation _returnSimulation;
  VoidCallback _onReturnSimulationDone;
  Offset _position;

  @override
  void initState() {
    super.initState();
    _position = widget.initialPosition;
  }

  @override
  Widget build(BuildContext context) {
    RenderBox overlayBox = widget.overlayKey.currentContext.findRenderObject();
    Offset overlayTopLeft = overlayBox.localToGlobal(Offset.zero);
    Offset localOffset = _position - widget.dragStartPoint;
    double left = localOffset.dx - overlayTopLeft.dx;
    double top = localOffset.dy - overlayTopLeft.dy;

    double returnProgress = _returnSimulation?.value ?? 0.0;
    if (returnProgress > 0.0) {
      final RenderBox returnTargetBox =
          widget.returnTargetKey.currentContext.findRenderObject();
      final Offset returnTargetTopLeft = returnTargetBox.localToGlobal(
        Offset.zero,
      );
      left = lerpDouble(
        left,
        returnTargetTopLeft.dx - overlayTopLeft.dx,
        returnProgress,
      );
      top = lerpDouble(
        top,
        returnTargetTopLeft.dy - overlayTopLeft.dy,
        returnProgress,
      );
    }
    return new Stack(
      fit: StackFit.passthrough,
      children: <Widget>[
        new Positioned(
          left: left,
          top: top,
          child: new IgnorePointer(
            child: widget.feedbackBuilder(
              widget.dragStartPoint,
              widget.initialBoundsOnDrag,
            ),
          ),
        ),
      ],
    );
  }

  @override
  bool handleTick(double elapsedSeconds) {
    _returnSimulation?.elapseTime(elapsedSeconds);
    if (_returnSimulation?.isDone ?? false) {
      _onReturnSimulationDone();
    }
    return !(isDone);
  }

  void updatePosition(Offset position) => setState(() {
        _position = position;
      });

  bool get isDone => _returnSimulation?.isDone ?? true;

  void startReturnSimulation(VoidCallback onReturnSimulationDone) {
    _returnSimulation = new RK4SpringSimulation(
      initValue: 0.0,
      desc: _kDefaultSimulationDesc,
    );
    _returnSimulation.target = 1.0;
    startTicking();
    _onReturnSimulationDone = onReturnSimulationDone;
  }
}

/// A widget that receives data when a [ArmadilloLongPressDraggable] widget is dropped.
///
/// When a draggable is dragged on top of a drag target, the drag target is
/// asked whether it will accept the data the draggable is carrying. If the user
/// does drop the draggable on top of the drag target (and the drag target has
/// indicated that it will accept the draggable's data), then the drag target is
/// asked to accept the draggable's data.
///
/// See also:
///
///  * [ArmadilloLongPressDraggable]
class ArmadilloDragTarget<T> extends StatefulWidget {
  /// Called to build the contents of this widget.
  ///
  /// The builder can build different widgets depending on what is being dragged
  /// into this drag target.
  final ArmadilloDragTargetBuilder<T> builder;

  /// Called to determine whether this widget is interested in receiving a given
  /// piece of data being dragged over this drag target.
  final ArmadilloDragTargetWillAccept<T> onWillAccept;

  /// Called when an acceptable piece of data was dropped over this drag target.
  final ArmadilloDragTargetAccept<T> onAccept;

  /// Creates a widget that receives drags.
  ///
  /// The [builder] argument must not be null.
  ArmadilloDragTarget({
    Key key,
    @required this.builder,
    this.onWillAccept,
    this.onAccept,
  })
      : super(key: key) {
    assert(builder != null);
  }

  @override
  _DragTargetState<T> createState() => new _DragTargetState<T>();
}

class _DragTargetState<T> extends State<ArmadilloDragTarget<T>> {
  final Map<T, Offset> _candidateData = new Map<T, Offset>();
  final Map<dynamic, Offset> _rejectedData = new Map<dynamic, Offset>();

  bool didEnter(dynamic data, Offset localPosition) {
    assert(_candidateData[data] == null);
    assert(_rejectedData[data] == null);
    if (data is T && (widget.onWillAccept?.call(data, localPosition) ?? true)) {
      setState(() {
        _candidateData[data] = localPosition;
      });
      return true;
    }
    setState(() {
      _rejectedData[data] = localPosition;
    });
    return false;
  }

  void updatePosition(dynamic data, Offset localPosition) {
    setState(() {
      if (_candidateData[data] != null) {
        _candidateData[data] = localPosition;
      }
      if (_rejectedData[data] != null) {
        _rejectedData[data] = localPosition;
      }
    });
  }

  void didLeave(dynamic data) {
    assert(_candidateData[data] != null || _rejectedData[data] != null);
    if (!mounted) {
      return;
    }
    setState(() {
      _candidateData.remove(data);
      _rejectedData.remove(data);
    });
  }

  void didDrop(dynamic data, Velocity velocity) {
    assert(_candidateData[data] != null);
    if (mounted) {
      Offset point = _candidateData[data];
      setState(() {
        _candidateData.remove(data);
        _rejectedData.remove(data);
      });
      widget.onAccept?.call(data, point, velocity);
    }
  }

  @override
  Widget build(BuildContext context) => new MetaData(
        metaData: this,
        behavior: HitTestBehavior.translucent,
        child: widget.builder(context, _candidateData, _rejectedData),
      );
}

enum _DragEndKind { dropped, canceled }
typedef void _OnDragEnd(bool wasAccepted);

// The lifetime of this object is a little dubious right now. Specifically, it
// lives as long as the pointer is down. Arguably it should self-immolate if the
// overlay goes away, or maybe even if the Draggable that created goes away.
// This will probably need to be changed once we have more experience with using
// this widget.
class _DragAvatar<T> extends Drag {
  final T data;
  final ValueChanged<Offset> onDragUpdate;
  final _OnDragEnd onDragEnd;
  final List<_DragTargetState<T>> _activeTargets = <_DragTargetState<T>>[];
  final List<_DragTargetState<T>> _enteredTargets = <_DragTargetState<T>>[];

  Offset _position;

  _DragAvatar({this.data, this.onDragUpdate, this.onDragEnd});

  set position(Offset newPosition) {
    _position = newPosition;
    _updateDrag(newPosition);
  }

  // Drag API
  @override
  void update(DragUpdateDetails details) {
    position = _position + details.delta;
  }

  @override
  void end(DragEndDetails details) => _finishDrag(
        _DragEndKind.dropped,
        details.velocity,
      );

  @override
  void cancel() => _finishDrag(_DragEndKind.canceled);

  void _updateDrag(Offset globalPosition) {
    onDragUpdate?.call(globalPosition);

    Iterable<_DragTargetState<T>> targets = _getDragTargets(globalPosition);

    // If everything's the same, bail early.
    if (!_match(targets, _enteredTargets)) {
      // Leave old targets.
      _leaveAllEntered();
      _enteredTargets.addAll(targets);

      // Enter new targets.
      _activeTargets.clear();
      _activeTargets.addAll(
        targets.where(
          (_DragTargetState<T> target) => target.didEnter(
                data,
                _globalToLocal(target, globalPosition),
              ),
        ),
      );
    }

    // Update positions
    _enteredTargets.forEach(
      (_DragTargetState<T> target) => _updatePosition(target, globalPosition),
    );
  }

  Offset _globalToLocal(_DragTargetState<T> target, Offset globalPosition) {
    RenderBox box = target.context.findRenderObject();
    return box.globalToLocal(globalPosition);
  }

  void _updatePosition(_DragTargetState<T> target, Offset globalPosition) =>
      target.updatePosition(data, _globalToLocal(target, globalPosition));

  Iterable<_DragTargetState<T>> _getDragTargets(Offset globalPosition) sync* {
    HitTestResult result = new HitTestResult();
    WidgetsBinding.instance.hitTest(result, globalPosition);

    // Look for the RenderBoxes that corresponds to the hit target (the hit target
    // widgets build RenderMetaData boxes for us for this purpose).
    for (HitTestEntry entry in result.path) {
      if (entry.target is RenderMetaData) {
        RenderMetaData renderMetaData = entry.target;
        if (renderMetaData.metaData is _DragTargetState<T>) {
          yield renderMetaData.metaData;
        }
      }
    }
  }

  bool _match(Iterable<dynamic> a, Iterable<dynamic> b) {
    bool listsMatch = false;
    if (a.length == b.length) {
      listsMatch = true;
      Iterator<dynamic> aIterator = a.iterator;
      Iterator<dynamic> bIterator = b.iterator;
      for (int i = 0; i < b.length; i += 1) {
        aIterator.moveNext();
        bIterator.moveNext();
        if (aIterator.current != bIterator.current) {
          listsMatch = false;
          break;
        }
      }
    }
    return listsMatch;
  }

  void _leaveAllEntered() {
    _enteredTargets.forEach(
      (_DragTargetState<T> target) => target.didLeave(data),
    );
    _enteredTargets.clear();
  }

  void _finishDrag(_DragEndKind endKind, [Velocity velocity]) {
    bool wasAccepted = false;
    if (endKind == _DragEndKind.dropped && _activeTargets.isNotEmpty) {
      _activeTargets.forEach((_DragTargetState<T> activeTarget) {
        activeTarget.didDrop(data, velocity);
        _enteredTargets.remove(activeTarget);
      });
      wasAccepted = true;
    }
    _leaveAllEntered();
    _activeTargets.clear();
    // TODO(ianh): consider passing _entry as well so the client can perform an animation.
    onDragEnd?.call(wasAccepted);
  }
}
