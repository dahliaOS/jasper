// Copyright 2016 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/widgets.dart';

/// Paints quadrilateral of the specified [color].
///
/// [topLeftInset], [topRightInset], [bottomLeftInset], and [bottomRightInset]
/// specify the quadrilateral defining insets of the four corners of the
/// bounding box.
class QuadrilateralPainter extends CustomPainter {
  /// Defines the inset of the bounding box's top left corner.
  final Offset topLeftInset;

  /// Defines the inset of the bounding box's top right corner.
  final Offset topRightInset;

  /// Defines the inset of the bounding box's bottom left corner.
  final Offset bottomLeftInset;

  /// Defines the inset of the bounding box's bottom right corner.
  final Offset bottomRightInset;

  /// The color to paint.
  final Color color;

  /// Constructor.
  QuadrilateralPainter({
    Offset topLeftInset,
    Offset topRightInset,
    Offset bottomLeftInset,
    Offset bottomRightInset,
    this.color,
  })
      : this.topLeftInset = topLeftInset ?? Offset.zero,
        this.topRightInset = topRightInset ?? Offset.zero,
        this.bottomLeftInset = bottomLeftInset ?? Offset.zero,
        this.bottomRightInset = bottomRightInset ?? Offset.zero {
    assert(this.topLeftInset.dx >= 0.0);
    assert(this.topLeftInset.dy >= 0.0);
    assert(this.topRightInset.dx >= 0.0);
    assert(this.topRightInset.dy >= 0.0);
    assert(this.bottomLeftInset.dx >= 0.0);
    assert(this.bottomLeftInset.dy >= 0.0);
    assert(this.bottomRightInset.dx >= 0.0);
    assert(this.bottomRightInset.dy >= 0.0);
    assert(color != null);
  }

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawPath(
        new Path()
          ..moveTo(topLeftInset.dx, topLeftInset.dy)
          ..lineTo(bottomLeftInset.dx, size.height - bottomLeftInset.dy)
          ..lineTo(size.width - bottomRightInset.dx,
              size.height - bottomRightInset.dy)
          ..lineTo(size.width - topRightInset.dx, topRightInset.dy)
          ..lineTo(topLeftInset.dx, topLeftInset.dy),
        new Paint()..color = color);
  }

  @override
  bool shouldRepaint(QuadrilateralPainter oldPainter) =>
      (oldPainter.topLeftInset != topLeftInset) ||
      (oldPainter.bottomLeftInset != bottomLeftInset) ||
      (oldPainter.bottomRightInset != bottomRightInset) ||
      (oldPainter.topRightInset != topRightInset) ||
      (oldPainter.color != color);

  @override
  bool hitTest(Offset position) => false;
}
