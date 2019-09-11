// Copyright 2017 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

import 'board_piece.dart';

/// A [Widget] for a board square.
// ignore: must_be_immutable
class BoardSquare extends StatelessWidget {
  // TODO: ColorTween

  /// Board piece on this square.
  ///
  /// Can be null if the board square is empty.
  BoardPiece piece;

  /// Color of the square.
  Color color;

  /// Index at which the square is located in the chess board.
  int index;

  /// Indicates whether this board square is highlighted.
  bool highlight = false;

  /// Callback on tap.
  final ValueChanged<int> onTap;

  /// Creates a new [BoardSquare]
  BoardSquare({
    this.index,
    this.color,
    this.onTap,
    this.piece,
    this.highlight,
    Key key,
  })
      : super(key: key);

  void _handleAccept(BoardPiece piece) {
    piece.onMove(<String, dynamic>{
      'name': piece.name,
      'from': piece.index,
      'to': index,
    });
  }

  @override
  Widget build(BuildContext context) {
    BoxDecoration decoration = new BoxDecoration(color: color
//        border: this.highlight ==null ? null : new Border.all(
//            color: Colors.cyan[400],
//            width: 2.0,
//            ),
        );
    return new DragTarget<BoardPiece>(
        onAccept: _handleAccept,
        builder: (BuildContext context, List<BoardPiece> data,
            List<dynamic> rejected) {
          return new GestureDetector(
              child: new Container(
                  child: new Material(
                      color: this.highlight
                          ? Theme.of(context).accentColor.withAlpha(127)
                          : color,
                      child: piece),
                  decoration: decoration),
              onTap: () {
                onTap(this.index);
              });
//            new Container(
//              child: new Material(
//                color: this.highlight ? Theme.of(context).accentColor.withAlpha(127) : color,
//                child: piece
//              ),
//              decoration: decoration
//          );
//          return new Material(
//              color: new Color(this.hexColor),
//              child: piece
//          );
        });
  }
}
