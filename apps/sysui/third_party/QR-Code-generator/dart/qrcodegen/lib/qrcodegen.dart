/*
 * QR Code generator library (JavaScript)
 *
 * Copyright (c) Project Nayuki. (MIT License)
 * https://www.nayuki.io/page/qr-code-generator-library
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy of
 * this software and associated documentation files (the "Software"), to deal in
 * the Software without restriction, including without limitation the rights to
 * use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of
 * the Software, and to permit persons to whom the Software is furnished to do so,
 * subject to the following conditions:
 * - The above copyright notice and this permission notice shall be included in
 *   all copies or substantial portions of the Software.
 * - The Software is provided "as is", without warranty of any kind, express or
 *   implied, including but not limited to the warranties of merchantability,
 *   fitness for a particular purpose and noninfringement. In no event shall the
 *   authors or copyright holders be liable for any claim, damages or other
 *   liability, whether in an action of contract, tort or otherwise, arising from,
 *   out of or in connection with the Software or the use or other dealings in the
 *   Software.
 */

import 'dart:math' as math;

/*
 * Module "qrcodegen", public members:
 * - Class QrCode:
 *   - Function encodeText(str text, QrCode.Ecc ecl) -> QrCode
 *   - Function encodeBinary(list<byte> data, QrCode.Ecc ecl) -> QrCode
 *   - Function encodeSegments(list<QrSegment> segs, QrCode.Ecc ecl,
 *         int minVersion=1, int maxVersion=40, mask=-1, boostEcl=true) -> QrCode
 *   - Constructor QrCode(QrCode qr, int mask)
 *   - Constructor QrCode(list<int> datacodewords, int mask, int version, QrCode.Ecc ecl)
 *   - Fields int version, size, mask
 *   - Field QrCode.Ecc errorCorrectionLevel
 *   - Method getModule(int x, int y) -> int
 *   - Method drawCanvas(int scale, int border, HTMLCanvasElement canvas) -> void
 *   - Method toSvgString(int border) -> str
 *   - Enum Ecc:
 *     - Constants LOW, MEDIUM, QUARTILE, HIGH
 *     - Field int ordinal
 * - Class QrSegment:
 *   - Function makeBytes(list<int> data) -> QrSegment
 *   - Function makeNumeric(str data) -> QrSegment
 *   - Function makeAlphanumeric(str data) -> QrSegment
 *   - Function makeSegments(str text) -> list<QrSegment>
 *   - Function makeEci(int assignVal) -> QrSegment
 *   - Constructor QrSegment(QrSegment.Mode mode, int numChars, list<int> bitData)
 *   - Field QrSegment.Mode mode
 *   - Field int numChars
 *   - Method getBits() -> list<int>
 *   - Constants RegExp NUMERIC_REGEX, ALPHANUMERIC_REGEX
 *   - Enum Mode:
 *     - Constants NUMERIC, ALPHANUMERIC, BYTE, KANJI, ECI
 */

/*---- QR Code symbol class ----*/

/// A class that represents an immutable square grid of black and white cells for a QR Code symbol,
/// with associated static functions to create a QR Code from user-supplied textual or binary data.
/// This class covers the QR Code model 2 specification, supporting all versions (sizes)
///  from 1 to 40, all 4 error correction levels.
///
///  This constructor can be called in one of two ways:
///  - new QrCode(datacodewords, mask, version, errCorLvl):
///        Creates a new QR Code symbol with the given version number, error correction level, binary data array,
///        and mask number. This is a cumbersome low-level constructor that should not be invoked directly by the user.
///        To go one level up, see the QrCode.encodeSegments() function.
///  - new QrCode(qr, mask):
///        Creates a new QR Code symbol based on the given existing object, but with a potentially different
///        mask pattern. The version, error correction level, codewords, etc. of the newly created object are
///        all identical to the argument object; only the mask may differ.
///  In both cases, mask = -1 is for automatic choice or 0 to 7 for fixed choice.
class QrCode {
  /*---- Read-only instance properties ----*/

  /// This QR Code symbol's version number, which is always between 1 and 40 (inclusive).
  int version;

  /// The width and height of this QR Code symbol, measured in modules.
  /// Always equal to version * 4 + 17, in the range 21 to 177.
  int size;

  /// The error correction level used in this QR Code symbol.
  _Ecc errCorLvl;

  /// The mask pattern used in this QR Code symbol, in the range 0 to 7 (i.e. unsigned 3-bit integer).
  /// Note that even if the constructor was called with automatic masking requested
  /// (mask = -1), the resulting object will still have a mask value between 0 and 7.
  int mask;

  List<List<bool>> _modules;
  List<List<bool>> _isFunction;

  /// Constructor.
  QrCode(dynamic initData, this.mask, this.version, this.errCorLvl) {
    // Check arguments and handle simple scalar fields
    if (mask < -1 || mask > 7) {
      throw new ArgumentError("Mask value out of range");
    }
    if (initData is List) {
      if (version < 1 || version > 40) {
        throw new ArgumentError("Version value out of range");
      }
    } else if (initData is QrCode) {
      if (version != null || errCorLvl != null) {
        throw new ArgumentError("Values must be undefined");
      }
      this.version = initData.version;
      this.errCorLvl = initData.errCorLvl;
    } else {
      throw new ArgumentError("Invalid initial data");
    }
    this.size = version * 4 + 17;

    // Initialize both grids to be size*size arrays of Boolean false
    _modules = new List<List<bool>>.generate(
      size,
      (_) => new List<bool>.filled(size, false),
    );
    _isFunction = new List<List<bool>>.generate(
      size,
      (_) => new List<bool>.filled(size, false),
    );

    // Handle grid fields
    if (initData is List<int>) {
      // Draw function patterns, draw all codewords
      _drawFunctionPatterns();
      _drawCodewords(_appendErrorCorrection(initData));
    } else if (initData is QrCode) {
      for (int y = 0; y < size; y++) {
        for (int x = 0; x < size; x++) {
          _modules[y][x] = initData.getModule(x, y) == 1;
          _isFunction[y][x] = initData.isFunctionModule(x, y);
        }
      }
      _applyMask(initData.mask); // Undo old mask
    } else {
      throw new ArgumentError("Invalid initial data");
    }

    // Handle masking
    if (mask == -1) {
      // Automatically choose best mask
      int minPenalty = 0xFFFFFFFFFFFFFFFF;
      for (int i = 0; i < 8; i++) {
        _drawFormatBits(i);
        _applyMask(i);
        int penalty = _getPenaltyScore();
        if (penalty < minPenalty) {
          mask = i;
          minPenalty = penalty;
        }
        _applyMask(i); // Undoes the mask due to XOR
      }
    }
    assert(mask >= 0 && mask <= 7);
    _drawFormatBits(mask); // Overwrite old format bits
    _applyMask(mask); // Apply the final choice of mask
  }

  /*---- Accessor methods ----*/

  /// (Public) Returns the color of the module (pixel) at the given coordinates, which is either 0 for white or 1 for black. The top
  /// left corner has the coordinates (x=0, y=0). If the given coordinates are out of bounds, then 0 (white) is returned.
  int getModule(int x, int y) {
    if (0 <= x && x < size && 0 <= y && y < size)
      return _modules[y][x] ? 1 : 0;
    else
      return 0; // Infinite white border
  }

  /// (Package-private) Tests whether the module at the given coordinates is a function module (true) or not (false).
  /// The top left corner has the coordinates (x=0, y=0). If the given coordinates are out of bounds, then false is returned.
  /// The JavaScript version of this library has this method because it is impossible to access private variables of another object.
  bool isFunctionModule(int x, int y) {
    if (0 <= x && x < size && 0 <= y && y < size)
      return _isFunction[y][x];
    else
      return false; // Infinite border
  }

  /*---- Private helper methods for constructor: Drawing function modules ----*/

  void _drawFunctionPatterns() {
    // Draw horizontal and vertical timing patterns
    for (int i = 0; i < size; i++) {
      _setFunctionModule(6, i, i % 2 == 0);
      _setFunctionModule(i, 6, i % 2 == 0);
    }

    // Draw 3 finder patterns (all corners except bottom right; overwrites some timing modules)
    _drawFinderPattern(3, 3);
    _drawFinderPattern(size - 4, 3);
    _drawFinderPattern(3, size - 4);

    // Draw numerous alignment patterns
    List<int> alignPatPos = _getAlignmentPatternPositions(version);
    int numAlign = alignPatPos.length;
    for (int i = 0; i < numAlign; i++) {
      for (int j = 0; j < numAlign; j++) {
        if (i == 0 && j == 0 ||
            i == 0 && j == numAlign - 1 ||
            i == numAlign - 1 && j == 0)
          continue; // Skip the three finder corners
        else
          _drawAlignmentPattern(alignPatPos[i], alignPatPos[j]);
      }
    }

    // Draw configuration data
    _drawFormatBits(
        0); // Dummy mask value; overwritten later in the constructor
    _drawVersion();
  }

  // Draws two copies of the format bits (with its own error correction code)
  // based on the given mask and this object's error correction level field.
  void _drawFormatBits(int mask) {
    // Calculate error correction code and pack bits
    int data =
        errCorLvl.formatBits << 3 | mask; // errCorrLvl is uint2, mask is uint3
    int rem = data;
    for (int i = 0; i < 10; i++) {
      rem = (rem << 1) ^ ((rem >> 9) * 0x537);
    }
    data = data << 10 | rem;
    data ^= 0x5412; // uint15
    assert(data >> 15 == 0);

    // Draw first copy
    for (int i = 0; i <= 5; i++) {
      _setFunctionModule(8, i, ((data >> i) & 1) != 0);
    }
    _setFunctionModule(8, 7, ((data >> 6) & 1) != 0);
    _setFunctionModule(8, 8, ((data >> 7) & 1) != 0);
    _setFunctionModule(7, 8, ((data >> 8) & 1) != 0);
    for (int i = 9; i < 15; i++) {
      _setFunctionModule(14 - i, 8, ((data >> i) & 1) != 0);
    }

    // Draw second copy
    for (int i = 0; i <= 7; i++) {
      _setFunctionModule(size - 1 - i, 8, ((data >> i) & 1) != 0);
    }
    for (int i = 8; i < 15; i++) {
      _setFunctionModule(8, size - 15 + i, ((data >> i) & 1) != 0);
    }
    _setFunctionModule(8, size - 8, true);
  }

  // Draws two copies of the version bits (with its own error correction code),
  // based on this object's version field (which only has an effect for 7 <= version <= 40).
  void _drawVersion() {
    if (version < 7) return;

    // Calculate error correction code and pack bits
    int rem = version; // version is uint6, in the range [7, 40]
    for (int i = 0; i < 12; i++) rem = (rem << 1) ^ ((rem >> 11) * 0x1F25);
    int data = version << 12 | rem; // uint18
    assert(data >> 18 == 0);

    // Draw two copies
    for (int i = 0; i < 18; i++) {
      bool bit = ((data >> i) & 1) != 0;
      int a = size - 11 + i % 3, b = (i / 3).floor();
      _setFunctionModule(a, b, bit);
      _setFunctionModule(b, a, bit);
    }
  }

  // Draws a 9*9 finder pattern including the border separator, with the center module at (x, y).
  void _drawFinderPattern(int x, int y) {
    for (int i = -4; i <= 4; i++) {
      for (int j = -4; j <= 4; j++) {
        int dist = math.max(i.abs(), j.abs()); // Chebyshev/infinity norm
        int xx = x + j, yy = y + i;
        if (0 <= xx && xx < size && 0 <= yy && yy < size) {
          _setFunctionModule(xx, yy, dist != 2 && dist != 4);
        }
      }
    }
  }

  // Draws a 5*5 alignment pattern, with the center module at (x, y).
  void _drawAlignmentPattern(int x, int y) {
    for (int i = -2; i <= 2; i++) {
      for (int j = -2; j <= 2; j++) {
        _setFunctionModule(x + j, y + i, math.max(i.abs(), j.abs()) != 1);
      }
    }
  }

  // Sets the color of a module and marks it as a function module.
  // Only used by the constructor. Coordinates must be in range.
  void _setFunctionModule(int x, int y, bool isBlack) {
    _modules[y][x] = isBlack;
    _isFunction[y][x] = true;
  }

  /*---- Private helper methods for constructor: Codewords and masking ----*/

  // Returns a new byte string representing the given data with the appropriate error correction
  // codewords appended to it, based on this object's version and error correction level.
  List<int> _appendErrorCorrection(List<int> data) {
    assert(data.length == QrCode._getNumDataCodewords(version, errCorLvl));

    // Calculate parameter numbers
    int numBlocks = _kNumErrorCorrectionBlocks[errCorLvl.ordinal][version];
    int blockEccLen = _kEccCodewordsPerBlock[errCorLvl.ordinal][version];
    int rawCodewords = (_getNumRawDataModules(version) / 8).floor();
    int numShortBlocks = numBlocks - rawCodewords % numBlocks;
    int shortBlockLen = (rawCodewords / numBlocks).floor();

    // Split data into blocks and append ECC to each block
    List<List<int>> blocks = <List<int>>[];
    _ReedSolomonGenerator rs = new _ReedSolomonGenerator(blockEccLen);
    for (int i = 0, k = 0; i < numBlocks; i++) {
      List<int> dat = data.sublist(
          k, k + shortBlockLen - blockEccLen + (i < numShortBlocks ? 0 : 1));
      k += dat.length;
      List<int> ecc = rs.getRemainder(dat);
      if (i < numShortBlocks) dat.add(0);
      ecc.forEach((int b) {
        dat.add(b);
      });
      blocks.add(dat);
    }

    // Interleave (not concatenate) the bytes from every block into a single sequence
    List<int> result = <int>[];
    for (int i = 0; i < blocks[0].length; i++) {
      for (int j = 0; j < blocks.length; j++) {
        // Skip the padding byte in short blocks
        if (i != shortBlockLen - blockEccLen || j >= numShortBlocks)
          result.add(blocks[j][i]);
      }
    }
    assert(result.length == rawCodewords);
    return result;
  }

  // Draws the given sequence of 8-bit codewords (data and error correction) onto the entire
  // data area of this QR Code symbol. Function modules need to be marked off before this is called.
  void _drawCodewords(List<int> data) {
    if (data.length != (_getNumRawDataModules(version) / 8).floor()) {
      throw new ArgumentError("Invalid argument");
    }
    int i = 0; // Bit index into the data
    // Do the funny zigzag scan
    for (int right = size - 1; right >= 1; right -= 2) {
      // Index of right column in each column pair
      if (right == 6) right = 5;
      for (int vert = 0; vert < size; vert++) {
        // Vertical counter
        for (int j = 0; j < 2; j++) {
          int x = right - j; // Actual x coordinate
          bool upward = ((right + 1) & 2) == 0;
          int y = upward ? size - 1 - vert : vert; // Actual y coordinate
          if (!_isFunction[y][x] && i < data.length * 8) {
            _modules[y][x] = ((data[i >> 3] >> (7 - (i & 7))) & 1) != 0;
            i++;
          }
          // If there are any remainder bits (0 to 7), they are already
          // set to 0/false/white when the grid of modules was initialized
        }
      }
    }
    assert(i == data.length * 8);
  }

  // XORs the data modules in this QR Code with the given mask pattern. Due to XOR's mathematical
  // properties, calling applyMask(m) twice with the same value is equivalent to no change at all.
  // This means it is possible to apply a mask, undo it, and try another mask. Note that a final
  // well-formed QR Code symbol needs exactly one mask applied (not zero, not two, etc.).
  void _applyMask(int mask) {
    if (mask < 0 || mask > 7) {
      throw new ArgumentError("Mask value out of range");
    }
    for (int y = 0; y < size; y++) {
      for (int x = 0; x < size; x++) {
        bool invert;
        switch (mask) {
          case 0:
            invert = (x + y) % 2 == 0;
            break;
          case 1:
            invert = y % 2 == 0;
            break;
          case 2:
            invert = x % 3 == 0;
            break;
          case 3:
            invert = (x + y) % 3 == 0;
            break;
          case 4:
            invert = ((x / 3).floor() + (y / 2).floor()) % 2 == 0;
            break;
          case 5:
            invert = x * y % 2 + x * y % 3 == 0;
            break;
          case 6:
            invert = (x * y % 2 + x * y % 3) % 2 == 0;
            break;
          case 7:
            invert = ((x + y) % 2 + x * y % 3) % 2 == 0;
            break;
          default:
            assert(false);
        }
        _modules[y][x] = !(_modules[y][x] == (invert && !_isFunction[y][x]));
      }
    }
  }

  // Calculates and returns the penalty score based on state of this QR Code's current modules.
  // This is used by the automatic mask choice algorithm to find the mask pattern that yields the lowest score.
  int _getPenaltyScore() {
    int result = 0;

    // Adjacent modules in row having same color
    for (int y = 0; y < size; y++) {
      bool colorX = false;
      for (int x = 0, runX; x < size; x++) {
        if (x == 0 || _modules[y][x] != colorX) {
          colorX = _modules[y][x];
          runX = 1;
        } else {
          runX++;
          if (runX == 5)
            result += _kPenaltyN1;
          else if (runX > 5) result++;
        }
      }
    }
    // Adjacent modules in column having same color
    for (int x = 0; x < size; x++) {
      bool colorY = false;
      for (int y = 0, runY; y < size; y++) {
        if (y == 0 || _modules[y][x] != colorY) {
          colorY = _modules[y][x];
          runY = 1;
        } else {
          runY++;
          if (runY == 5)
            result += _kPenaltyN1;
          else if (runY > 5) result++;
        }
      }
    }

    // 2*2 blocks of modules having same color
    for (int y = 0; y < size - 1; y++) {
      for (int x = 0; x < size - 1; x++) {
        bool color = _modules[y][x];
        if (color == _modules[y][x + 1] &&
            color == _modules[y + 1][x] &&
            color == _modules[y + 1][x + 1]) result += _kPenaltyN2;
      }
    }

    // Finder-like pattern in rows
    for (int y = 0; y < size; y++) {
      for (int x = 0, bits = 0; x < size; x++) {
        bits = ((bits << 1) & 0x7FF) | (_modules[y][x] ? 1 : 0);
        if (x >= 10 &&
            (bits == 0x05D || bits == 0x5D0)) // Needs 11 bits accumulated
          result += _kPenaltyN3;
      }
    }
    // Finder-like pattern in columns
    for (int x = 0; x < size; x++) {
      for (int y = 0, bits = 0; y < size; y++) {
        bits = ((bits << 1) & 0x7FF) | (_modules[y][x] ? 1 : 0);
        if (y >= 10 &&
            (bits == 0x05D || bits == 0x5D0)) // Needs 11 bits accumulated
          result += _kPenaltyN3;
      }
    }

    // Balance of black and white modules
    int black = 0;
    _modules.forEach((List<bool> row) {
      row.forEach((bool color) {
        if (color) {
          black++;
        }
      });
    });
    int total = size * size;
    // Find smallest k such that (45-5k)% <= dark/total <= (55+5k)%
    for (int k = 0;
        black * 20 < (9 - k) * total || black * 20 > (11 + k) * total;
        k++) {
      result += _kPenaltyN4;
    }
    return result;
  }

  /*---- Public static factory functions for QrCode ----*/

  /// Returns a QR Code symbol representing the given Unicode text string at the given error correction level.
  /// As a conservative upper bound, this function is guaranteed to succeed for strings that have 738 or fewer Unicode
  /// code points (not UTF-16 code units). The smallest possible QR Code version is automatically chosen for the output.
  /// The ECC level of the result may be higher than the ecl argument if it can be done without increasing the version.
  static QrCode encodeText(String text, EccEnum ecl) => _encodeSegments(
        segs: _QrSegment.makeSegments(text),
        initialEcl: _kEcc[ecl],
      );

  /// Returns a QR Code symbol representing the given binary data string at the given error correction level.
  /// This function always encodes using the binary segment mode, not any text mode. The maximum number of
  /// bytes allowed is 2953. The smallest possible QR Code version is automatically chosen for the output.
  /// The ECC level of the result may be higher than the ecl argument if it can be done without increasing the version.
  static QrCode encodeBinary(List<int> data, EccEnum ecl) => _encodeSegments(
        segs: <_QrSegment>[new _QrSegment.makeBytes(data)],
        initialEcl: _kEcc[ecl],
      );

  /// Returns a QR Code symbol representing the given data segments with the given encoding parameters.
  /// The smallest possible QR Code version within the given range is automatically chosen for the output.
  /// This function allows the user to create a custom sequence of segments that switches
  /// between modes (such as alphanumeric and binary) to encode text more efficiently.
  /// This function is considered to be lower level than simply encoding text or binary data.
  static QrCode _encodeSegments(
      {List<_QrSegment> segs,
      _Ecc initialEcl,
      int minVersion: 1,
      int maxVersion: 40,
      int mask: -1,
      bool boostEcl: true}) {
    if (!(1 <= minVersion && minVersion <= maxVersion && maxVersion <= 40) ||
        mask < -1 ||
        mask > 7) {
      throw new ArgumentError("Invalid value");
    }

    _Ecc ecl = initialEcl;

    // Find the minimal version number to use
    int version;
    int dataUsedBits;
    for (version = minVersion;; version++) {
      // Number of data bits available
      int dataCapacityBits = _getNumDataCodewords(version, ecl) * 8;
      dataUsedBits = _QrSegment.getTotalBits(segs, version);
      if (dataUsedBits != null && dataUsedBits <= dataCapacityBits) {
        break; // This version number is found to be suitable
      }
      if (version >= maxVersion) {
        // All versions in the range could not fit the given data
        throw new ArgumentError("Data too long");
      }
    }

    // Increase the error correction level while the data still fits in the current version number
    <_Ecc>[_kEcc[EccEnum.medium], _kEcc[EccEnum.quartile], _kEcc[EccEnum.high]]
        .forEach((_Ecc newEcl) {
      if (boostEcl &&
          dataUsedBits <= _getNumDataCodewords(version, newEcl) * 8) {
        ecl = newEcl;
      }
    });

    // Create the data bit string by concatenating all segments
    int dataCapacityBits = _getNumDataCodewords(version, ecl) * 8;
    _BitBuffer bb = new _BitBuffer();
    segs.forEach((_QrSegment seg) {
      bb.appendBits(seg.mode.modeBits, 4);
      bb.appendBits(seg.numChars, seg.mode.numCharCountBits(version));
      bb.appendData(seg);
    });

    // Add terminator and pad up to a byte if applicable
    bb.appendBits(0, math.min(4, dataCapacityBits - bb.bitLength));
    bb.appendBits(0, (8 - bb.bitLength % 8) % 8);

    // Pad with alternate bytes until data capacity is reached
    for (int padByte = 0xEC;
        bb.bitLength < dataCapacityBits;
        padByte ^= 0xEC ^ 0x11) {
      bb.appendBits(padByte, 8);
    }
    assert(bb.bitLength % 8 == 0);

    // Create the QR Code symbol
    return new QrCode(bb.bytes, mask, version, ecl);
  }

  /*---- Private static helper functions QrCode ----*/

  // Returns a sequence of positions of the alignment patterns in ascending order. These positions are
  // used on both the x and y axes. Each value in the resulting sequence is in the range [0, 177).
  // This stateless pure function could be implemented as table of 40 variable-length lists of integers.
  static List<int> _getAlignmentPatternPositions(int ver) {
    if (ver != null && (ver < 1 || ver > 40))
      throw new ArgumentError("Version number out of range");
    else if (ver == 1)
      return <int>[];
    else {
      int size = ver * 4 + 17;
      int numAlign = (ver / 7).floor() + 2;
      int step;
      if (ver != 32)
        step = ((size - 13) / (2 * numAlign - 2)).ceil() * 2;
      else // C-C-C-Combo breaker!
        step = 26;

      List<int> result = <int>[6];
      for (int i = 0, pos = size - 7; i < numAlign - 1; i++, pos -= step) {
        result.insert(1, pos);
      }
      return result;
    }
  }

  // Returns the number of data bits that can be stored in a QR Code of the given version number, after
  // all function modules are excluded. This includes remainder bits, so it might not be a multiple of 8.
  // The result is in the range [208, 29648]. This could be implemented as a 40-entry lookup table.
  static int _getNumRawDataModules(int ver) {
    if (ver < 1 || ver > 40)
      throw new ArgumentError("Version number out of range");
    int result = (16 * ver + 128) * ver + 64;
    if (ver >= 2) {
      int numAlign = (ver / 7).floor() + 2;
      result -= (25 * numAlign - 10) * numAlign - 55;
      if (ver >= 7) result -= 18 * 2; // Subtract version information
    }
    return result;
  }

  // Returns the number of 8-bit data (i.e. not error correction) codewords contained in any
  // QR Code of the given version number and error correction level, with remainder bits discarded.
  // This stateless pure function could be implemented as a (40*4)-cell lookup table.
  static int _getNumDataCodewords(int ver, _Ecc ecl) {
    if (ver < 1 || ver > 40)
      throw new ArgumentError("Version number out of range");
    return (_getNumRawDataModules(ver) / 8).floor() -
        _kEccCodewordsPerBlock[ecl.ordinal][ver] *
            QrCode._kNumErrorCorrectionBlocks[ecl.ordinal][ver];
  }

  /*---- Private tables of constants for QrCode ----*/

  // For use in getPenaltyScore(), when evaluating which mask is best.
  static final int _kPenaltyN1 = 3;
  static final int _kPenaltyN2 = 3;
  static final int _kPenaltyN3 = 40;
  static final int _kPenaltyN4 = 10;

  static final List<List<int>> _kEccCodewordsPerBlock = <List<int>>[
    // Version: (note that index 0 is for padding, and is set to an illegal value)
    //  0,  1,  2,  3,  4,  5,  6,  7,  8,  9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36, 37, 38, 39, 40    Error correction level
    <int>[
      null,
      7,
      10,
      15,
      20,
      26,
      18,
      20,
      24,
      30,
      18,
      20,
      24,
      26,
      30,
      22,
      24,
      28,
      30,
      28,
      28,
      28,
      28,
      30,
      30,
      26,
      28,
      30,
      30,
      30,
      30,
      30,
      30,
      30,
      30,
      30,
      30,
      30,
      30,
      30,
      30
    ], // Low
    <int>[
      null,
      10,
      16,
      26,
      18,
      24,
      16,
      18,
      22,
      22,
      26,
      30,
      22,
      22,
      24,
      24,
      28,
      28,
      26,
      26,
      26,
      26,
      28,
      28,
      28,
      28,
      28,
      28,
      28,
      28,
      28,
      28,
      28,
      28,
      28,
      28,
      28,
      28,
      28,
      28,
      28
    ], // Medium
    <int>[
      null,
      13,
      22,
      18,
      26,
      18,
      24,
      18,
      22,
      20,
      24,
      28,
      26,
      24,
      20,
      30,
      24,
      28,
      28,
      26,
      30,
      28,
      30,
      30,
      30,
      30,
      28,
      30,
      30,
      30,
      30,
      30,
      30,
      30,
      30,
      30,
      30,
      30,
      30,
      30,
      30
    ], // Quartile
    <int>[
      null,
      17,
      28,
      22,
      16,
      22,
      28,
      26,
      26,
      24,
      28,
      24,
      28,
      22,
      24,
      24,
      30,
      28,
      28,
      26,
      28,
      30,
      24,
      30,
      30,
      30,
      30,
      30,
      30,
      30,
      30,
      30,
      30,
      30,
      30,
      30,
      30,
      30,
      30,
      30,
      30
    ], // High
  ];

  static final List<List<int>> _kNumErrorCorrectionBlocks = <List<int>>[
    // Version: (note that index 0 is for padding, and is set to an illegal value)
    //  0, 1, 2, 3, 4, 5, 6, 7, 8, 9,10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36, 37, 38, 39, 40    Error correction level
    <int>[
      null,
      1,
      1,
      1,
      1,
      1,
      2,
      2,
      2,
      2,
      4,
      4,
      4,
      4,
      4,
      6,
      6,
      6,
      6,
      7,
      8,
      8,
      9,
      9,
      10,
      12,
      12,
      12,
      13,
      14,
      15,
      16,
      17,
      18,
      19,
      19,
      20,
      21,
      22,
      24,
      25
    ], // Low
    <int>[
      null,
      1,
      1,
      1,
      2,
      2,
      4,
      4,
      4,
      5,
      5,
      5,
      8,
      9,
      9,
      10,
      10,
      11,
      13,
      14,
      16,
      17,
      17,
      18,
      20,
      21,
      23,
      25,
      26,
      28,
      29,
      31,
      33,
      35,
      37,
      38,
      40,
      43,
      45,
      47,
      49
    ], // Medium
    <int>[
      null,
      1,
      1,
      2,
      2,
      4,
      4,
      6,
      6,
      8,
      8,
      8,
      10,
      12,
      16,
      12,
      17,
      16,
      18,
      21,
      20,
      23,
      23,
      25,
      27,
      29,
      34,
      34,
      35,
      38,
      40,
      43,
      45,
      48,
      51,
      53,
      56,
      59,
      62,
      65,
      68
    ], // Quartile
    <int>[
      null,
      1,
      1,
      2,
      4,
      4,
      4,
      5,
      6,
      8,
      8,
      11,
      11,
      16,
      16,
      18,
      16,
      19,
      21,
      25,
      25,
      25,
      34,
      30,
      32,
      35,
      37,
      40,
      42,
      45,
      48,
      51,
      54,
      57,
      60,
      63,
      66,
      70,
      74,
      77,
      81
    ], // High
  ];

  /*---- Public helper enumeration ----*/

  /*
	 * Represents the error correction level used in a QR Code symbol.
	 */
  static final Map<EccEnum, _Ecc> _kEcc = <EccEnum, _Ecc>{
    // Constants declared in ascending order of error protection
    EccEnum.low: new _Ecc(0, 1),
    EccEnum.medium: new _Ecc(1, 0),
    EccEnum.quartile: new _Ecc(2, 3),
    EccEnum.high: new _Ecc(3, 2),
  };
}

/// Represents the error correction level used in a QR Code symbol.
enum EccEnum {
  /// Corresponds to a data restoration rate of about 7%.
  low,

  /// Corresponds to a data restoration rate of about 15%.
  medium,

  /// Corresponds to a data restoration rate of about 25%.
  quartile,

  /// Corresponds to a data restoration rate of about 30%.
  high,
}

class _Ecc {
  // (Public) In the range 0 to 3 (unsigned 2-bit integer)
  final int ordinal;
  // (Package-private) In the range 0 to 3 (unsigned 2-bit integer)
  final int formatBits;
  _Ecc(this.ordinal, this.formatBits);
}

/*---- Data segment class ----*/
/*
 * A public class that represents a character string to be encoded in a QR Code symbol.
 * Each segment has a mode, and a sequence of characters that is already encoded as
 * a sequence of bits. Instances of this class are immutable.
 * This segment class imposes no length restrictions, but QR Codes have restrictions.
 * Even in the most favorable conditions, a QR Code can only hold 7089 characters of data.
 * Any segment longer than this is meaningless for the purpose of generating QR Codes.
 */
class _QrSegment {
  // The mode indicator for this segment.
  final _Mode mode;
  // The length of this segment's unencoded data, measured in characters. Always zero or positive.
  final int numChars;
  final List<int> bitData;

  _QrSegment(this.mode, this.numChars, this.bitData) {
    if (numChars < 0) throw new ArgumentError("Invalid argument");
  }

  /*---- Public static factory functions for QrSegment ----*/

  /// Returns a segment representing the given binary data encoded in byte mode.
  factory _QrSegment.makeBytes(List<int> data) {
    _BitBuffer bb = new _BitBuffer();
    data.forEach((int b) {
      bb.appendBits(b, 8);
    });
    return new _QrSegment(kMode[_ModeEnum.byte], data.length, bb.bits);
  }

  /// Returns a segment representing the given string of decimal digits encoded in numeric mode.
  factory _QrSegment.makeNumeric(String digits) {
    if (!digits.contains(kNumericRegEx))
      throw new ArgumentError("String contains non-numeric characters");
    _BitBuffer bb = new _BitBuffer();
    int i;
    for (i = 0; i + 3 <= digits.length; i += 3) // Process groups of 3
      bb.appendBits(int.parse(digits.substring(i, 3), radix: 10), 10);
    int rem = digits.length - i;
    if (rem > 0) // 1 or 2 digits remaining
      bb.appendBits(int.parse(digits.substring(i), radix: 10), rem * 3 + 1);
    return new _QrSegment(kMode[_ModeEnum.numeric], digits.length, bb.bits);
  }

  /// Returns a segment representing the given text string encoded in alphanumeric mode. The characters allowed are:
  /// 0 to 9, A to Z (uppercase only), space, dollar, percent, asterisk, plus, hyphen, period, slash, colon.
  factory _QrSegment.makeAlphanumeric(String text) {
    if (!text.contains(kAlphanumericRegex))
      throw new ArgumentError(
          "String contains unencodable characters in alphanumeric mode");
    _BitBuffer bb = new _BitBuffer();
    int i;
    for (i = 0; i + 2 <= text.length; i += 2) {
      // Process groups of 2
      int temp = kAlphanumericCharset.indexOf(text[i]) * 45;
      temp += kAlphanumericCharset.indexOf(text[i + 1]);
      bb.appendBits(temp, 11);
    }
    if (i < text.length) // 1 character remaining
      bb.appendBits(kAlphanumericCharset.indexOf(text[i]), 6);
    return new _QrSegment(kMode[_ModeEnum.alphanumeric], text.length, bb.bits);
  }

  /// Returns a segment representing an Extended Channel Interpretation (ECI) designator with the given assignment value.
  factory _QrSegment.makeEci(int assignVal) {
    _BitBuffer bb = new _BitBuffer();
    if (0 <= assignVal && assignVal < (1 << 7))
      bb.appendBits(assignVal, 8);
    else if ((1 << 7) <= assignVal && assignVal < (1 << 14)) {
      bb.appendBits(2, 2);
      bb.appendBits(assignVal, 14);
    } else if ((1 << 14) <= assignVal && assignVal < 999999) {
      bb.appendBits(6, 3);
      bb.appendBits(assignVal, 21);
    } else
      throw new ArgumentError("ECI assignment value out of range");
    return new _QrSegment(kMode[_ModeEnum.eci], 0, bb.bits);
  }

  // Returns a copy of all bits, which is an array of 0s and 1s.
  List<int> get bits => new List<int>.from(bitData);

  /*
		 * Returns a new mutable list of zero or more segments to represent the given Unicode text string.
		 * The result may use various segment modes and switch modes to optimize the length of the bit stream.
		 */
  static List<_QrSegment> makeSegments(String text) {
    // Select the most efficient segment encoding automatically
    if (text == "")
      return <_QrSegment>[];
    else if (text.contains(kNumericRegEx))
      return <_QrSegment>[new _QrSegment.makeNumeric(text)];
    else if (text.contains(kAlphanumericRegex))
      return <_QrSegment>[new _QrSegment.makeAlphanumeric(text)];
    else
      return <_QrSegment>[new _QrSegment.makeBytes(_toUtf8ByteArray(text))];
  }

  // Package-private helper function.
  static int getTotalBits(List<_QrSegment> segs, int version) {
    if (version < 1 || version > 40)
      throw new ArgumentError("Version number out of range");
    int result = 0;
    for (int i = 0; i < segs.length; i++) {
      _QrSegment seg = segs[i];
      int ccbits = seg.mode.numCharCountBits(version);
      // Fail if segment length value doesn't fit in the length field's bit-width
      if (seg.numChars >= (1 << ccbits)) return null;
      result += 4 + ccbits + seg.bits.length;
    }
    return result;
  }

/*---- Constants for QrSegment ----*/

// (Public) Can test whether a string is encodable in numeric mode (such as by using QrSegment.makeNumeric()).
  static final RegExp kNumericRegEx = new RegExp(r'/^[0-9]*\$/');

// (Public) Can test whether a string is encodable in alphanumeric mode (such as by using QrSegment.makeAlphanumeric()).
  static final RegExp kAlphanumericRegex =
      new RegExp('r/^[A-Z0-9 \$%*+.\/:-]*\$/');

// (Private) The set of all legal characters in alphanumeric mode, where each character value maps to the index in the string.
  static final String kAlphanumericCharset =
      '0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ \$%*+-./:';

/*---- Public helper enumeration ----*/

/*
 * Represents the mode field of a segment. Immutable.
 */
  static final Map<_ModeEnum, _Mode> kMode = <_ModeEnum, _Mode>{
    // Constants
    _ModeEnum.numeric: new _Mode(0x1, <int>[10, 12, 14]),
    _ModeEnum.alphanumeric: new _Mode(0x2, <int>[9, 11, 13]),
    _ModeEnum.byte: new _Mode(0x4, <int>[8, 16, 16]),
    _ModeEnum.kanji: new _Mode(0x8, <int>[8, 10, 12]),
    _ModeEnum.eci: new _Mode(0x7, <int>[0, 0, 0]),
  };
}

enum _ModeEnum {
  numeric,
  alphanumeric,
  byte,
  kanji,
  eci,
}

typedef int _NumCharCountBits(int ver);

// Private constructor.
class _Mode {
  _NumCharCountBits numCharCountBits;

  // (Package-private) An unsigned 4-bit integer value (range 0 to 15) representing the mode indicator bits for this mode object.
  final int modeBits;

  _Mode(this.modeBits, List<int> ccbits) {
    // (Package-private) Returns the bit width of the segment character count field for this mode object at the given version number.
    numCharCountBits = (int ver) {
      if (1 <= ver && ver <= 9)
        return ccbits[0];
      else if (10 <= ver && ver <= 26)
        return ccbits[1];
      else if (27 <= ver && ver <= 40)
        return ccbits[2];
      else
        throw new ArgumentError("Version number out of range");
    };
  }
}

/*---- Private helper functions and classes ----*/

// Returns a new array of bytes representing the given string encoded in UTF-8.
List<int> _toUtf8ByteArray(String unencodedStr) {
  String str = Uri.encodeComponent(unencodedStr);
  List<int> result = <int>[];
  for (int i = 0; i < str.length; i++) {
    if (str[i] != "%") {
      result.add(str.codeUnitAt(i));
    } else {
      result.add(int.parse('${str[i+1]}${str[i+2]}', radix: 16));
      i += 2;
    }
  }
  return result;
}

/*
 * A private helper class that computes the Reed-Solomon error correction codewords for a sequence of
 * data codewords at a given degree. Objects are immutable, and the state only depends on the degree.
 * This class exists because the divisor polynomial does not need to be recalculated for every input.
 * This constructor creates a Reed-Solomon ECC generator for the given degree. This could be implemented
 * as a lookup table over all possible parameter values, instead of as an algorithm.
 */
class _ReedSolomonGenerator {
  final int degree;

  // Coefficients of the divisor polynomial, stored from highest to lowest power, excluding the leading term which
  // is always 1. For example the polynomial x^3 + 255x^2 + 8x + 93 is stored as the uint8 array {255, 8, 93}.
  final List<int> coefficients = <int>[];

  // Compute the product polynomial (x - r^0) * (x - r^1) * (x - r^2) * ... * (x - r^{degree-1}),
  // drop the highest term, and store the rest of the coefficients in order of descending powers.
  // Note that r = 0x02, which is a generator element of this field GF(2^8/0x11D).
  int root = 1;

  _ReedSolomonGenerator(this.degree) {
    if (degree < 1 || degree > 255)
      throw new ArgumentError("Degree out of range");

    // Start with the monomial x^0
    for (int i = 0; i < degree - 1; i++) coefficients.add(0);
    coefficients.add(1);

    for (int i = 0; i < degree; i++) {
      // Multiply the current product by (x - r^i)
      for (int j = 0; j < coefficients.length; j++) {
        coefficients[j] = multiply(coefficients[j], root);
        if (j + 1 < coefficients.length) coefficients[j] ^= coefficients[j + 1];
      }
      root = multiply(root, 0x02);
    }
  }

  // Computes and returns the Reed-Solomon error correction codewords for the given sequence of data codewords.
  // The returned object is always a new byte array. This method does not alter this object's state (because it is immutable).
  List<int> getRemainder(List<int> data) {
    // Compute the remainder by performing polynomial division
    List<int> result = coefficients.map((_) {
      return 0;
    }).toList();
    data.forEach((int b) {
      int factor = b ^ result[0];
      result.removeAt(0);
      result.add(0);
      for (int i = 0; i < result.length; i++) {
        result[i] ^= multiply(coefficients[i], factor);
      }
    });
    return result;
  }

// This static function returns the product of the two given field elements modulo GF(2^8/0x11D). The arguments and
// result are unsigned 8-bit integers. This could be implemented as a lookup table of 256*256 entries of uint8.
  static int multiply(int x, int y) {
    if (x >> 8 != 0 || y >> 8 != 0)
      throw new ArgumentError("Byte out of range");
    // Russian peasant multiplication
    int z = 0;
    for (int i = 7; i >= 0; i--) {
      z = (z << 1) ^ ((z >> 7) * 0x11D);
      z ^= ((y >> i) & 1) * x;
    }
    assert(z >> 8 == 0);
    return z;
  }
}

/// A private helper class that represents an appendable sequence of bits.
/// This constructor creates an empty bit buffer (length 0).
class _BitBuffer {
  // Array of bits; each item is the integer 0 or 1
  final List<int> bitData = <int>[];

  // Returns the number of bits in the buffer, which is a non-negative value.
  int get bitLength => bitData.length;

  // Returns a copy of all bits.
  List<int> get bits => new List<int>.from(bitData);

  // Returns a copy of all bytes, padding up to the nearest byte.
  List<int> get bytes {
    List<int> result = <int>[];
    int numBytes = (bitData.length / 8).ceil();
    for (int i = 0; i < numBytes; i++) {
      result.add(0);
    }
    int i = 0;
    bitData.forEach((int bit) {
      result[i >> 3] |= bit << (7 - (i & 7));
      i++;
    });
    return result;
  }

  // Appends the given number of bits of the given value to this sequence.
  // If 0 <= len <= 31, then this requires 0 <= val < 2^len.
  void appendBits(int val, int len) {
    if (len < 0 || len > 32 || len < 32 && (val >> len) != 0)
      throw new ArgumentError("Value out of range");
    for (int i = len - 1; i >= 0; i--) // Append bit by bit
      bitData.add((val >> i) & 1);
  }

  // Appends the bit data of the given segment to this bit buffer.
  void appendData(_QrSegment seg) => bitData.addAll(seg.bits);
}
