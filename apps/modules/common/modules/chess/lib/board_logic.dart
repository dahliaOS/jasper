// Copyright 2017 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// import 'board_piece.dart';
import 'helpers.dart';

const String _kStartingFENString =
    'rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1';
const List<String> _kFiles = const <String>[
  'a',
  'b',
  'c',
  'd',
  'e',
  'f',
  'g',
  'h',
];
const List<String> _kRanks = const <String>[
  '1',
  '2',
  '3',
  '4',
  '5',
  '6',
  '7',
  '8',
];
const List<String> _kPieces = const <String>[
  'R',
  'N',
  'B',
  'Q',
  'K',
  'P',
];

enum _PieceColor { white, black }

/// A class representing a chess game
class ChessGame {
  /// Active piece color.
  _PieceColor activeColor;

  /// Description of last move, to allow for undo
  // ignore: unused_field
  Map<String, dynamic> _undo;

  final List<String> _castling = <String>[];

  // ignore: unused_field
  String _enPassentTarget;

  // ignore: unused_field, prefer_final_fields
  int _halfmoveClock;

  // ignore: unused_field, prefer_final_fields
  int _fullmoveClock;

  /// Positions
  Map<int, String> positions = <int, String>{};

  /// Creates a new chess game instance.
  ChessGame() {
    this._parseFen(fenString: _kStartingFENString);
  }

  _PieceColor _colorOf({String piece}) {
    if (piece.toUpperCase() == piece) {
      return _PieceColor.white;
    } else {
      return _PieceColor.black;
    }
  }

  String _kindOf(String piece) {
    print('piece: $piece');
    return piece.toUpperCase();
  }

  /// Returns the list of valid moves from the given piece position.
  List<int> validMoves({int position}) {
    List<int> validPositions = <int>[];
    String thisPiece = positions[position];

    int column = position % 8;
    int row = position ~/ 8;
    int left = column;
    int right = 8 - column - 1;
    int down = row;
    int up = 8 - row - 1;

    switch (_kindOf(thisPiece)) {
      // Bishop
      case 'Q':
        continue bishop;
      bishop:
      case 'B':
        for (int i = 1; i <= left; i++) {
          int testPosition = position + i * 7;
          String occupier = positions[testPosition];
          if (occupier == null) {
            validPositions.add(testPosition);
          } else {
            if (_colorOf(piece: occupier) != _colorOf(piece: thisPiece)) {
              validPositions.add(testPosition);
            }
            break;
          }
        }

        for (int i = 1; i <= right; i++) {
          int testPosition = position + i * 9;
          String occupier = positions[testPosition];
          if (occupier == null) {
            validPositions.add(testPosition);
          } else {
            if (_colorOf(piece: occupier) != _colorOf(piece: thisPiece)) {
              validPositions.add(testPosition);
            }
            break;
          }
        }

        for (int i = 1; i <= right; i++) {
          int testPosition = position - i * 7;
          String occupier = positions[testPosition];

          if (occupier == null) {
            validPositions.add(testPosition);
          } else {
            if (_colorOf(piece: occupier) != _colorOf(piece: thisPiece)) {
              validPositions.add(testPosition);
            }
            break;
          }
        }

        for (int i = 1; i <= left; i++) {
          int testPosition = position - i * 9;
          String occupier = positions[testPosition];
          if (occupier == null) {
            validPositions.add(testPosition);
          } else {
            if (_colorOf(piece: occupier) != _colorOf(piece: thisPiece)) {
              validPositions.add(testPosition);
            }
            break;
          }
        }
        if (_kindOf(thisPiece) == 'Q') {
          continue rook;
        }
        break;
      rook:
      case 'R':
        for (int i = 1; i <= left; i++) {
          int testPosition = position - i;
          String occupier = positions[testPosition];
          if (occupier == null) {
            validPositions.add(testPosition);
          } else {
            if (_colorOf(piece: occupier) != _colorOf(piece: thisPiece)) {
              validPositions.add(testPosition);
            }
            break;
          }
        }
        for (int i = 1; i <= right; i++) {
          int testPosition = position + i;
          String occupier = positions[testPosition];
          if (occupier == null) {
            validPositions.add(testPosition);
          } else {
            if (_colorOf(piece: occupier) != _colorOf(piece: thisPiece)) {
              validPositions.add(testPosition);
            }
            break;
          }
        }
        for (int i = 1; i <= up; i++) {
          int testPosition = position + i * 8;
          String occupier = positions[testPosition];
          if (occupier == null) {
            validPositions.add(testPosition);
          } else {
            if (_colorOf(piece: occupier) != _colorOf(piece: thisPiece)) {
              validPositions.add(testPosition);
            }
            break;
          }
        }
        for (int i = 1; i <= down; i++) {
          int testPosition = position - i * 8;
          String occupier = positions[testPosition];
          if (occupier == null) {
            validPositions.add(testPosition);
          } else {
            if (_colorOf(piece: occupier) != _colorOf(piece: thisPiece)) {
              validPositions.add(testPosition);
            }
            break;
          }
        }
        break;
      case 'N':
        List<int> testPositions = <int>[];
        print('right: $right, left: $left');
        if (left >= 2) {
          testPositions.addAll(<int>[position - 10, position + 6]);
        }
        if (right >= 2) {
          testPositions.addAll(<int>[position + 10, position - 6]);
        }
        if (right >= 1) {
          testPositions.addAll(<int>[position + 17, position - 15]);
        }
        if (left >= 1) {
          testPositions.addAll(<int>[position - 17, position + 15]);
        }
        testPositions.forEach((int position) {
          if (position >= 0 && position < 64) {
            String occupier = positions[position];
            if (occupier == null) {
              validPositions.add(position);
            } else if (_colorOf(piece: occupier) !=
                _colorOf(piece: thisPiece)) {
              validPositions.add(position);
            }
          }
        });
        break;
      case 'P':
        int sign = _colorOf(piece: thisPiece) == _PieceColor.white ? 1 : -1;
        // two-square pawn move
        if (row == 1 || row == 6) {
          int testPosition = position + 16 * sign;
          String occupier = positions[testPosition];
          if (occupier == null) {
            validPositions.add(testPosition);
          }
        }
        // one-square move forward
        int testPosition = position + 8 * sign;
        String occupier = positions[testPosition];
        if (occupier == null) {
          validPositions.add(testPosition);
        }
        // left capture
        testPosition = position + 7 * sign;
        occupier = positions[testPosition];
        if (occupier != null) {
          if (_colorOf(piece: occupier) != _colorOf(piece: thisPiece)) {
            validPositions.add(testPosition);
          }
        }
        // right capture
        testPosition = position + 9 * sign;
        occupier = positions[testPosition];
        if (occupier != null) {
          if (_colorOf(piece: occupier) != _colorOf(piece: thisPiece)) {
            validPositions.add(testPosition);
          }
        }
        // enpassent (right now only from FEN parsing)
        if (_enPassentTarget != '') {
          validPositions.add(_notationToIndex(coord: _enPassentTarget));
        }
        break;
      case 'K':
        List<int> possiblePositions = <int>[-7, -8, -9, -1, 1, 7, 8, 9];
        possiblePositions.forEach((int move) {
          int testPosition = position + move;
          String occupier = positions[testPosition];
          if (occupier == null) {
            validPositions.add(testPosition);
          } else if (_colorOf(piece: occupier) != _colorOf(piece: thisPiece)) {
            validPositions.add(testPosition);
          }
        });
    }
    return validPositions;
  }

  // TODO: Move this to board?
  int _notationToIndex({String coord}) {
    coord.replaceAll(r'!+\++', '');
    if (coord.length > 2) {
      coord = coord.substring(coord.length - 2);
    }
    return _kFiles.indexOf(coord[0]) + 8 * _kRanks.indexOf(coord[1]);
  }

  String _indexToNotation({int index}) {
    print('index: $index');
    int file = index % 8;
    int rank = index ~/ 8 + 1;
    return '${_kFiles[file - 1]}$rank';
  }

  Map<int, String> _parseFenPositionField({String pieceField}) {
    Map<int, String> pieces = <int, String>{};
    List<String> fenRanks = pieceField.split('/');
    if (fenRanks.length != 8) {
      print(
          'error - not enought ranks in parsed positions'); //TODO: make this a log
      return pieces;
    }

    for (int i = 0; i < 8; i++) {
      int file = 1;
      String current = fenRanks[i];
      for (int j = 0; j < current.length; j++) {
        if (isAnInt(current[j])) {
          file += int.parse(current[j]);
        } else {
          String letter = _kFiles[file - 1];
          String number = _kRanks[7 - i];
          pieces[_notationToIndex(coord: '$letter$number')] = current[j];
          file++;
        }
      }
    }
    return pieces;
  }

  void _parseFen({String fenString}) {
    // https://en.wikipedia.org/wiki/Forsyth%E2%80%93Edwards_Notation
    List<String> fields = fenString.split(' ');
    this.positions = _parseFenPositionField(pieceField: fields[0]);
    this.activeColor = fields[1] == 'w' ? _PieceColor.white : _PieceColor.black;
    for (int i = 0; i < fields[2].length; i++) {
      this._castling.add(fields[2][i]);
    }
    if (fields[3] == '-') {
      this._enPassentTarget = '';
    } else {
      this._enPassentTarget = fields[3];
    }
  }

  String _reversePieceSearch({String dest, String piece, String hint}) {
    // brute force this until the vector refactorization of move logic
    print(
        'Looking for $piece moving to ${_notationToIndex(coord: dest)} with hint: $hint');
    List<int> candidates = <int>[];
    List<int> searchSet = <int>[];
    if (hint != null) {
      assert(_kFiles.contains(hint));
      for (int i = _kFiles.indexOf(hint); i < 64; i = i + 8) {
        searchSet.add(i);
      }
    } else {
      searchSet = this.positions.keys.toList();
    }
    searchSet.forEach((int i) {
      if (this.positions[i] == piece) {
        print('valid moves for $i: ${validMoves(position: i)}');
        if (validMoves(position: i).contains(_notationToIndex(coord: dest))) {
          candidates.add(i);
        }
      }
    });
    if (candidates.length > 1) {
      print('Warning! More than one candidate piece found...');
    }
    if (candidates.length == 0) {
      print('Warning! No candidates found!');
    }
    return candidates.isEmpty ? null : _indexToNotation(index: candidates[0]);
  }

  // ignore: unused_element
  List<List<String>> _parsePGNMoves({String pgnMovesString}) {
    // leading whitespace any number of digits followed by a period
    List<String> moveList = pgnMovesString.split(new RegExp(r'\s?\d+\.\s'));

    List<List<String>> movePairs = <List<String>>[];
    int halfMoves = 0;
    this.activeColor = _PieceColor.white;
    for (int i = 1; i < moveList.length; i++) {
      List<String> moves = moveList[i].split(' ');
      print('moves: $moves');
      moves.forEach((String m) {
        print(m);
        String piece, orig, dest = '';
        if (m.contains('x')) {
          // capture!
          List<String> cap = m.split('x');
          orig = cap[0]; // could be anything
          dest = cap[1].replaceAll(r'\++\!+', ''); // clean endings like +, !
          piece = _kPieces.contains(orig[0]) ? orig[0] : 'P';
          orig.replaceAll(r'RNBQKP', '');
          if (orig.length == 1) {
            piece =
                halfMoves % 2 == 0 ? piece.toUpperCase() : piece.toLowerCase();
            orig = _reversePieceSearch(dest: dest, piece: piece, hint: orig);
          }
        }
        if (m.length == 2) {
          // Pawn move e.g. e4
          dest = m;
          piece = halfMoves % 2 == 0 ? 'P' : 'p';
          orig = _reversePieceSearch(dest: dest, piece: piece);
        }
        movePairs.add(<String>[orig, dest]);
        print(halfMoves);
        halfMoves++;
        this.activeColor =
            halfMoves % 2 == 0 ? _PieceColor.white : _PieceColor.black;
      });
    }
    //"Qa6xb7#", "fxg1=Q+"
    print(movePairs);
    return movePairs;
  }

  /// returns the position of pieces in the board model
  Map<int, String> getPositions() {
    return positions;
  }

  /// Request to move a piece from place to place - returns success of move
  bool movePiece({int from, int to}) {
    if (validMoves(position: from).contains(to)) {
      print('valid move');
      String piece = positions[from];
      String captured = positions[to];
      _undo = <String, dynamic>{
        'piece': piece,
        'from': from,
        'to': to,
        'captured': captured,
      };
      positions.remove(from);
      positions[to] = piece;
      return true;
    } else {
      return false;
    }
  }
}
