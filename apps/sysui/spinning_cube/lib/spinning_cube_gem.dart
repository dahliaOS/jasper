// Copyright 2017 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:meta/meta.dart';
import 'package:vector_math/vector_math_64.dart';

const double _kGemCornerRadius = 16.0;
const double _kGemOpacity = 1.0;
const double _kFaceRotation = math.pi / 2.0;
const double _kPerspectiveFieldOfViewRadians = math.pi / 6.0;
const double _kPerspectiveNearZ = 100.0;
const double _kPerspectiveAspectRatio = 1.0;
const double _kCubeScaleFactor = 50.0;
const double _kCubeAnimationYRotation = 2.0 * math.pi;
const double _kCubeAnimationXRotation = 6.0 * math.pi;

/// Creates a spinning unicolor cube with rounded corners.
class SpinningCubeGem extends StatelessWidget {
  /// Controls the spinning animation.
  final AnimationController controller;

  /// The color of the cube faces.
  final Color color;

  /// Constructor.
  SpinningCubeGem({this.controller, this.color});

  // The six cube faces are:
  //   1. Placed in a stack and rotated and translated into different positions
  //      to form a cube.
  //   2. Manipulated into a perspective view.
  //   3. Rotated based on the animation.
  @override
  Widget build(BuildContext context) => new LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          double gemSize = math.min(
            constraints.maxWidth,
            constraints.maxHeight,
          );
          double faceSize = gemSize;
          double halfFaceSize = faceSize / 2.0;
          double perspectiveFarZ = _kPerspectiveNearZ + (2.0 * faceSize);
          double cubeZ = _kPerspectiveNearZ + faceSize;

          /// We draw the cube with a 3D perspective.  This matrix manipulates the cube
          /// faces into this perspective.
          Matrix4 cubePerspective = new Matrix4.diagonal3Values(
                _kCubeScaleFactor,
                _kCubeScaleFactor,
                _kCubeScaleFactor,
              ) *
              makePerspectiveMatrix(
                _kPerspectiveFieldOfViewRadians,
                _kPerspectiveAspectRatio,
                _kPerspectiveNearZ,
                perspectiveFarZ,
              ) *
              new Matrix4.translationValues(0.0, 0.0, cubeZ);

          return new Opacity(
            opacity: _kGemOpacity,
            child: new AnimatedBuilder(
              animation: controller,
              builder: (BuildContext context, Widget child) => new Stack(
                children: <Widget>[
                  // Right face.
                  _createRoundedCubeFace(
                    faceTranslation: new Matrix4.translationValues(
                      halfFaceSize,
                      0.0,
                      0.0,
                    ),
                    faceRotation: new Matrix4.rotationY(_kFaceRotation),
                    cubePerspective: cubePerspective,
                    gemSize: gemSize,
                  ),
                  // Left face.
                  _createRoundedCubeFace(
                    faceTranslation:
                        new Matrix4.translationValues(-halfFaceSize, 0.0, 0.0),
                    faceRotation: new Matrix4.rotationY(_kFaceRotation),
                    cubePerspective: cubePerspective,
                    gemSize: gemSize,
                  ),
                  // Back face.
                  _createRoundedCubeFace(
                    faceTranslation: new Matrix4.translationValues(
                      0.0,
                      0.0,
                      halfFaceSize,
                    ),
                    cubePerspective: cubePerspective,
                    gemSize: gemSize,
                  ),
                  // Front face.
                  _createRoundedCubeFace(
                    faceTranslation:
                        new Matrix4.translationValues(0.0, 0.0, -halfFaceSize),
                    cubePerspective: cubePerspective,
                    gemSize: gemSize,
                  ),
                  // Bottom face.
                  _createRoundedCubeFace(
                    faceTranslation: new Matrix4.translationValues(
                      0.0,
                      halfFaceSize,
                      0.0,
                    ),
                    faceRotation: new Matrix4.rotationX(_kFaceRotation),
                    cubePerspective: cubePerspective,
                    gemSize: gemSize,
                  ),
                  // Top face.
                  _createRoundedCubeFace(
                    faceTranslation: new Matrix4.translationValues(
                      0.0,
                      -halfFaceSize,
                      0.0,
                    ),
                    faceRotation: new Matrix4.rotationX(_kFaceRotation),
                    cubePerspective: cubePerspective,
                    gemSize: gemSize,
                  ),
                ],
              ),
            ),
          );
        },
      );

  /// Creates a cube face, rotated by [faceRotation] and translated by
  /// [faceTranslation].  The face is then rotated with the rest of the ongoing
  /// cube rotation as specified by [controller],
  /// [_kCubeAnimationXRotation], and [_kCubeAnimationYRotation].
  Widget _createRoundedCubeFace({
    Matrix4 faceTranslation,
    Matrix4 faceRotation,
    @required Matrix4 cubePerspective,
    @required double gemSize,
  }) =>
      new Transform(
        alignment: FractionalOffset.center,
        transform: cubePerspective *
            new Matrix4.rotationY(
              _kCubeAnimationYRotation * controller.value,
            ) *
            new Matrix4.rotationX(
              _kCubeAnimationXRotation * controller.value,
            ) *
            (faceTranslation ?? new Matrix4.identity()) *
            (faceRotation ?? new Matrix4.identity()),
        child: new Container(
          width: gemSize,
          height: gemSize,
          decoration: new BoxDecoration(
            color: color,
            borderRadius: new BorderRadius.circular(_kGemCornerRadius),
          ),
        ),
      );
}
