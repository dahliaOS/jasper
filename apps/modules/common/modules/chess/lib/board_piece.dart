// Copyright 2017 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

/// A class representing a board piece
// ignore: must_be_immutable
class BoardPiece extends StatelessWidget {
  /// The index at which the board piece located
  int index;

  /// Name of the piece represented as a single character (one of "RNBQKPrnbqkp")
  final String name;

  /// Image of the piece
  Image pieceImage;

  /// Board piece opacity
  double opacity = 1.0;

  /// The previous position of this piece (to be used in undo logic)
  int from;

  /// Indicates whether this piece is selected
  bool selected = false;

  /// Callback to be called when this piece has been moved
  final ValueChanged<Map<String, dynamic>> onMove;

  /// Callback to be called when this piece is being dragged
  final ValueChanged<int> onDragStart;

  /// Creates a new [BoardPiece].
  BoardPiece({
    this.index,
    this.name,
    this.onMove,
    this.onDragStart,
    Key key,
  })
      : super(key: key) {
    String filename;
    // The difference between white and black is capitalization in FEN
    if (name.toUpperCase() == name) {
      filename = 'w${name.toUpperCase()}';
    } else {
      filename = 'b${name.toUpperCase()}';
    }
    this.pieceImage = new Image.asset('assets/$filename.png');
  }

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;
    double height = (min(size.height, size.width) * 0.9) / 8;

    return new Draggable<BoardPiece>(
        data: this,
        child: pieceImage,
        childWhenDragging: new Container(
            child: null,
            decoration: new BoxDecoration(color: Theme.of(context).accentColor
//                border: new Border.all(
//                    color: Colors.cyan[400],
//                    width: 2.0,
//                    ),
                )),
        feedback: new Image(image: this.pieceImage.image, height: height),
        maxSimultaneousDrags: 1,
        onDragStarted: () {
          onDragStart(this.index);
        },
        onDraggableCanceled: (Velocity velocity, Offset offset) {
          onDragStart(null);
        });
  }
}
