// Copyright 2016 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';

import 'additional_items.dart';

/// Color options for a phone
enum _PhoneColor {
  black,
  silver,
  blue,
}

/// Size options for a phone
enum _StorageSize {
  s32,
  s128,
}

/// Animation duration for image resize
const Duration _kAnimationDuration = const Duration(milliseconds: 300);

/// Duration for confirmation snackbar
const Duration _kSnackBarDisplayDuration = const Duration(milliseconds: 2500);

/// UI Widget that represents an interactive receipt that is meant to replace
/// a standard email receipt.
///
/// This is a proof of concept module to showcase how Modular can leverage
/// embedding to create rich interactive experiences.
///
/// Prices and Items are not meant to reflect the real world.
class InteractiveReceipt extends StatefulWidget {
  /// Indicates whether to use the https url for images
  final bool useHttps;

  /// Constructor
  InteractiveReceipt({
    Key key,
    bool useHttps,
  })
      : useHttps = useHttps ?? true,
        super(key: key);

  @override
  _InteractiveReceiptState createState() => new _InteractiveReceiptState();
}

class _InteractiveReceiptState extends State<InteractiveReceipt>
    with TickerProviderStateMixin {
  final GlobalKey<ScaffoldState> _scaffoldKey = new GlobalKey<ScaffoldState>();
  AnimationController _controller;
  Animation<double> _imageAnimation;
  bool _editMode = false;
  _StorageSize _storageSize = _StorageSize.s32;
  _PhoneColor _selectedPhoneColor = _PhoneColor.silver;

  @override
  void initState() {
    super.initState();
    _controller =
        new AnimationController(duration: _kAnimationDuration, vsync: this);
    _imageAnimation =
        new CurvedAnimation(parent: _controller, curve: Curves.ease);
  }

  String get _storageSizeText {
    switch (_storageSize) {
      case _StorageSize.s32:
        return '32 GB';
      case _StorageSize.s128:
        return '128 GB';
      default:
        return '';
    }
  }

  String get _price {
    switch (_storageSize) {
      case _StorageSize.s32:
        return '\$769.00';
      case _StorageSize.s128:
        return '\$869.00';
      default:
        return '';
    }
  }

  String get imageUrl {
    switch (_selectedPhoneColor) {
      case _PhoneColor.black:
        return 'https://lh3.googleusercontent.com/WiZ9IdoWExc2vUdR5Oom31lK3BNHeaZ8SRFLgSUl2ObTYineH7LPKLM5NbHaAGXZt0qf';
      case _PhoneColor.silver:
        return 'https://lh3.googleusercontent.com/JKkKltrLkFnpNirTEjb8yA5bui0Hv7mPocx8T5Gu6qUiYrlnt1Jcx7ITH9pobnejSp9u';
      case _PhoneColor.blue:
        return 'https://lh3.googleusercontent.com/7cco-0fPUfmv0D0Rk0dCDYYv1QjzncyGEhxN5zFUHKWoIKuxgvrOwAFbAyRkKxLvv6pV';
      default:
        return '';
    }
  }

  String get _colorText {
    switch (_selectedPhoneColor) {
      case _PhoneColor.black:
        return 'Quite Black';
      case _PhoneColor.silver:
        return 'Very Silver';
      case _PhoneColor.blue:
        return 'Really Blue';
      default:
        return '';
    }
  }

  Color _getColorFromPhoneColor(_PhoneColor phoneColor) {
    switch (phoneColor) {
      case _PhoneColor.blue:
        return Colors.blue[600];
      case _PhoneColor.silver:
        return Colors.white;
      case _PhoneColor.black:
        return Colors.black;
      default:
        return Colors.white;
    }
  }

  Widget _buildBrandHeader() {
    return new Container(
      height: 130.0,
      padding: const EdgeInsets.only(top: 24.0),
      alignment: FractionalOffset.topCenter,
      color: Colors.grey[800],
      child: new Text(
        'A+ Mobile',
        style: new TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w500,
          fontSize: 20.0,
        ),
      ),
    );
  }

  Widget _buildColorOption(_PhoneColor phoneColor) {
    return new Container(
      margin: const EdgeInsets.symmetric(horizontal: 4.0),
      decoration: new BoxDecoration(
        border: _selectedPhoneColor == phoneColor
            ? new Border.all(color: Colors.grey[600], width: 3.0)
            : new Border.all(color: Colors.grey[300]),
      ),
      child: new Material(
        color: _getColorFromPhoneColor(phoneColor),
        child: new InkWell(
          onTap: () {
            setState(() {
              _selectedPhoneColor = phoneColor;
            });
          },
          child: new Container(
            width: 20.0,
            height: 20.0,
          ),
        ),
      ),
    );
  }

  Widget _buildPhoneDetails() {
    if (_editMode) {
      return new Expanded(
        flex: 1,
        child: new Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            // Color choices
            new Row(
              children: <Widget>[
                _buildColorOption(_PhoneColor.black),
                _buildColorOption(_PhoneColor.blue),
                _buildColorOption(_PhoneColor.silver),
              ],
            ),
            // Size selection dropdown menu
            new Container(
              margin: const EdgeInsets.only(left: 4.0),
              child: new DropdownButton<_StorageSize>(
                value: _storageSize,
                onChanged: (_StorageSize newSize) {
                  setState(() {
                    if (newSize != null) _storageSize = newSize;
                  });
                },
                items: <_StorageSize>[_StorageSize.s32, _StorageSize.s128]
                    .map((_StorageSize value) {
                  String text;
                  switch (value) {
                    case _StorageSize.s32:
                      text = '32 GB';
                      break;
                    case _StorageSize.s128:
                      text = '128 GB';
                      break;
                  }
                  return new DropdownMenuItem<_StorageSize>(
                    value: value,
                    child: new Text(
                      text,
                      style: new TextStyle(fontSize: 12.0),
                    ),
                  );
                }).toList(),
              ),
            ),
            new Container(
              margin: const EdgeInsets.only(top: 4.0),
              child: new FlatButton(
                child: new Text(
                  'Submit Modification',
                  style: new TextStyle(
                    color: Colors.blue[600],
                    fontSize: 10.0,
                  ),
                ),
                onPressed: () {
                  setState(() {
                    _editMode = false;
                    _controller.reverse();
                    _scaffoldKey.currentState.showSnackBar(new SnackBar(
                      duration: _kSnackBarDisplayDuration,
                      backgroundColor: Colors.green[500],
                      content: new Text(
                        'Your order has been successfully modified',
                        textAlign: TextAlign.center,
                        style: new TextStyle(fontSize: 12.0),
                      ),
                    ));
                  });
                },
              ),
            ),
          ],
        ),
      );
    } else {
      return new Expanded(
        flex: 1,
        child: new Text(
          '$_storageSizeText / $_colorText',
          softWrap: false,
          overflow: TextOverflow.fade,
          style: new TextStyle(fontSize: 12.0),
        ),
      );
    }
  }

  Widget _buildPhoneOverview() {
    return new Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        new _AnimatedPhoneImage(
          imageUrl: widget.useHttps
              ? imageUrl
              : imageUrl.replaceFirst('https:', 'http:'),
          animation: _imageAnimation,
        ),
        new Expanded(
          flex: 1,
          child: new Container(
            margin: const EdgeInsets.only(top: 30.0),
            child: new Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                new Text(
                  '1 Phone XL',
                  style: new TextStyle(
                    fontSize: 16.0,
                  ),
                ),
                new Container(
                  margin: const EdgeInsets.only(
                    top: 4.0,
                    right: 12.0,
                  ),
                  child: new Row(
                    children: <Widget>[
                      _buildPhoneDetails(),
                      _editMode
                          ? new Container()
                          : new Text(
                              _price,
                              style: new TextStyle(fontSize: 12.0),
                            ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        new Container(
          margin: const EdgeInsets.only(
            right: 8.0,
            left: 8.0,
            top: 30.0,
          ),
          child: new FadeTransition(
            opacity: new ReverseAnimation(_imageAnimation),
            child: new IconButton(
              onPressed: () {
                setState(() {
                  _editMode = !_editMode;
                  _controller.forward();
                });
              },
              icon: new Icon(Icons.edit),
              color: Colors.blue[600],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPricingLine({String label, String value}) {
    return new Container(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: new Row(children: <Widget>[
        new Expanded(
          flex: 1,
          child: new Text(label, style: new TextStyle(fontSize: 12.0)),
        ),
        new Text(value, style: new TextStyle(fontSize: 12.0)),
      ]),
    );
  }

  Widget _buildPricing() {
    return new Container(
      margin: const EdgeInsets.only(
        left: 16.0,
        right: 16.0,
        top: 16.0,
      ),
      padding: const EdgeInsets.only(
        top: 16.0,
        left: 14.0,
        right: 14.0,
      ),
      decoration: new BoxDecoration(
        border: new Border(
            top: new BorderSide(
          color: Colors.grey[300],
        )),
      ),
      child: new Column(
        children: <Widget>[
          _buildPricingLine(
            label: 'Subtotal',
            value: _price,
          ),
          _buildPricingLine(
            label: 'Shipping & Handling',
            value: '\$0.00',
          ),
          _buildPricingLine(
            label: 'Tax',
            value: '\$0.00',
          ),
          _buildPricingLine(
            label: 'Total',
            value: _price,
          ),
        ],
      ),
    );
  }

  Widget _buildMainItemCard() {
    return new Container(
      padding: const EdgeInsets.only(
        top: 70.0,
        right: 16.0,
        left: 16.0,
      ),
      child: new Card(
        child: new Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            new Row(
              children: <Widget>[
                new Expanded(
                  flex: 1,
                  child: new Container(
                    alignment: FractionalOffset.center,
                    color: Colors.grey[300],
                    padding: const EdgeInsets.symmetric(vertical: 36.0),
                    child: new Column(
                      children: <Widget>[
                        new Text(
                          'Thanks for shopping with A+ Mobile',
                          style: new TextStyle(
                            fontSize: 18.0,
                            color: Colors.grey[700],
                          ),
                        ),
                        new Container(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: new Text(
                            'You have 7 hours to modify your order',
                            style: new TextStyle(
                              color: Colors.grey[700],
                              fontSize: 12.0,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            new Container(
              padding: const EdgeInsets.all(8.0),
              child: new Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  _buildPhoneOverview(),
                  _buildPricing(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return new Scaffold(
      key: _scaffoldKey,
      body: new ListView(
        children: <Widget>[
          new Container(
            color: Colors.grey[100],
            padding: const EdgeInsets.only(bottom: 32.0),
            child: new Stack(
              fit: StackFit.passthrough,
              alignment: FractionalOffset.topLeft,
              children: <Widget>[
                _buildBrandHeader(),
                _buildMainItemCard(),
              ],
            ),
          ),
          new AdditionalItems(useHttps: widget.useHttps),
        ],
      ),
    );
  }
}

/// Animates the Phone Image from 100dp to 200dp
// ignore: must_be_immutable
class _AnimatedPhoneImage extends AnimatedWidget {
  final String imageUrl;

  _AnimatedPhoneImage({
    Key key,
    Animation<double> animation,
    this.imageUrl,
  })
      : super(key: key, listenable: animation);

  @override
  Widget build(BuildContext context) {
    // ignore: strong_mode_down_cast_composite
    final Animation<double> animation = this.listenable;

    return new Container(
      height: 100.0 + 100 * animation.value,
      width: 100.0 + 100 * animation.value,
      child: new Image.network(
        imageUrl,
        gaplessPlayback: true,
      ),
    );
  }
}
