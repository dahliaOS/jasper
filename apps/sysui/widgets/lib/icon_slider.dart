// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:math' as math;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:meta/meta.dart';

/// A material design slider.
/// Adapted from Flutter's Slider class. Adds the ability to set an image
/// for the slider control.
///
/// TODO(mikejurka): Merge these changes into Flutter's slider class
/// This code is almost identical to that class except for the paint method,
/// and the "thumbImage" parameter.
///
/// Used to select from a range of values.
///
/// A slider can be used to select from either a continuous or a discrete set of
/// values. The default is use a continuous range of values from [min] to [max].
/// To use discrete values, use a non-null value for [divisions], which
/// indicates the number of discrete intervals. For example, if [min] is 0.0 and
/// [max] is 50.0 and [divisions] is 5, then the slider can take on the values
/// discrete values 0.0, 10.0, 20.0, 30.0, 40.0, and 50.0.
///
/// The slider itself does not maintain any state. Instead, when the state of
/// the slider changes, the widget calls the [onChanged] callback. Most widgets
/// that use a slider will listen for the [onChanged] callback and rebuild the
/// slider with a new [value] to update the visual appearance of the slider.
///
/// Requires one of its ancestors to be a [Material] widget.
///
/// See also:
///
///  * [Radio]
///  * [Switch]
///  * <https://www.google.com/design/spec/components/sliders.html>
///
class IconSlider extends StatefulWidget {
  /// Creates a material design slider with an icon for the picker.
  ///
  /// The slider itself does not maintain any state. Instead, when the state of
  /// the slider changes, the widget calls the [onChanged] callback. Most widgets
  /// that use a slider will listen for the [onChanged] callback and rebuild the
  /// slider with a new [value] to update the visual appearance of the slider.
  ///
  /// * [value] determines currently selected value for this slider.
  /// * [onChanged] is called when the user selects a new value for the slider.
  IconSlider({
    Key key,
    @required this.value,
    @required this.onChanged,
    this.min: 0.0,
    this.max: 1.0,
    this.divisions,
    this.label,
    this.activeColor,
    this.thumbImage,
  }) : super(key: key) {
    assert(value != null);
    assert(min != null);
    assert(max != null);
    assert(value >= min && value <= max);
    assert(divisions == null || divisions > 0);
  }

  /// The currently selected value for this slider.
  ///
  /// The slider's thumb is drawn at a position that corresponds to this value.
  final double value;

  /// Called when the user selects a new value for the slider.
  ///
  /// The slider passes the new value to the callback but does not actually
  /// change state until the parent widget rebuilds the slider with the new
  /// value.
  ///
  /// If null, the slider will be displayed as disabled.
  final ValueChanged<double> onChanged;

  /// The minium value the user can select.
  ///
  /// Defaults to 0.0.
  final double min;

  /// The maximum value the user can select.
  ///
  /// Defaults to 1.0.
  final double max;

  /// The number of discrete divisions.
  ///
  /// Typically used with [label] to show the current discrete value.
  ///
  /// If null, the slider is continuous.
  final int divisions;

  /// A label to show above the slider when the slider is active.
  ///
  /// Typically used to display the value of a discrete slider.
  final String label;

  /// The color to use for the portion of the slider that has been selected.
  ///
  /// Defaults to accent color of the current [Theme].
  final Color activeColor;

  /// Draw this image inside the thumb (i.e. the draggable circle)
  ///
  /// If null, do not draw any image.
  final ImageProvider thumbImage;

  @override
  _IconSliderState createState() => new _IconSliderState();
}

class _IconSliderState extends State<IconSlider> with TickerProviderStateMixin {
  void _handleChanged(double value) {
    assert(widget.onChanged != null);
    widget.onChanged(value * (widget.max - widget.min) + widget.min);
  }

  @override
  Widget build(BuildContext context) {
    ThemeData theme = Theme.of(context);
    return new _IconSliderRenderObjectWidget(
        value: (widget.value - widget.min) / (widget.max - widget.min),
        divisions: widget.divisions,
        label: widget.label,
        activeColor: widget.activeColor ?? theme.accentColor,
        textTheme: theme.primaryTextTheme,
        thumbImage: widget.thumbImage,
        configuration: createLocalImageConfiguration(context),
        onChanged: widget.onChanged != null ? _handleChanged : null,
        vsync: this);
  }
}

class _IconSliderRenderObjectWidget extends LeafRenderObjectWidget {
  _IconSliderRenderObjectWidget(
      {Key key,
      this.value,
      this.divisions,
      this.label,
      this.activeColor,
      this.textTheme,
      this.thumbImage,
      this.configuration,
      this.onChanged,
      this.vsync})
      : super(key: key);

  final double value;
  final int divisions;
  final String label;
  final Color activeColor;
  final TextTheme textTheme;
  final ImageProvider thumbImage;
  final ImageConfiguration configuration;
  final ValueChanged<double> onChanged;
  final TickerProvider vsync;

  @override
  _RenderIconSlider createRenderObject(BuildContext context) =>
      new _RenderIconSlider(
        value: value,
        divisions: divisions,
        label: label,
        activeColor: activeColor,
        textTheme: textTheme,
        thumbImage: thumbImage,
        configuration: configuration,
        onChanged: onChanged,
        vsync: vsync,
      );

  @override
  void updateRenderObject(
      BuildContext context, _RenderIconSlider renderObject) {
    renderObject
      ..value = value
      ..divisions = divisions
      ..label = label
      ..activeColor = activeColor
      ..textTheme = textTheme
      ..thumbImage = thumbImage
      ..configuration = configuration
      ..onChanged = onChanged;
    // Ticker provider cannot change since there's a 1:1 relationship between
    // the _SliderRenderObjectWidget object and the _SliderState object.
  }
}

const double _kThumbRadius = 6.0;
const double _kActiveThumbRadius = 9.0;
const double _kDisabledThumbRadius = 4.0;
const double _kReactionRadius = 16.0;
const double _kTrackWidth = 144.0;
final Color _kInactiveTrackColor = Colors.grey[400];
final Color _kActiveTrackColor = Colors.grey[500];
final Tween<double> _kReactionRadiusTween =
    new Tween<double>(begin: _kThumbRadius, end: _kReactionRadius);
final Tween<double> _kThumbRadiusTween =
    new Tween<double>(begin: _kThumbRadius, end: _kActiveThumbRadius);
final ColorTween _kTrackColorTween =
    new ColorTween(begin: _kInactiveTrackColor, end: _kActiveTrackColor);
final ColorTween _kTickColorTween =
    new ColorTween(begin: Colors.transparent, end: Colors.black54);
final Duration _kDiscreteTransitionDuration = const Duration(milliseconds: 500);

const double _kLabelBalloonRadius = 14.0;
final Tween<double> _kLabelBalloonCenterTween =
    new Tween<double>(begin: 0.0, end: -_kLabelBalloonRadius * 2.0);
final Tween<double> _kLabelBalloonRadiusTween =
    new Tween<double>(begin: _kThumbRadius, end: _kLabelBalloonRadius);
final Tween<double> _kLabelBalloonTipTween =
    new Tween<double>(begin: 0.0, end: -8.0);
final double _kLabelBalloonTipAttachmentRatio = math.sin(math.pi / 4.0);

const double _kAdjustmentUnit =
    0.1; // Matches iOS implementation of material slider.

double _getAdditionalHeightForLabel(String label) {
  return label == null ? 0.0 : _kLabelBalloonRadius * 2.0;
}

BoxConstraints _getAdditionalConstraints(String label) {
  return new BoxConstraints.tightFor(
      width: _kTrackWidth + 2 * _kReactionRadius,
      height: 2 * _kReactionRadius + _getAdditionalHeightForLabel(label));
}

class _RenderIconSlider extends RenderConstrainedBox {
  _RenderIconSlider({
    double value,
    int divisions,
    String label,
    Color activeColor,
    TextTheme textTheme,
    ImageProvider thumbImage,
    ImageConfiguration configuration,
    this.onChanged,
    TickerProvider vsync,
  })  : _value = value,
        _divisions = divisions,
        _activeColor = activeColor,
        _textTheme = textTheme,
        _thumbImage = thumbImage,
        _configuration = configuration,
        super(additionalConstraints: _getAdditionalConstraints(label)) {
    assert(value != null && value >= 0.0 && value <= 1.0);
    this.label = label;
    _drag = new HorizontalDragGestureRecognizer()
      ..onStart = _handleDragStart
      ..onUpdate = _handleDragUpdate
      ..onEnd = _handleDragEnd;
    _reactionController = new AnimationController(
      duration: kRadialReactionDuration,
      vsync: vsync,
    );
    _reaction = new CurvedAnimation(
        parent: _reactionController, curve: Curves.fastOutSlowIn)
      ..addListener(markNeedsPaint);
    _position = new AnimationController(
        value: value, duration: _kDiscreteTransitionDuration, vsync: vsync)
      ..addListener(markNeedsPaint);
  }

  double get value => _value;
  double _value;
  set value(double newValue) {
    assert(newValue != null && newValue >= 0.0 && newValue <= 1.0);
    if (newValue == _value) return;
    _value = newValue;
    if (divisions != null)
      _position.animateTo(newValue, curve: Curves.fastOutSlowIn);
    else
      _position.value = newValue;
  }

  int get divisions => _divisions;
  int _divisions;
  set divisions(int newDivisions) {
    if (newDivisions == _divisions) return;
    _divisions = newDivisions;
    markNeedsPaint();
  }

  String get label => _label;
  String _label;
  set label(String newLabel) {
    if (newLabel == _label) return;
    _label = newLabel;
    additionalConstraints = _getAdditionalConstraints(_label);
    if (newLabel != null) {
      _labelPainter
        ..text = new TextSpan(
          style: _textTheme.body1.copyWith(fontSize: 10.0),
          text: newLabel,
        )
        ..layout();
    } else {
      _labelPainter.text = null;
    }
    markNeedsPaint();
  }

  TextTheme get textTheme => _textTheme;
  TextTheme _textTheme;
  set textTheme(TextTheme value) {
    if (value == _textTheme) return;
    _textTheme = value;
    markNeedsPaint();
  }

  Color get activeColor => _activeColor;
  Color _activeColor;
  set activeColor(Color value) {
    if (value == _activeColor) return;
    _activeColor = value;
    markNeedsPaint();
  }

  ImageProvider get thumbImage => _thumbImage;
  ImageProvider _thumbImage;
  set thumbImage(ImageProvider value) {
    if (value == _thumbImage) return;
    _thumbImage = value;
    markNeedsPaint();
  }

  ImageConfiguration get configuration => _configuration;
  ImageConfiguration _configuration;
  set configuration(ImageConfiguration value) {
    assert(value != null);
    if (value == _configuration) return;
    _configuration = value;
    markNeedsPaint();
  }

  @override
  void detach() {
    _cachedThumbPainter?.dispose();
    _cachedThumbPainter = null;
    super.detach();
  }

  ValueChanged<double> onChanged;

  double get _trackLength => size.width - 2.0 * _kReactionRadius;

  Animation<double> _reaction;
  AnimationController _reactionController;

  AnimationController _position;
  final TextPainter _labelPainter = new TextPainter();

  HorizontalDragGestureRecognizer _drag;
  bool _active = false;
  double _currentDragValue = 0.0;

  double get _discretizedCurrentDragValue {
    double dragValue = _currentDragValue.clamp(0.0, 1.0);
    if (divisions != null)
      dragValue = (dragValue * divisions).round() / divisions;
    return dragValue;
  }

  bool get isInteractive => onChanged != null;

  void _handleDragStart(DragStartDetails details) {
    if (isInteractive) {
      _active = true;
      _currentDragValue =
          (globalToLocal(details.globalPosition).dx - _kReactionRadius) /
              _trackLength;
      onChanged(_discretizedCurrentDragValue);
      _reactionController.forward();
      markNeedsPaint();
    }
  }

  void _handleDragUpdate(DragUpdateDetails details) {
    if (isInteractive) {
      _currentDragValue += details.primaryDelta / _trackLength;
      onChanged(_discretizedCurrentDragValue);
    }
  }

  void _handleDragEnd(DragEndDetails details) {
    if (_active) {
      _active = false;
      _currentDragValue = 0.0;
      _reactionController.reverse();
      markNeedsPaint();
    }
  }

  @override
  bool hitTestSelf(Offset position) => true;

  @override
  void handleEvent(PointerEvent event, BoxHitTestEntry entry) {
    assert(debugHandleEvent(event, entry));
    if (event is PointerDownEvent && isInteractive) _drag.addPointer(event);
  }

  ImageProvider _cachedThumbImage;
  BoxPainter _cachedThumbPainter;

  BoxDecoration _createDefaultThumbDecoration(ImageProvider image) {
    return new BoxDecoration(
        image: image == null ? null : new DecorationImage(image: image),
        shape: BoxShape.circle,
        boxShadow: null);
  }

  bool _isPaintingThumb = false;

  void _handleDecorationChanged() {
    // If the image decoration is available synchronously, we'll get called here
    // during paint. There's no reason to mark ourselves as needing paint if we
    // are already in the middle of painting. (In fact, doing so would trigger
    // an assert).
    if (!_isPaintingThumb) markNeedsPaint();
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    final Canvas canvas = context.canvas;

    final double trackLength = _trackLength;
    final bool enabled = isInteractive;
    final double value = _position.value;

    final double additionalHeightForLabel = _getAdditionalHeightForLabel(label);
    final double trackCenter = offset.dy +
        (size.height - additionalHeightForLabel) / 2.0 +
        additionalHeightForLabel;
    final double trackLeft = offset.dx + _kReactionRadius;
    final double trackTop = trackCenter - 1.0;
    final double trackBottom = trackCenter + 1.0;
    final double trackRight = trackLeft + trackLength;
    final double trackActive = trackLeft + trackLength * value;

    final Paint primaryPaint = new Paint()
      ..color = enabled ? _activeColor : _kInactiveTrackColor;
    final Paint trackPaint = new Paint()
      ..color = _kTrackColorTween.evaluate(_reaction);

    final Offset thumbCenter = new Offset(trackActive, trackCenter);
    double thumbRadius = enabled
        ? _kThumbRadiusTween.evaluate(_reaction)
        : _kDisabledThumbRadius;

    double thumbStrokeWidth = 0.0; // if 0, we fill the thumb circle
    if (thumbImage != null) {
      // Don't fill the circle if you're drawing an image inside
      thumbStrokeWidth = 2.0;
      // Create a bigger circle if you have an image
      thumbRadius += 8.0;
    }
    if (value == 0) {
      // Don't fill the circle if you're drawing an image
      thumbStrokeWidth = 2.0;
      // Make the circle a bit smaller when value == 0.
      thumbRadius -= 1.0;
    }

    if (enabled) {
      final bool hasBalloon =
          _reaction.status != AnimationStatus.dismissed && label != null;
      final double trackActiveDelta = hasBalloon ? 0.0 : thumbRadius - 1.0;
      if (value > 0.0)
        canvas.drawRect(
            new Rect.fromLTRB(trackLeft, trackTop,
                trackActive - trackActiveDelta, trackBottom),
            primaryPaint);
      if (value < 1.0)
        canvas.drawRect(
            new Rect.fromLTRB(trackActive + trackActiveDelta, trackTop,
                trackRight, trackBottom),
            trackPaint);
    } else {
      if (value > 0.0)
        canvas.drawRect(
            new Rect.fromLTRB(trackLeft, trackTop,
                trackActive - thumbRadius - 2, trackBottom),
            trackPaint);
      if (value < 1.0)
        canvas.drawRect(
            new Rect.fromLTRB(trackActive + thumbRadius + 2, trackTop,
                trackRight, trackBottom),
            trackPaint);
    }

    if (_reaction.status != AnimationStatus.dismissed) {
      final int divisions = this.divisions;
      if (divisions != null) {
        const double tickWidth = 2.0;
        final double dx = (trackLength - tickWidth) / divisions;
        // If the ticks would be too dense, don't bother painting them.
        if (dx >= 3 * tickWidth) {
          final Paint tickPaint = new Paint()
            ..color = _kTickColorTween.evaluate(_reaction);
          for (int i = 0; i <= divisions; i += 1) {
            final double left = trackLeft + i * dx;
            canvas.drawRect(
                new Rect.fromLTRB(
                    left, trackTop, left + tickWidth, trackBottom),
                tickPaint);
          }
        }
      }

      if (label != null) {
        final Offset center = new Offset(trackActive,
            _kLabelBalloonCenterTween.evaluate(_reaction) + trackCenter);
        final double radius = _kLabelBalloonRadiusTween.evaluate(_reaction);
        final Offset tip = new Offset(trackActive,
            _kLabelBalloonTipTween.evaluate(_reaction) + trackCenter);
        final double tipAttachment = _kLabelBalloonTipAttachmentRatio * radius;

        Path path = new Path()
          ..moveTo(tip.dx, tip.dy)
          ..lineTo(center.dx - tipAttachment, center.dy + tipAttachment)
          ..lineTo(center.dx + tipAttachment, center.dy + tipAttachment)
          ..close();
        canvas.drawPath(path, primaryPaint);
        _labelPainter.layout();
        Offset labelOffset = new Offset(center.dx - _labelPainter.width / 2.0,
            center.dy - _labelPainter.height / 2.0);
        _labelPainter.paint(canvas, labelOffset);
        return;
      } else {
        // Don't draw a reaction circle if you have an icon
        if (thumbImage == null) {
          final Color reactionBaseColor =
              value == 0.0 ? _kActiveTrackColor : _activeColor;
          final Paint reactionPaint = new Paint()
            ..color = reactionBaseColor.withAlpha(kRadialReactionAlpha);

          canvas.drawCircle(thumbCenter,
              _kReactionRadiusTween.evaluate(_reaction), reactionPaint);
        }
      }
    }

    // Use the neutral color to draw thumb circle
    Paint thumbPaint = trackPaint;

    if (thumbStrokeWidth != 0.0) {
      // Set the style to stroke if we've set a non-zero stroke width
      // This destructive to trackingPaint or primaryPaint
      thumbPaint
        ..style = PaintingStyle.stroke
        ..strokeWidth = thumbStrokeWidth;
    }

    canvas.drawCircle(thumbCenter, thumbRadius, thumbPaint);

    if (thumbImage != null) {
      try {
        _isPaintingThumb = true;
        if (_cachedThumbPainter == null || thumbImage != _cachedThumbImage) {
          _cachedThumbImage = thumbImage;
          _cachedThumbPainter = _createDefaultThumbDecoration(thumbImage)
              .createBoxPainter(_handleDecorationChanged);
        }

        BoxPainter thumbPainter = _cachedThumbPainter;

        double imageRadius = thumbRadius - thumbStrokeWidth;
        thumbPainter.paint(
            canvas,
            thumbCenter - new Offset(imageRadius, imageRadius), // + offset
            configuration.copyWith(size: new Size.fromRadius(imageRadius)));
      } finally {
        _isPaintingThumb = false;
      }
    }
  }
}
