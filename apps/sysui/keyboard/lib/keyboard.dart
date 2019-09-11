// Copyright 2016 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/painting.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

import 'keys.dart';
import 'word_suggestion_service.dart';

const double _kSuggestionRowHeight = 40.0;
const Color _kTurquoiseAccentColor = const Color(0xFF68EFAD);
const Color _kImageColor = const Color(0xFF909090);
const double _kDefaultRowHeight = 54.0;

const double _kKeyTextSize = 22.0;
const TextStyle _kDefaultTextStyle = const TextStyle(
  color: Colors.white,
  fontFamily: "Roboto-Light",
  fontSize: _kKeyTextSize,
);

const String _kKeyType = 'type'; // defaults to kKeyTypeNormal
const String _kKeyTypeSuggestion = 'suggestion';
const String _kKeyTypeNormal = 'normal';
const String _kKeyTypeSpecial = 'special';

const String _kKeyVisualType = 'visualtype'; // defaults to kKeyVisualTypeText
const String _kKeyVisualTypeText = 'text';
const String _kKeyVisualTypeImage = 'image';
const String _kKeyVisualTypeActionText = 'actiontext';

const String _kKeyAction =
    'action'; // defaults to kKeyActionEmitText, a number indicates an index into the kayboard layouts array.
const String _kKeyActionEmitText = 'emittext';
const String _kKeyActionDelete = 'delete';
const String _kKeyActionSpace = 'space';
const String _kKeyActionGo = 'go';

const String _kKeyImage = 'image'; // defaults to null
const String _kKeyText = 'text'; // defaults to null
const String _kKeyWidth = 'width'; // defaults to 1
const String _kKeyAlign = 'align'; // defaults to 0.5

const int _kKeyboardLayoutIndexLowerCase = 0;
const int _kKeyboardLayoutIndexUpperCase = 1;
const int _kKeyboardLayoutIndexSymbolsOne = 2;
const int _kKeyboardLayoutIndexSymbolsTwo = 3;

const String _kKeyboardLayoutsJson = "["
// Lower Case Layout
    "["
    "["
    "{\"$_kKeyType\":\"$_kKeyTypeSuggestion\", \"$_kKeyText\":\"call\"},"
    "{\"$_kKeyType\":\"$_kKeyTypeSuggestion\", \"$_kKeyText\":\"text\"},"
    "{\"$_kKeyType\":\"$_kKeyTypeSuggestion\", \"$_kKeyText\":\"play\"}"
    "],"
    "["
    "{\"$_kKeyText\":\"q\"},"
    "{\"$_kKeyText\":\"w\"},"
    "{\"$_kKeyText\":\"e\"},"
    "{\"$_kKeyText\":\"r\"},"
    "{\"$_kKeyText\":\"t\"},"
    "{\"$_kKeyText\":\"y\"},"
    "{\"$_kKeyText\":\"u\"},"
    "{\"$_kKeyText\":\"i\"},"
    "{\"$_kKeyText\":\"o\"},"
    "{\"$_kKeyText\":\"p\"}"
    "],"
    "["
    "{\"$_kKeyText\":\"a\", \"$_kKeyWidth\":\"3\", \"$_kKeyAlign\":\"0.66666666\"},"
    "{\"$_kKeyText\":\"s\", \"$_kKeyWidth\":\"2\"},"
    "{\"$_kKeyText\":\"d\", \"$_kKeyWidth\":\"2\"},"
    "{\"$_kKeyText\":\"f\", \"$_kKeyWidth\":\"2\"},"
    "{\"$_kKeyText\":\"g\", \"$_kKeyWidth\":\"2\"},"
    "{\"$_kKeyText\":\"h\", \"$_kKeyWidth\":\"2\"},"
    "{\"$_kKeyText\":\"j\", \"$_kKeyWidth\":\"2\"},"
    "{\"$_kKeyText\":\"k\", \"$_kKeyWidth\":\"2\"},"
    "{\"$_kKeyText\":\"l\", \"$_kKeyWidth\":\"3\", \"$_kKeyAlign\":\"0.33333333\"}"
    "],"
    "["
    "{\"$_kKeyImage\":\"packages/keyboard/res/ArrowUp.png\", \"$_kKeyAction\":\"$_kKeyboardLayoutIndexUpperCase\", \"$_kKeyType\":\"$_kKeyTypeSpecial\", \"$_kKeyVisualType\":\"$_kKeyVisualTypeImage\", \"$_kKeyWidth\":\"3\"},"
    "{\"$_kKeyText\":\"z\", \"$_kKeyWidth\":\"2\"},"
    "{\"$_kKeyText\":\"x\", \"$_kKeyWidth\":\"2\"},"
    "{\"$_kKeyText\":\"c\", \"$_kKeyWidth\":\"2\"},"
    "{\"$_kKeyText\":\"v\", \"$_kKeyWidth\":\"2\"},"
    "{\"$_kKeyText\":\"b\", \"$_kKeyWidth\":\"2\"},"
    "{\"$_kKeyText\":\"n\", \"$_kKeyWidth\":\"2\"},"
    "{\"$_kKeyText\":\"m\", \"$_kKeyWidth\":\"2\"},"
    "{\"$_kKeyImage\":\"packages/keyboard/res/Delete.png\", \"$_kKeyAction\":\"$_kKeyActionDelete\", \"$_kKeyType\":\"$_kKeyTypeSpecial\", \"$_kKeyVisualType\":\"$_kKeyVisualTypeImage\", \"$_kKeyWidth\":\"3\"}"
    "],"
    "["
    "{\"$_kKeyText\":\"?123\", \"$_kKeyAction\":\"$_kKeyboardLayoutIndexSymbolsOne\", \"$_kKeyType\":\"$_kKeyTypeSpecial\", \"$_kKeyVisualType\":\"$_kKeyVisualTypeActionText\", \"$_kKeyWidth\":\"5\"},"
    "{\"$_kKeyImage\":\"packages/keyboard/res/Space.png\", \"$_kKeyAction\":\"$_kKeyActionSpace\", \"$_kKeyType\":\"$_kKeyTypeSpecial\", \"$_kKeyVisualType\":\"$_kKeyVisualTypeImage\", \"$_kKeyWidth\":\"10\"},"
    "{\"$_kKeyText\":\".\", \"$_kKeyWidth\":\"2\"},"
    "{\"$_kKeyText\":\"Go\", \"$_kKeyAction\":\"$_kKeyActionGo\", \"$_kKeyVisualType\":\"$_kKeyVisualTypeActionText\", \"$_kKeyWidth\":\"3\"}"
    "]"
    "],"
// Upper Case Layout
    "["
    "["
    "{\"$_kKeyType\":\"$_kKeyTypeSuggestion\", \"$_kKeyText\":\"call\"},"
    "{\"$_kKeyType\":\"$_kKeyTypeSuggestion\", \"$_kKeyText\":\"text\"},"
    "{\"$_kKeyType\":\"$_kKeyTypeSuggestion\", \"$_kKeyText\":\"play\"}"
    "],"
    "["
    "{\"$_kKeyText\":\"Q\"},"
    "{\"$_kKeyText\":\"W\"},"
    "{\"$_kKeyText\":\"E\"},"
    "{\"$_kKeyText\":\"R\"},"
    "{\"$_kKeyText\":\"T\"},"
    "{\"$_kKeyText\":\"Y\"},"
    "{\"$_kKeyText\":\"U\"},"
    "{\"$_kKeyText\":\"I\"},"
    "{\"$_kKeyText\":\"O\"},"
    "{\"$_kKeyText\":\"P\"}"
    "],"
    "["
    "{\"$_kKeyText\":\"A\", \"$_kKeyWidth\":\"3\", \"$_kKeyAlign\":\"0.66666666\"},"
    "{\"$_kKeyText\":\"S\", \"$_kKeyWidth\":\"2\"},"
    "{\"$_kKeyText\":\"D\", \"$_kKeyWidth\":\"2\"},"
    "{\"$_kKeyText\":\"F\", \"$_kKeyWidth\":\"2\"},"
    "{\"$_kKeyText\":\"G\", \"$_kKeyWidth\":\"2\"},"
    "{\"$_kKeyText\":\"H\", \"$_kKeyWidth\":\"2\"},"
    "{\"$_kKeyText\":\"J\", \"$_kKeyWidth\":\"2\"},"
    "{\"$_kKeyText\":\"K\", \"$_kKeyWidth\":\"2\"},"
    "{\"$_kKeyText\":\"L\", \"$_kKeyWidth\":\"3\", \"$_kKeyAlign\":\"0.33333333\"}"
    "],"
    "["
    "{\"$_kKeyImage\":\"packages/keyboard/res/ArrowDown.png\", \"$_kKeyAction\":\"$_kKeyboardLayoutIndexLowerCase\", \"$_kKeyType\":\"$_kKeyTypeSpecial\", \"$_kKeyVisualType\":\"$_kKeyVisualTypeImage\", \"$_kKeyWidth\":\"3\"},"
    "{\"$_kKeyText\":\"Z\", \"$_kKeyWidth\":\"2\"},"
    "{\"$_kKeyText\":\"X\", \"$_kKeyWidth\":\"2\"},"
    "{\"$_kKeyText\":\"C\", \"$_kKeyWidth\":\"2\"},"
    "{\"$_kKeyText\":\"V\", \"$_kKeyWidth\":\"2\"},"
    "{\"$_kKeyText\":\"B\", \"$_kKeyWidth\":\"2\"},"
    "{\"$_kKeyText\":\"N\", \"$_kKeyWidth\":\"2\"},"
    "{\"$_kKeyText\":\"M\", \"$_kKeyWidth\":\"2\"},"
    "{\"$_kKeyImage\":\"packages/keyboard/res/Delete.png\", \"$_kKeyAction\":\"$_kKeyActionDelete\", \"$_kKeyType\":\"$_kKeyTypeSpecial\", \"$_kKeyVisualType\":\"$_kKeyVisualTypeImage\", \"$_kKeyWidth\":\"3\"}"
    "],"
    "["
    "{\"$_kKeyText\":\"?123\", \"$_kKeyAction\":\"$_kKeyboardLayoutIndexSymbolsOne\", \"$_kKeyType\":\"$_kKeyTypeSpecial\", \"$_kKeyVisualType\":\"$_kKeyVisualTypeActionText\", \"$_kKeyWidth\":\"5\"},"
    "{\"$_kKeyImage\":\"packages/keyboard/res/Space.png\", \"$_kKeyAction\":\"$_kKeyActionSpace\", \"$_kKeyType\":\"$_kKeyTypeSpecial\", \"$_kKeyVisualType\":\"$_kKeyVisualTypeImage\", \"$_kKeyWidth\":\"10\"},"
    "{\"$_kKeyText\":\".\", \"$_kKeyWidth\":\"2\"},"
    "{\"$_kKeyText\":\"Go\", \"$_kKeyAction\":\"$_kKeyActionGo\", \"$_kKeyVisualType\":\"$_kKeyVisualTypeActionText\", \"$_kKeyWidth\":\"3\"}"
    "]"
    "],"
// Symbols One Layout
    "["
    "["
    "{\"$_kKeyType\":\"$_kKeyTypeSuggestion\", \"$_kKeyText\":\"call\"},"
    "{\"$_kKeyType\":\"$_kKeyTypeSuggestion\", \"$_kKeyText\":\"text\"},"
    "{\"$_kKeyType\":\"$_kKeyTypeSuggestion\", \"$_kKeyText\":\"play\"}"
    "],"
    "["
    "{\"$_kKeyText\":\"1\"},"
    "{\"$_kKeyText\":\"2\"},"
    "{\"$_kKeyText\":\"3\"},"
    "{\"$_kKeyText\":\"4\"},"
    "{\"$_kKeyText\":\"5\"},"
    "{\"$_kKeyText\":\"6\"},"
    "{\"$_kKeyText\":\"7\"},"
    "{\"$_kKeyText\":\"8\"},"
    "{\"$_kKeyText\":\"9\"},"
    "{\"$_kKeyText\":\"0\"}"
    "],"
    "["
    "{\"$_kKeyText\":\"@\", \"$_kKeyWidth\":\"3\", \"$_kKeyAlign\":\"0.66666666\"},"
    "{\"$_kKeyText\":\"#\", \"$_kKeyWidth\":\"2\"},"
    "{\"$_kKeyText\":\"\$\", \"$_kKeyWidth\":\"2\"},"
    "{\"$_kKeyText\":\"%\", \"$_kKeyWidth\":\"2\"},"
    "{\"$_kKeyText\":\"&\", \"$_kKeyWidth\":\"2\"},"
    "{\"$_kKeyText\":\"-\", \"$_kKeyWidth\":\"2\"},"
    "{\"$_kKeyText\":\"+\", \"$_kKeyWidth\":\"2\"},"
    "{\"$_kKeyText\":\"(\", \"$_kKeyWidth\":\"2\"},"
    "{\"$_kKeyText\":\")\", \"$_kKeyWidth\":\"3\", \"$_kKeyAlign\":\"0.33333333\"}"
    "],"
    "["
    "{\"$_kKeyText\":\"=\\\\<\", \"$_kKeyAction\":\"$_kKeyboardLayoutIndexSymbolsTwo\", \"$_kKeyType\":\"$_kKeyTypeSpecial\", \"$_kKeyVisualType\":\"$_kKeyVisualTypeActionText\", \"$_kKeyWidth\":\"3\"},"
    "{\"$_kKeyText\":\"*\", \"$_kKeyWidth\":\"2\"},"
    "{\"$_kKeyText\":\"\\\\\", \"$_kKeyWidth\":\"2\"},"
    "{\"$_kKeyText\":\"\'\", \"$_kKeyWidth\":\"2\"},"
    "{\"$_kKeyText\":\":\", \"$_kKeyWidth\":\"2\"},"
    "{\"$_kKeyText\":\";\", \"$_kKeyWidth\":\"2\"},"
    "{\"$_kKeyText\":\"!\", \"$_kKeyWidth\":\"2\"},"
    "{\"$_kKeyText\":\"?\", \"$_kKeyWidth\":\"2\"},"
    "{\"$_kKeyImage\":\"packages/keyboard/res/Delete.png\", \"$_kKeyAction\":\"$_kKeyActionDelete\", \"$_kKeyType\":\"$_kKeyTypeSpecial\", \"$_kKeyVisualType\":\"$_kKeyVisualTypeImage\", \"$_kKeyWidth\":\"3\"}"
    "],"
    "["
    "{\"$_kKeyText\":\"ABC\", \"$_kKeyAction\":\"$_kKeyboardLayoutIndexLowerCase\", \"$_kKeyType\":\"$_kKeyTypeSpecial\", \"$_kKeyVisualType\":\"$_kKeyVisualTypeActionText\", \"$_kKeyWidth\":\"3\"},"
    "{\"$_kKeyText\":\",\", \"$_kKeyWidth\":\"2\"},"
    "{\"$_kKeyText\":\"_\", \"$_kKeyWidth\":\"2\"},"
    "{\"$_kKeyImage\":\"packages/keyboard/res/Space.png\", \"$_kKeyAction\":\"$_kKeyActionSpace\", \"$_kKeyType\":\"$_kKeyTypeSpecial\", \"$_kKeyVisualType\":\"$_kKeyVisualTypeImage\", \"$_kKeyWidth\":\"6\"},"
    "{\"$_kKeyText\":\"/\", \"$_kKeyWidth\":\"2\"},"
    "{\"$_kKeyText\":\".\", \"$_kKeyWidth\":\"2\"},"
    "{\"$_kKeyText\":\"Go\", \"$_kKeyAction\":\"$_kKeyActionGo\", \"$_kKeyVisualType\":\"$_kKeyVisualTypeActionText\", \"$_kKeyWidth\":\"3\"}"
    "]"
    "],"
// Symbols Two Layout
    "["
    "["
    "{\"$_kKeyType\":\"$_kKeyTypeSuggestion\", \"$_kKeyText\":\"call\"},"
    "{\"$_kKeyType\":\"$_kKeyTypeSuggestion\", \"$_kKeyText\":\"text\"},"
    "{\"$_kKeyType\":\"$_kKeyTypeSuggestion\", \"$_kKeyText\":\"play\"}"
    "],"
    "["
    "{\"$_kKeyText\":\"~\"},"
    "{\"$_kKeyText\":\"`\"},"
    "{\"$_kKeyText\":\"|\"},"
    "{\"$_kKeyText\":\"\u{2022}\"},"
    "{\"$_kKeyText\":\"\u{221A}\"},"
    "{\"$_kKeyText\":\"\u{03C0}\"},"
    "{\"$_kKeyText\":\"\u{00F7}\"},"
    "{\"$_kKeyText\":\"\u{00D7}\"},"
    "{\"$_kKeyText\":\"\u{00B6}\"},"
    "{\"$_kKeyText\":\"\u{2206}\"}"
    "],"
    "["
    "{\"$_kKeyText\":\"\u{00A3}\", \"$_kKeyWidth\":\"3\", \"$_kKeyAlign\":\"0.66666666\"},"
    "{\"$_kKeyText\":\"\u{00A2}\", \"$_kKeyWidth\":\"2\"},"
    "{\"$_kKeyText\":\"\u{20AC}\", \"$_kKeyWidth\":\"2\"},"
    "{\"$_kKeyText\":\"\u{00A5}\", \"$_kKeyWidth\":\"2\"},"
    "{\"$_kKeyText\":\"^\", \"$_kKeyWidth\":\"2\"},"
    "{\"$_kKeyText\":\"\u{00B0}\", \"$_kKeyWidth\":\"2\"},"
    "{\"$_kKeyText\":\"=\", \"$_kKeyWidth\":\"2\"},"
    "{\"$_kKeyText\":\"{\", \"$_kKeyWidth\":\"2\"},"
    "{\"$_kKeyText\":\"}\", \"$_kKeyWidth\":\"3\", \"$_kKeyAlign\":\"0.33333333\"}"
    "],"
    "["
    "{\"$_kKeyText\":\"?123\", \"$_kKeyAction\":\"$_kKeyboardLayoutIndexSymbolsOne\", \"$_kKeyType\":\"$_kKeyTypeSpecial\", \"$_kKeyVisualType\":\"$_kKeyVisualTypeActionText\", \"$_kKeyWidth\":\"3\"},"
    "{\"$_kKeyText\":\"\\\\\", \"$_kKeyWidth\":\"2\"},"
    "{\"$_kKeyText\":\"\u{00A9}\", \"$_kKeyWidth\":\"2\"},"
    "{\"$_kKeyText\":\"\u{00AE}\", \"$_kKeyWidth\":\"2\"},"
    "{\"$_kKeyText\":\"\u{2122}\", \"$_kKeyWidth\":\"2\"},"
    "{\"$_kKeyText\":\"\u{2105}\", \"$_kKeyWidth\":\"2\"},"
    "{\"$_kKeyText\":\"[\", \"$_kKeyWidth\":\"2\"},"
    "{\"$_kKeyText\":\"]\", \"$_kKeyWidth\":\"2\"},"
    "{\"$_kKeyImage\":\"packages/keyboard/res/Delete.png\", \"$_kKeyAction\":\"$_kKeyActionDelete\", \"$_kKeyType\":\"$_kKeyTypeSpecial\", \"$_kKeyVisualType\":\"$_kKeyVisualTypeImage\", \"$_kKeyWidth\":\"3\"}"
    "],"
    "["
    "{\"$_kKeyText\":\"ABC\", \"$_kKeyAction\":\"$_kKeyboardLayoutIndexLowerCase\", \"$_kKeyType\":\"$_kKeyTypeSpecial\", \"$_kKeyVisualType\":\"$_kKeyVisualTypeActionText\", \"$_kKeyWidth\":\"3\"},"
    "{\"$_kKeyText\":\",\", \"$_kKeyWidth\":\"2\"},"
    "{\"$_kKeyText\":\"<\", \"$_kKeyWidth\":\"2\"},"
    "{\"$_kKeyImage\":\"packages/keyboard/res/Space.png\", \"$_kKeyAction\":\"$_kKeyActionSpace\", \"$_kKeyType\":\"$_kKeyTypeSpecial\", \"$_kKeyVisualType\":\"$_kKeyVisualTypeImage\", \"$_kKeyWidth\":\"6\"},"
    "{\"$_kKeyText\":\">\", \"$_kKeyWidth\":\"2\"},"
    "{\"$_kKeyText\":\".\", \"$_kKeyWidth\":\"2\"},"
    "{\"$_kKeyText\":\"Go\", \"$_kKeyAction\":\"$_kKeyActionGo\", \"$_kKeyVisualType\":\"$_kKeyVisualTypeActionText\", \"$_kKeyWidth\":\"3\"}"
    "]"
    "]"
    "]";

final List<List<List<Map<String, String>>>> _kKeyboardLayouts =
    json.decode(_kKeyboardLayoutsJson);

/// Displays a keyboard.
class Keyboard extends StatefulWidget {
  /// Called when a key is tapped on the keyboard.
  final OnText onText;

  /// Called when a suggestion is tapped on the keyboard.
  final OnText onSuggestion;

  /// Called when 'Delete' is tapped on the keyboard.
  final VoidCallback onDelete;

  /// Called when 'Go' is tapped on the keyboard.
  final VoidCallback onGo;

  /// Constructor.
  Keyboard({Key key, this.onText, this.onSuggestion, this.onDelete, this.onGo})
      : super(key: key);

  @override
  KeyboardState createState() => new KeyboardState();
}

/// Displays the current keyboard for [Keyboard].
/// [_keyboards] is the list of available keyboards created from
/// [_kKeyboardLayouts] while [_keyboardWidget] is the one currently being
/// displayed.
class KeyboardState extends State<Keyboard> {
  static const double _kGoKeyTextSize = 16.0;
  static const double _kSuggestionTextSize = 16.0;
  static const TextStyle _kSuggestionTextStyle = const TextStyle(
      color: _kTurquoiseAccentColor,
      fontSize: _kSuggestionTextSize,
      letterSpacing: 2.0);

  final List<GlobalKey<TextKeyState>> _suggestionKeys =
      <GlobalKey<TextKeyState>>[];
  Widget _keyboardWidget;
  List<Widget> _keyboards;

  @override
  void initState() {
    super.initState();
    _keyboards = <Widget>[];
    _kKeyboardLayouts.forEach((List<List<Map<String, String>>> keyboard) {
      _keyboards.add(
        new IntrinsicHeight(
          child: new Column(
            children: keyboard
                .map((List<Map<String, String>> jsonRow) => _makeRow(jsonRow))
                .toList(),
          ),
        ),
      );
    });
    _keyboardWidget = _keyboards[0];
  }

  @override
  Widget build(BuildContext context) => _keyboardWidget;

  /// Updates the suggestions to be related to [text].
  void updateSuggestions(String text) {
    // If we have no text, clear the suggestions.  If the text ends in
    // whitespace also clear the suggestions (as there is no current word to
    // create suggestions from).
    if (text == null || text == '' || text.endsWith(' ')) {
      _clearSuggestions();
      return;
    }

    final List<String> stringList = text.split(' ');

    // If we have no words at all, clear the suggestions.
    if (stringList.isEmpty) {
      _clearSuggestions();
      return;
    }

    final String currentWord = stringList.removeLast();

    final WordSuggestionService wordSuggestionService =
        new WordSuggestionService();
    List<String> suggestedWords =
        wordSuggestionService.suggestWords(currentWord);
    _clearSuggestions();
    for (int i = 0;
        i < min(_suggestionKeys.length, suggestedWords.length);
        i++) {
      _suggestionKeys[i].currentState?.text = suggestedWords[i];
    }
  }

  void _clearSuggestions() {
    _suggestionKeys.forEach((GlobalKey<TextKeyState> suggestionKey) {
      suggestionKey.currentState?.text = '';
    });
  }

  Row _makeRow(List<Map<String, String>> jsonRow) => new Row(
      children: jsonRow
          .map((Map<String, String> jsonKey) => _makeKey(jsonKey))
          .toList(),
      mainAxisAlignment: MainAxisAlignment.center);

  Widget _makeKey(Map<String, String> jsonKey) {
    String visualType = jsonKey[_kKeyVisualType] ?? _kKeyVisualTypeText;
    String action = jsonKey[_kKeyAction] ?? _kKeyActionEmitText;
    int width = int.parse(jsonKey[_kKeyWidth] ?? '1');

    switch (visualType) {
      case _kKeyVisualTypeImage:
        String image = jsonKey[_kKeyImage];
        return _createImageKey(image, width, action);
      case _kKeyVisualTypeText:
      case _kKeyVisualTypeActionText:
      default:
        String type = jsonKey[_kKeyType] ?? _kKeyTypeNormal;
        String text = jsonKey[_kKeyText];
        double align = double.parse(jsonKey[_kKeyAlign] ?? '0.5');
        return _createTextKey(text, width, action, align, type, visualType);
    }
  }

  Widget _createTextKey(String text, int width, String action, double align,
      String type, String visualType) {
    TextStyle style = (type == _kKeyTypeSuggestion)
        ? _kSuggestionTextStyle
        : (visualType == _kKeyVisualTypeActionText)
            ? (type == _kKeyTypeSpecial)
                ? _kDefaultTextStyle.copyWith(
                    fontSize: _kGoKeyTextSize,
                    fontWeight: FontWeight.bold,
                    color: _kImageColor,
                  )
                : _kDefaultTextStyle.copyWith(
                    fontSize: _kGoKeyTextSize,
                    fontWeight: FontWeight.bold,
                  )
            : _kDefaultTextStyle;
    bool isSuggestion = type == _kKeyTypeSuggestion;
    GlobalKey key = isSuggestion ? new GlobalKey() : null;
    TextKey textKey = new TextKey(
      isSuggestion ? '' : text,
      key: key,
      flex: width,
      onText: (String text) {
        VoidCallback actionCallback = _getAction(action);
        if (actionCallback != null) {
          actionCallback();
        } else if (isSuggestion) {
          _onSuggestion(text);
        } else {
          _onText(text);
        }
      },
      horizontalAlign: align,
      style: style,
      height: isSuggestion ? _kSuggestionRowHeight : _kDefaultRowHeight,
      verticalAlign: 0.5,
    );
    if (isSuggestion) {
      _suggestionKeys.add(key);
    }
    return textKey;
  }

  Widget _createImageKey(String image, int width, String action) =>
      new ImageKey(
        image,
        _getAction(action),
        _kImageColor,
        _kDefaultRowHeight,
        flex: width,
      );

  VoidCallback _getAction(String action) {
    switch (action) {
      case _kKeyActionEmitText:
        return null;
      case _kKeyActionDelete:
        return _onDeletePressed;
      case _kKeyActionSpace:
        return _onSpacePressed;
      case _kKeyActionGo:
        return _onGoPressed;
      default:
        return () => setState(() {
              _keyboardWidget = _keyboards[int.parse(action)];
            });
    }
  }

  void _onText(String text) {
    widget.onText?.call(text);
  }

  void _onSuggestion(String suggestion) {
    widget.onSuggestion?.call(suggestion);
  }

  void _onSpacePressed() {
    widget.onText?.call(' ');
  }

  void _onGoPressed() {
    widget.onGo?.call();
  }

  void _onDeletePressed() {
    widget.onDelete?.call();
  }
}
