// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:math' as math;

import 'package:flutter/material.dart';

const Color _kDefaultColor = const Color(0xFF6EFAFA);

const double _kInitialFractionalDiameter = 1.0 / 1.2;
const double _kTargetFractionalDiameter = 1.0;
const double _kRotationRadians = 6 * math.pi;
const Curve _kDefaultCurve = const Cubic(0.3, 0.1, 0.3, 0.9);

const Duration _kAnimationDuration = const Duration(seconds: 2);

/// The spinner used by fuchsia flutter apps.
class FuchsiaSpinner extends StatefulWidget {
  /// The color of the spinner at rest
  final Color color;

  /// Constructor.
  FuchsiaSpinner({
    this.color: _kDefaultColor,
  });

  @override
  _FuchsiaSpinnerState createState() => new _FuchsiaSpinnerState();
}

class _FuchsiaSpinnerState extends State<FuchsiaSpinner>
    with SingleTickerProviderStateMixin {
  final Tween<double> _fractionalWidthTween = new Tween<double>(
    begin: _kInitialFractionalDiameter,
    end: _kTargetFractionalDiameter,
  );
  final Tween<double> _fractionalHeightTween = new Tween<double>(
    begin: _kInitialFractionalDiameter,
    end: _kInitialFractionalDiameter / 2,
  );
  final Tween<double> _hueTween = new Tween<double>(
    begin: 0.0,
    end: 90.0,
  );
  final Curve _firstHalfCurve = const Cubic(0.75, 0.25, 0.25, 1.0);
  final Curve _secondHalfCurve = _kDefaultCurve;

  AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = new AnimationController(
      vsync: this,
      duration: _kAnimationDuration,
    );
    _controller.repeat(period: _kAnimationDuration);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => new LayoutBuilder(
        builder: (_, BoxConstraints constraints) {
          double maxDiameter = math.min(
            constraints.maxWidth,
            constraints.maxHeight,
          );
          return new AnimatedBuilder(
            animation: _controller,
            builder: (_, __) {
              double tweenProgress = _tweenValue;
              double width = maxDiameter *
                  _fractionalWidthTween.lerp(
                    tweenProgress,
                  );
              double height = maxDiameter *
                  _fractionalHeightTween.lerp(
                    tweenProgress,
                  );
              return new Transform(
                alignment: FractionalOffset.center,
                transform: new Matrix4.rotationZ(
                  _kDefaultCurve.transform(_controller.value) *
                      _kRotationRadians,
                ),
                child: new Center(
                  child: new Container(
                    width: width,
                    height: height,
                    child: new Material(
                      color: _transformHue(
                        widget.color,
                        _hueTween.lerp(tweenProgress),
                      ),
                      borderRadius: new BorderRadius.circular(width / 2),
                    ),
                  ),
                ),
              );
            },
          );
        },
      );

  double get _tweenValue {
    if (_controller.value <= 0.5) {
      return _firstHalfCurve.transform(_controller.value / 0.5);
    } else {
      return 1.0 - _secondHalfCurve.transform((_controller.value - 0.5) / 0.5);
    }
  }

  /// This performs a hue rotation by [hueDegrees].
  /// See https://beesbuzz.biz/code/hsv_color_transforms.php for information
  /// about the constants used.
  Color _transformHue(Color original, double hueDegrees) {
    double u = math.cos(hueDegrees * math.pi / 180.0);
    double w = math.sin(hueDegrees * math.pi / 180.0);
    return new Color.fromARGB(
      original.alpha,
      ((.299 + .701 * u + .168 * w) * original.red +
              (.587 - .587 * u + .330 * w) * original.green +
              (.114 - .114 * u - .497 * w) * original.blue)
          .round()
          .clamp(0, 255),
      ((.299 - .299 * u - .328 * w) * original.red +
              (.587 + .413 * u + .035 * w) * original.green +
              (.114 - .114 * u + .292 * w) * original.blue)
          .round()
          .clamp(0, 255),
      ((.299 - .3 * u + 1.25 * w) * original.red +
              (.587 - .588 * u - 1.05 * w) * original.green +
              (.114 + .886 * u - .203 * w) * original.blue)
          .round()
          .clamp(0, 255),
    );
  }
}
