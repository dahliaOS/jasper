// Copyright 2017 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:qrcodegen/qrcodegen.dart';

const double _kSmoothingThreshold = 2.0;

/// Displays a QR Code.
class QrCodeWidget extends StatefulWidget {
  /// The QR code for the kernel panic info.
  final QrCode qrCode;

  /// Encodes [text] into a QR Code image.
  QrCodeWidget(String text) : qrCode = QrCode.encodeText(text, EccEnum.low);

  @override
  _QrCodeWidgetState createState() => new _QrCodeWidgetState();
}

class _QrCodeWidgetState extends State<QrCodeWidget> {
  double _lastPixelRatio;
  bool _smooth = false;
  Timer _timer;

  @override
  void dispose() {
    super.dispose();
    _timer?.cancel();
  }

  @override
  Widget build(BuildContext context) => new Material(
        color: Colors.white,
        elevation: 4.0,
        borderRadius: new BorderRadius.circular(4.0),
        child: new Container(
          child: new LayoutBuilder(
            builder: (BuildContext context, BoxConstraints constraints) {
              double pixelRatio = ((constraints.biggest.shortestSide) /
                      (widget.qrCode.size + 4))
                  .clamp(
                0.0,
                4.0,
              );
              if (_lastPixelRatio != pixelRatio) {
                _smooth = false;
                _timer?.cancel();
                _timer = null;
                if (pixelRatio >= _kSmoothingThreshold) {
                  _timer = new Timer(const Duration(seconds: 3), () {
                    if (mounted) {
                      setState(() {
                        _smooth = true;
                      });
                    }
                  });
                }
                _lastPixelRatio = pixelRatio;
              }

              return new Container(
                margin: new EdgeInsets.all(pixelRatio * 2.0),
                width: widget.qrCode.size * pixelRatio,
                height: widget.qrCode.size * pixelRatio,
                child: new RepaintBoundary(
                  child: new CustomPaint(
                    painter: pixelRatio >= _kSmoothingThreshold && _smooth
                        ? new _SmoothQrCodePainter(qrCode: widget.qrCode)
                        : new _QrCodePainter(qrCode: widget.qrCode),
                  ),
                ),
              );
            },
          ),
        ),
      );
}

class _QrCodePainter extends CustomPainter {
  final QrCode qrCode;

  _QrCodePainter({this.qrCode});

  @override
  void paint(Canvas canvas, Size size) {
    double pixelSize = size.shortestSide / qrCode.size;
    Paint blackPaint = new Paint()..color = Colors.black;
    for (int x = 0; x < qrCode.size; x++) {
      for (int y = 0; y < qrCode.size; y++) {
        if (qrCode.getModule(x, y) != 0) {
          canvas.drawRect(
            new Rect.fromLTWH(
              x * pixelSize,
              y * pixelSize,
              pixelSize,
              pixelSize,
            ),
            blackPaint,
          );
        }
      }
    }
  }

  @override
  bool shouldRepaint(_QrCodePainter oldDelegate) =>
      oldDelegate.qrCode != qrCode;

  @override
  bool hitTest(Offset position) => false;
}

class _SmoothQrCodePainter extends CustomPainter {
  final QrCode qrCode;

  _SmoothQrCodePainter({this.qrCode});

  @override
  void paint(Canvas canvas, Size size) {
    double pixelSize = size.shortestSide / qrCode.size;
    Paint blackPaint = new Paint()..color = Colors.black;
    for (int x = 0; x < qrCode.size; x++) {
      for (int y = 0; y < qrCode.size; y++) {
        bool isBlack = qrCode.getModule(x, y) != 0;
        bool leftIsBlack = qrCode.getModule(x - 1, y) != 0;
        bool rightIsBlack = qrCode.getModule(x + 1, y) != 0;
        bool aboveIsBlack = qrCode.getModule(x, y - 1) != 0;
        bool belowIsBlack = qrCode.getModule(x, y + 1) != 0;

        if (isBlack) {
          bool topLeftCurved = !aboveIsBlack && !leftIsBlack;
          bool bottomLeftCurved = !belowIsBlack && !leftIsBlack;
          bool topRightCurved = !aboveIsBlack && !rightIsBlack;
          bool bottomRightCurved = !belowIsBlack && !rightIsBlack;
          if (!topLeftCurved &&
              !bottomLeftCurved &&
              !topRightCurved &&
              !bottomRightCurved) {
            canvas.drawRect(
              new Rect.fromLTRB(
                x * pixelSize,
                y * pixelSize,
                (x + 1) * pixelSize,
                (y + 1) * pixelSize,
              ),
              blackPaint,
            );
          } else {
            RRect rrect = new RRect.fromLTRBAndCorners(
              x * pixelSize,
              y * pixelSize,
              (x + 1) * pixelSize,
              (y + 1) * pixelSize,
              topLeft:
                  topLeftCurved ? new Radius.circular(pixelSize) : Radius.zero,
              topRight:
                  topRightCurved ? new Radius.circular(pixelSize) : Radius.zero,
              bottomRight: bottomRightCurved
                  ? new Radius.circular(pixelSize)
                  : Radius.zero,
              bottomLeft: bottomLeftCurved
                  ? new Radius.circular(pixelSize)
                  : Radius.zero,
            );
            canvas.drawRRect(rrect, blackPaint);
          }
        } else {
          bool topLeftCurved = leftIsBlack &&
              aboveIsBlack &&
              qrCode.getModule(x - 1, y - 1) != 0;
          bool bottomLeftCurved = leftIsBlack &&
              belowIsBlack &&
              qrCode.getModule(x - 1, y + 1) != 0;
          bool topRightCurved = rightIsBlack &&
              aboveIsBlack &&
              qrCode.getModule(x + 1, y - 1) != 0;
          bool bottomRightCurved = rightIsBlack &&
              belowIsBlack &&
              qrCode.getModule(x + 1, y + 1) != 0;
          if (topLeftCurved) {
            canvas.drawPath(
              new Path()
                ..moveTo(x * pixelSize, (y + 0.5) * pixelSize)
                ..relativeLineTo(0.0, -(0.5 * pixelSize))
                //..relativeLineTo(0.5 * pixelSize, 0.0)
                ..arcTo(
                  new Rect.fromLTRB(x * pixelSize, y * pixelSize,
                      (x + 1) * pixelSize, (y + 1) * pixelSize),
                  -math.pi / 2.0,
                  -math.pi / 2.0,
                  false,
                ),
              blackPaint,
            );
          }
          if (bottomLeftCurved) {
            canvas.drawPath(
              new Path()
                ..moveTo(x * pixelSize, (y + 0.5) * pixelSize)
                ..relativeLineTo(0.0, (0.5 * pixelSize))
                //..relativeLineTo(0.5 * pixelSize, 0.0)
                ..arcTo(
                  new Rect.fromLTRB(x * pixelSize, y * pixelSize,
                      (x + 1) * pixelSize, (y + 1) * pixelSize),
                  math.pi / 2.0,
                  math.pi / 2.0,
                  false,
                ),
              blackPaint,
            );
          }
          if (topRightCurved) {
            canvas.drawPath(
              new Path()
                ..moveTo((x + 1) * pixelSize, (y + 0.5) * pixelSize)
                ..relativeLineTo(0.0, -(0.5 * pixelSize))
                //..relativeLineTo(0.5 * pixelSize, 0.0)
                ..arcTo(
                  new Rect.fromLTRB(x * pixelSize, y * pixelSize,
                      (x + 1) * pixelSize, (y + 1) * pixelSize),
                  -math.pi / 2.0,
                  math.pi / 2.0,
                  false,
                ),
              blackPaint,
            );
          }
          if (bottomRightCurved) {
            canvas.drawPath(
              new Path()
                ..moveTo((x + 1) * pixelSize, (y + 0.5) * pixelSize)
                ..relativeLineTo(0.0, 0.5 * pixelSize)
                //..relativeLineTo(0.5 * pixelSize, 0.0)
                ..arcTo(
                  new Rect.fromLTRB(x * pixelSize, y * pixelSize,
                      (x + 1) * pixelSize, (y + 1) * pixelSize),
                  math.pi / 2.0,
                  -math.pi / 2.0,
                  false,
                ),
              blackPaint,
            );
          }
        }
      }
    }
  }

  @override
  bool shouldRepaint(_SmoothQrCodePainter oldDelegate) =>
      oldDelegate.qrCode != qrCode;

  @override
  bool hitTest(Offset position) => false;
}
