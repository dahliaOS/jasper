// Copyright 2017 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:meta/meta.dart';
import 'package:widgets_meta/widgets_meta.dart';

const Duration _kAnimationDuration = const Duration(milliseconds: 100);
const double _kDefaultSize = 150.0;
const double _kSelectedIconSizeRatio = 0.20;
const double _kSelectSizeRatio = 0.70;
const String _kExampleImage =
    'https://github.com/dvdwasibi/DogsOfFuchsia/blob/master/coco.jpg?raw=true';

/// UI Widget that represents a single image in an Image Picker
@ExampleSize(_kDefaultSize, _kDefaultSize)
class ImageEntry extends StatelessWidget {
  /// URL of image to show
  final String imageUrl;

  /// True if this [ImageEntry] is currently selected
  final bool selected;

  /// Size of the [ImageEntry]. Defaults to 150.0.
  final double size;

  /// Callback for when this image is tapped(toggled). The typical response will
  /// be toggling the selected state of the image.
  final VoidCallback onTap;

  /// Constructor
  ImageEntry({
    Key key,
    @required @ExampleValue(_kExampleImage) this.imageUrl,
    this.selected: false,
    @sizeParam this.size: _kDefaultSize,
    this.onTap,
  })
      : super(key: key) {
    assert(imageUrl != null);
    assert(size != null);
  }

  double get _selectedIconSize => size * _kSelectedIconSizeRatio;

  double get _iconOffset =>
      size * (1.0 - _kSelectSizeRatio) - _selectedIconSize;

  @override
  Widget build(BuildContext context) {
    return new Material(
      color: Colors.grey[300],
      child: new InkWell(
        onTap: () => onTap?.call(),
        child: new Stack(
          fit: StackFit.passthrough,
          children: <Widget>[
            new Container(
              alignment: FractionalOffset.center,
              width: size,
              height: size,
              child: new AnimatedContainer(
                duration: _kAnimationDuration,
                curve: Curves.easeOut,
                width: selected ? size * _kSelectSizeRatio : size,
                height: selected ? size * _kSelectSizeRatio : size,
                child: new Image.network(
                  imageUrl,
                  fit: BoxFit.cover,
                  gaplessPlayback: true,
                ),
              ),
            ),
            new Positioned(
              top: _iconOffset,
              left: _iconOffset,
              child: new Offstage(
                offstage: !selected,
                child: new Container(
                  width: _selectedIconSize,
                  height: _selectedIconSize,
                  decoration: new BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.blue[500],
                  ),
                  alignment: FractionalOffset.center,
                  child: new Icon(
                    Icons.check,
                    color: Colors.white,
                    size: _selectedIconSize - 8.0,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
