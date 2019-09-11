// Copyright 2016 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io' show Platform;

const int _kAndroidMetaStateNormal = 0;
const int _kAndroidMetaStateLeftShiftDown = 65;
const int _kAndroidMetaStateRightShiftDown = 129;
const int _kAndroidMetaStateAltDown = 18;
const int _kAndroidMetaStateCtrlDown = 12288;

const Map<int, String> _kAndroidKeyCodeMap = const <int, String>{
  7: '0',
  8: '1',
  9: '2',
  10: '3',
  11: '4',
  12: '5',
  13: '6',
  14: '7',
  15: '8',
  16: '9',
  29: 'a',
  30: 'b',
  31: 'c',
  32: 'd',
  33: 'e',
  34: 'f',
  35: 'g',
  36: 'h',
  37: 'i',
  38: 'j',
  39: 'k',
  40: 'l',
  41: 'm',
  42: 'n',
  43: 'o',
  44: 'p',
  45: 'q',
  46: 'r',
  47: 's',
  48: 't',
  49: 'u',
  50: 'v',
  51: 'w',
  52: 'x',
  53: 'y',
  54: 'z',
  55: ',',
  56: '.',
  62: ' ',
  69: '-',
  70: '=',
  74: ';',
  75: '\'',
  76: '/'
};

const Map<int, String> _kAndroidShiftedKeyCodeMap = const <int, String>{
  7: ')',
  8: '!',
  9: '@',
  10: '#',
  11: '\$',
  12: '%',
  13: '^',
  14: '&',
  15: '*',
  16: '(',
  29: 'A',
  30: 'B',
  31: 'C',
  32: 'D',
  33: 'E',
  34: 'F',
  35: 'G',
  36: 'H',
  37: 'I',
  38: 'J',
  39: 'K',
  40: 'L',
  41: 'M',
  42: 'N',
  43: 'O',
  44: 'P',
  45: 'Q',
  46: 'R',
  47: 'S',
  48: 'T',
  49: 'U',
  50: 'V',
  51: 'W',
  52: 'X',
  53: 'Y',
  54: 'Z',
  55: '<',
  56: '>',
  62: ' ',
  69: '_',
  70: '+',
  74: ':',
  75: '"',
  76: '?'
};

const int _kAndroidKeyCodeEnter = 66;
const int _kAndroidKeyCodeBackspace = 67;

const int _kLinuxMetaStateNormal = 0;
const int _kLinuxMetaStateLeftShiftDown = 1;
const int _kLinuxMetaStateRightShiftDown = 1;
const int _kLinuxMetaStateAltDown = 2;
const int _kLinuxMetaStateCtrlDown = 4096;

const Map<int, String> _kLinuxKeyCodeMap = const <int, String>{
  48: '0',
  49: '1',
  50: '2',
  51: '3',
  52: '4',
  53: '5',
  54: '6',
  55: '7',
  56: '8',
  57: '9',
  65: 'a',
  66: 'b',
  67: 'c',
  68: 'd',
  69: 'e',
  70: 'f',
  71: 'g',
  72: 'h',
  73: 'i',
  74: 'j',
  75: 'k',
  76: 'l',
  77: 'm',
  78: 'n',
  79: 'o',
  80: 'p',
  81: 'q',
  82: 'r',
  83: 's',
  84: 't',
  85: 'u',
  86: 'v',
  87: 'w',
  88: 'x',
  89: 'y',
  90: 'z',
  188: ',',
  190: '.',
  32: ' ',
  189: '-',
  187: '=',
  186: ';',
  222: '\'',
  191: '/'
};

const Map<int, String> _kLinuxShiftedKeyCodeMap = const <int, String>{
  48: ')',
  49: '!',
  50: '@',
  51: '#',
  52: '\$',
  53: '%',
  54: '^',
  55: '&',
  56: '*',
  57: '(',
  65: 'A',
  66: 'B',
  67: 'C',
  68: 'D',
  69: 'E',
  70: 'F',
  71: 'G',
  72: 'H',
  73: 'I',
  74: 'J',
  75: 'K',
  76: 'L',
  77: 'M',
  78: 'N',
  79: 'O',
  80: 'P',
  81: 'Q',
  82: 'R',
  83: 'S',
  84: 'T',
  85: 'U',
  86: 'V',
  87: 'W',
  88: 'X',
  89: 'Y',
  90: 'Z',
  188: '<',
  190: '>',
  32: ' ',
  189: '_',
  187: '+',
  186: ':',
  222: '"',
  191: '?'
};

const int _kLinuxKeyCodeEnter = 13;
const int _kLinuxKeyCodeBackspace = 8;

/// The keycode for backspace on the current platform.
int get keyCodeBackspace =>
    Platform.isAndroid ? _kAndroidKeyCodeBackspace : _kLinuxKeyCodeBackspace;

/// The keycode for enter on the current platform.
int get keyCodeEnter =>
    Platform.isAndroid ? _kAndroidKeyCodeEnter : _kLinuxKeyCodeEnter;

/// The metastate indicating no modifications apply to the keycode on the
/// current platform.
int get metaStateNormal =>
    Platform.isAndroid ? _kAndroidMetaStateNormal : _kLinuxMetaStateNormal;

/// The metastate indicating the left shift is down on the current platform.
int get metaStateLeftShiftDown => Platform.isAndroid
    ? _kAndroidMetaStateLeftShiftDown
    : _kLinuxMetaStateLeftShiftDown;

/// The metastate indicating the right shift is down on the current platform.
int get metaStateRightShiftDown => Platform.isAndroid
    ? _kAndroidMetaStateRightShiftDown
    : _kLinuxMetaStateRightShiftDown;

/// Maps keycodes to text on the current platform.
Map<int, String> get keyCodeMap =>
    Platform.isAndroid ? _kAndroidKeyCodeMap : _kLinuxKeyCodeMap;

/// Maps shifted keycodes to text on the current platform.
Map<int, String> get shiftedKeyCodeMap =>
    Platform.isAndroid ? _kAndroidShiftedKeyCodeMap : _kLinuxShiftedKeyCodeMap;
