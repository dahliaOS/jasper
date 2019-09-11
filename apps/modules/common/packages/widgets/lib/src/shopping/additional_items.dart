// Copyright 2016 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';

/// UI Widget that shows relevant items to also purchase at the end of an
/// interactive receipt.
///
/// This is a proof of concept module to showcase how Modular can leverage
/// embedding to create rich interactive experiences.
///
/// Prices and items are not meant to reflect the real world
class AdditionalItems extends StatelessWidget {
  /// Indicates whether to use the https url for images
  final bool useHttps;

  /// Constructor
  AdditionalItems({
    Key key,
    bool useHttps,
  })
      : useHttps = useHttps ?? true,
        super(key: key);

  Widget _buildItem({
    String name,
    String price,
    String imageUrl,
  }) {
    return new Container(
      margin: const EdgeInsets.all(16.0),
      child: new Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          new Container(
            margin: const EdgeInsets.only(bottom: 4.0),
            padding: const EdgeInsets.all(15.0),
            width: 180.0,
            height: 180.0,
            color: Colors.grey[300],
            child: new Image.network(
              useHttps ? imageUrl : imageUrl.replaceFirst('https:', 'http:'),
            ),
          ),
          new Text(
            name,
            style: new TextStyle(height: 1.5),
          ),
          new Text(
            price,
            style: new TextStyle(
              height: 1.5,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return new Container(
      color: Colors.white,
      child: new Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          new Container(
            alignment: FractionalOffset.center,
            padding: const EdgeInsets.only(top: 32.0, bottom: 12.0),
            child: new Text(
              'YOU MAY ALSO LIKE',
              style: new TextStyle(
                fontSize: 18.0,
                fontWeight: FontWeight.w400,
                color: Colors.grey[600],
              ),
            ),
          ),
          new Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              _buildItem(
                name: 'Chromecast Ultra',
                price: '\$69',
                imageUrl:
                    'https://lh3.googleusercontent.com/yq9EWTGMYrpcav3_0ROrNYMA3IC5EJuvpZxNOiEsfMk7dunDdWR2TP_S-Khu1WGejQ',
              ),
              _buildItem(
                name: 'Google Home',
                price: '\$129',
                imageUrl:
                    'https://lh3.googleusercontent.com/Nu3a6F80WfixUqf_ec_vgXy_c0-0r4VLJRXjVFF_X_CIilEu8B9fT35qyTEj_PEsKw',
              ),
            ],
          ),
          new Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              _buildItem(
                name: 'Artworks Live Case',
                price: '\$40',
                imageUrl:
                    'https://lh3.googleusercontent.com/aYJf9JJIwsNXO_W-1GKBPtdrcfplqzVKUCBUj5sWNJX5jECg3ku68aP0HbgLecEL8A',
              ),
              _buildItem(
                name: 'Daydream View',
                price: '\$79',
                imageUrl:
                    'https://lh3.googleusercontent.com/3cTyu0he1Yv6YkDFcsyQURR3H0kQsk0IB8raKeWxtTK_NsngsgnVP5XOLW4cuT9FLME',
              ),
            ],
          ),
        ],
      ),
    );
  }
}
