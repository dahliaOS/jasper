// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

const double _kBorderWidth = 4.0;
const double _kBorderRadius = 8.0;
const double _kClipRadius = 12.0;

const int _kBlueStartingIndex = 0;
const int _kYellowStartingIndex = 3;

/// The mondrian spinner.  A series of overlapping rectangular elements that
/// rotate.  The parent of this [MondrianSpinner] must have non-infinite bounds.
/// The [MondrianSpinner] will center itself in its parent and have a diameter
/// equal to the minimum dimension.
class MondrianSpinner extends StatefulWidget {
  @override
  _MondrianSpinnerState createState() => new _MondrianSpinnerState();
}

class _MondrianSpinnerState extends State<MondrianSpinner> {
  Timer _timer;
  int _index = 0;
  List<Rect> _positions;

  @override
  void initState() {
    super.initState();
    _timer = new Timer.periodic(
      const Duration(milliseconds: 500),
      (_) => setState(() {
            _index = (_index + 1) % _positions.length;
          }),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    _timer = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => new LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          double diameter = math.min(
            constraints.maxWidth,
            constraints.maxHeight,
          );
          _positions = <Rect>[
            new Rect.fromLTWH(
              0.0,
              0.0,
              diameter / 2.0 + _kBorderWidth / 2.0,
              diameter,
            ),
            new Rect.fromLTWH(
              0.0,
              diameter / 2.0 - _kBorderWidth / 2.0,
              diameter / 2.0 + _kBorderWidth / 2.0,
              diameter / 2.0 + _kBorderWidth / 2.0,
            ),
            new Rect.fromLTWH(
              0.0,
              diameter / 2.0 - _kBorderWidth / 2.0,
              diameter,
              diameter / 2.0 + _kBorderWidth / 2.0,
            ),
            new Rect.fromLTWH(
              diameter / 2.0 - _kBorderWidth / 2.0,
              diameter / 2.0 - _kBorderWidth / 2.0,
              diameter / 2.0 + _kBorderWidth / 2.0,
              diameter / 2.0 + _kBorderWidth / 2.0,
            ),
            new Rect.fromLTWH(
              diameter / 2.0 - _kBorderWidth / 2.0,
              0.0,
              diameter / 2.0 + _kBorderWidth / 2.0,
              diameter,
            ),
            new Rect.fromLTWH(
              diameter / 2.0 - _kBorderWidth / 2.0,
              0.0,
              diameter / 2.0 + _kBorderWidth / 2.0,
              diameter / 2.0 + _kBorderWidth / 2.0,
            ),
            new Rect.fromLTWH(
              0.0,
              0.0,
              diameter,
              diameter / 2.0 + _kBorderWidth / 2.0,
            ),
            new Rect.fromLTWH(
              0.0,
              0.0,
              diameter / 2.0 + _kBorderWidth / 2.0,
              diameter / 2.0 + _kBorderWidth / 2.0,
            ),
          ];

          return new Center(
            child: new Container(
              width: diameter,
              height: diameter,
              decoration: new BoxDecoration(
                color: Colors.black,
                borderRadius: new BorderRadius.circular(_kBorderRadius),
              ),
              foregroundDecoration: new BoxDecoration(
                border: new Border.all(
                  color: Colors.black,
                  width: _kBorderWidth,
                ),
                borderRadius: new BorderRadius.circular(_kBorderRadius),
              ),
              child: new ClipRRect(
                borderRadius: new BorderRadius.circular(_kClipRadius),
                child: new Stack(
                  fit: StackFit.passthrough,
                  children: <Widget>[
                    new Container(
                      margin: const EdgeInsets.all(_kBorderWidth),
                      color: Colors.red[700],
                    ),
                    new AnimatedPositioned(
                      left: _yellowPosition.left,
                      top: _yellowPosition.top,
                      width: _yellowPosition.width,
                      height: _yellowPosition.height,
                      curve: Curves.fastOutSlowIn,
                      duration: const Duration(milliseconds: 250),
                      child: new Container(
                        color: Colors.yellow[700],
                        foregroundDecoration: new BoxDecoration(
                          border: new Border.all(
                            color: Colors.black,
                            width: _kBorderWidth,
                          ),
                        ),
                      ),
                    ),
                    new AnimatedPositioned(
                      left: _bluePosition.left,
                      top: _bluePosition.top,
                      width: _bluePosition.width,
                      height: _bluePosition.height,
                      curve: Curves.fastOutSlowIn,
                      duration: const Duration(milliseconds: 250),
                      child: new Container(
                        color: Colors.blue[700],
                        foregroundDecoration: new BoxDecoration(
                          border: new Border.all(
                            color: Colors.black,
                            width: _kBorderWidth,
                          ),
                        ),
                      ),
                    )
                  ],
                ),
              ),
            ),
          );
        },
      );

  Rect get _bluePosition =>
      _positions[(_index + _kBlueStartingIndex) % _positions.length];
  Rect get _yellowPosition =>
      _positions[(_index + _kYellowStartingIndex) % _positions.length];
}
