// Copyright 2016 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/painting.dart';
import 'package:flutter/widgets.dart';

const int _kTurquoiseAccentColorValue = 0x8068EFAD;
const int _kUnselectedColorValue = 0xFF000000;

/// Called when a key is pressed.
typedef void OnText(String text);

/// A key that is represented by a string.  The [TextKey] is expected to have
/// a [Row] as a parent.
class TextKey extends StatefulWidget {
  /// The text to display.
  final String text;

  /// The style of the text.
  final TextStyle style;

  /// The vertical alignment the text should have within its container.
  final double verticalAlign;

  /// The horizontal alignment the text should have within its container.
  final double horizontalAlign;

  /// The height of the container to hold the text.
  final double height;

  /// The size of the key relative to its siblings.
  final int flex;

  /// Called when the key is pressed.
  final OnText onText;

  /// Constructor.
  TextKey(
    this.text, {
    GlobalKey key,
    this.onText,
    this.style,
    this.verticalAlign: 0.5,
    this.horizontalAlign: 0.5,
    this.height,
    this.flex: 2,
  })
      : super(key: key);

  @override
  TextKeyState createState() => new TextKeyState();
}

/// Holds the current text and down state of the [TextKey].
class TextKeyState extends State<TextKey> {
  String _text;
  bool _down;

  @override
  void initState() {
    super.initState();
    _text = widget.text;
    _down = false;
  }

  @override
  void didUpdateWidget(_) {
    super.didUpdateWidget(_);
    setState(() {
      _text = widget.text;
      _down = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return new Expanded(
      flex: widget.flex,
      child: new Listener(
        onPointerDown: (_) => setState(() {
              _down = true;
            }),
        onPointerUp: (_) {
          setState(() {
            _down = false;
          });
          widget.onText?.call(_text);
        },
        child: new Container(
          color: new Color(
            _down ? _kTurquoiseAccentColorValue : _kUnselectedColorValue,
          ),
          height: widget.height,
          child: new Align(
            alignment: new FractionalOffset(
              widget.horizontalAlign,
              widget.verticalAlign,
            ),
            child: new Text(_text, style: widget.style),
          ),
        ),
      ),
    );
  }

  /// Sets the text of the key.
  set text(String text) => setState(() {
        _text = text;
      });
}

/// A key that is represented by an image.  The [ImageKey] is expected to have
/// a [Row] as a parent.
class ImageKey extends StatefulWidget {
  /// The url of the image.
  final String imageUrl;

  /// The size of the key relative to its siblings.
  final int flex;

  /// Called when the key is pressed.
  final VoidCallback onKeyPressed;

  /// The color filter to apply to the image.
  final Color color;

  /// The height of the container to hold the image.
  final double height;

  /// Constructor.
  ImageKey(
    this.imageUrl,
    this.onKeyPressed,
    this.color,
    this.height, {
    this.flex: 2,
    Key key,
  })
      : super(key: key);

  @override
  _ImageKeyState createState() => new _ImageKeyState();
}

/// Holds the current down state of the [ImageKey].
class _ImageKeyState extends State<ImageKey> {
  static final double _kPadding = 20.0 / 3.0;

  bool _down = false;

  @override
  Widget build(BuildContext context) => new Expanded(
        flex: widget.flex,
        child: new Listener(
          onPointerDown: (_) {
            setState(() {
              _down = true;
            });
          },
          onPointerUp: (_) {
            setState(() {
              _down = false;
            });
            final VoidCallback onPressed =
                widget.onKeyPressed != null ? widget.onKeyPressed : () {};
            onPressed();
          },
          child: new Container(
            color: new Color(_down
                ? _kTurquoiseAccentColorValue
                : _kUnselectedColorValue),
            padding: new EdgeInsets.all(_kPadding),
            height: widget.height,
            child: new Container(
              child: new Image(
                image: new AssetImage(widget.imageUrl),
                fit: BoxFit.contain,
                color: widget.color,
              ),
            ),
          ),
        ),
      );
}
