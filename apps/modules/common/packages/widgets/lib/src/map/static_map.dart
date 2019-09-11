// Copyright 2016 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:meta/meta.dart';
import 'package:widgets_meta/widgets_meta.dart';

/// UI Widget that renders a Google Map given a location
class StaticMap extends StatelessWidget {
  /// Location to show
  final String location;

  /// How much to zoom in for given location
  final int zoom;

  /// Width of map
  final double width;

  /// Height of map
  final double height;

  /// API key for Google Maps
  final String apiKey;

  /// Constructor
  StaticMap({
    Key key,
    @required @ConfigKey('google_api_key') this.apiKey,
    @ExampleValue('56 Henry, San Francisco, CA') this.location,
    int zoom,
    @widthParam double width,
    @heightParam double height,
  })
      : zoom = zoom ?? 5,
        width = width ?? 300.0,
        height = height ?? 300.0,
        super(key: key) {
    assert(location != null);
    assert(apiKey != null);
  }

  @override
  Widget build(BuildContext context) {
    if (location == null || location.isEmpty) {
      return new Container(
        color: Colors.blueGrey[300],
        child: new Center(child: new Text('No Maps')),
      );
    } else {
      // TODO (dayang): Move back to a HTTPS once it become stable
      String mapUrl = 'http://maps.googleapis.com/maps/api/staticmap?'
          'center=$location&scale=2'
          '&zoom=$zoom&size=${width.round()}x${height.round()}'
          '&maptype=roadmap&markers=color:red%7Clabel:P%7C'
          '${Uri.encodeQueryComponent(location)}'
          '&key=$apiKey';
      return new Image.network(
        mapUrl,
        height: height,
        width: width,
        gaplessPlayback: true,
        fit: BoxFit.cover,
      );
    }
  }
}
