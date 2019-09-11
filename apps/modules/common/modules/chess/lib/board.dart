// Copyright 2017 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

import 'board_logic.dart';
import 'board_piece.dart';
import 'board_square.dart';

//final BoardGridDelegate _boardGridDelegate = new BoardGridDelegate();
final Color _kLightColor = new Color(0xFFE0E0E0);
final Color _kDarkColor = new Color(0xFFFAFAFA);

enum _Player { white, black }

/// Widget representing a chess board.
class Board extends StatefulWidget {
  /// Creates a new [Board].
  Board({Key key}) : super(key: key);

  @override
  _BoardState createState() => new _BoardState();
}

class _BoardState extends State<Board> {
  Map<String, dynamic> undo;
  List<int> highlights = <int>[];
  int pieceSelected;
  bool confirming = false;
  _Player player = _Player.black;
  final _Player _turn = _Player.white;
  ChessGame chessGame;
  Map<int, BoardPiece> positions = <int, BoardPiece>{};

  @override
  void initState() {
    super.initState();
    chessGame = new ChessGame();
    Map<int, String> boardPositions = chessGame.getPositions();
    boardPositions
        .forEach((int index, String piece) => positions[index] = new BoardPiece(
              index: index,
              name: piece,
              onMove: handleMovePiece,
              onDragStart: handleSelectPiece,
            ));
  }

  @override
  void dispose() {
    super.dispose();
  }

  void handleTapSquare(int index) {
    print('index: $index');
    if (pieceSelected == null) {
      if (chessGame.getPositions().containsKey(index)) {
        handleSelectPiece(index);
      }
    } else {
      if (highlights.contains(index)) {
        Map<String, int> move = <String, int>{
          'from': pieceSelected,
          'to': index,
        };
        handleMovePiece(move);
      } else if (chessGame.getPositions().containsKey(index)) {
        handleSelectPiece(index);
      } else {
        clearSelection();
      }
    }
  }

  // Update the visual presentation of board pieces
  void updatePositions() {
    positions.clear();
    Map<int, String> boardPositions = chessGame.getPositions();
    boardPositions
        .forEach((int index, String piece) => positions[index] = new BoardPiece(
              index: index,
              name: piece,
              onMove: handleMovePiece,
              onDragStart: handleSelectPiece,
            ));
  }

  // Highlights the drop targets for the current piece
  void handleSelectPiece(int index) {
    pieceSelected = index;
    List<int> setOfMoves = chessGame.validMoves(position: index);
    setState(() {
      highlights = setOfMoves;
    });
  }

  void clearSelection() {
    pieceSelected = null;
    setState(() {
      highlights = <int>[];
    });
  }

  // Attempt to move the piece
  // If successful highlight the origin and destination of the move
  // Otherwise reset the highlights
  void handleMovePiece(Map<String, int> data) {
    int from = data['from'];
    int to = data['to'];
    bool validMove = chessGame.movePiece(from: from, to: to);
    if (validMove) {
      setState(() {
        highlights = <int>[from, to];
        updatePositions();
      });
      confirmMove();
    } else {
      setState(() {
        highlights = <int>[];
      });
    }
    pieceSelected = null;
  }

  void cancelMove() {
    confirming = false;
    print('cancelled');
    Navigator.pop(context);
    setState(() {
      highlights = <int>[];
      BoardPiece piece = undo['piece'];
      piece.index = undo['from'];
      BoardPiece capture = undo['capture'];
      if (capture != null) {
        capture.index = undo['to'];
        positions[undo['to']] = capture;
      }
      positions[undo['from']] = piece;
      positions.remove(undo['to']);
    });
  }

  void confirmed() {
    confirming = false;
    print('confirmed');
  }

  void confirmMove() {
    confirming = true;
  }

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;
    print(size);
    List<Widget> grids = <Widget>[];
    int index = 0;
    if (player == _Player.white) {
      for (int i = 0; i < 8; i++) {
        for (int j = 0; j < 8; j++) {
          Color colorval = (i % 2 == (j % 2)) ? _kDarkColor : _kLightColor;
          index = ((7 - i) * 8) + j;
          bool highlight = highlights.contains(index);
          grids.add(new BoardSquare(
            index: index,
            color: colorval,
            onTap: this.handleTapSquare,
            piece: this.positions[index],
            highlight: highlight,
          ));
        }
      }
    } else {
      for (int i = 7; i >= 0; i--) {
        for (int j = 7; j >= 0; j--) {
          Color colorval = (i % 2 == (j % 2)) ? _kDarkColor : _kLightColor;
          index = ((7 - i) * 8) + j;
          bool highlight = highlights.contains(index);
          grids.add(new BoardSquare(
              index: index,
              color: colorval,
              onTap: this.handleTapSquare,
              piece: this.positions[index],
              highlight: highlight));
        }
      }
    }
    print('turn: $_turn');
    String turntext = _turn.toString().split('.')[1];
    turntext = turntext[0].toUpperCase() + turntext.substring(1);

    return new Scaffold(
        appBar: new AppBar(title: new Text('$turntext To Move')),
        body: new Container(
            child: new Center(
                child: new Container(
                    constraints: new BoxConstraints(
                        minHeight: min(size.height, size.width) * 0.9,
                        maxHeight: min(size.height, size.width) * 0.9,
                        minWidth: min(size.height, size.width) * 0.9,
                        maxWidth: min(size.height, size.width) * 0.9),
                    child: new GridView.count(
                      crossAxisCount: 8,
                      children: grids,
                    )))));
  }
}
