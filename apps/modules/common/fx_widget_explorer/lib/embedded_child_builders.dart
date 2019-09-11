// Copyright 2016 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:config/config.dart';
import 'package:flutter/material.dart';
import 'package:widgets/map.dart';
import 'package:widgets/shopping.dart';
import 'package:widgets/usps.dart';
import 'package:widgets/youtube.dart';

/// Adds all the [EmbeddedChildBuilder]s that this application supports.
void addEmbeddedChildBuilders(Config config) {
  // USPS Tracking
  if (config.has('usps_api_key')) {
    kEmbeddedChildProvider.addEmbeddedChildBuilder(
      'usps-shipping',
      (dynamic args) {
        return new EmbeddedChild(
          widgetBuilder: (BuildContext context) => new TrackingStatus(
                apiKey: config.get('usps_api_key'),
                trackingCode: args,
              ),
          // Flutter version doesn't need a specific disposer.
          disposer: () {},
        );
      },
    );
  }

  // Map, Youtube video
  if (config.has('google_api_key')) {
    kEmbeddedChildProvider.addEmbeddedChildBuilder(
      'map',
      (dynamic args) {
        return new EmbeddedChild(
          widgetBuilder: (BuildContext context) => new StaticMap(
                location: args,
                apiKey: config.get('google_api_key'),
              ),
          // Flutter version doesn't need a specific disposer.
          disposer: () {},
        );
      },
    );

    kEmbeddedChildProvider.addEmbeddedChildBuilder(
      'youtube-video',
      (dynamic args) {
        return new EmbeddedChild(
          widgetBuilder: (BuildContext context) => new YoutubeVideo(
                videoId: args,
                apiKey: config.get('google_api_key'),
              ),
          // Flutter version doesn't need a specific disposer.
          disposer: () {},
        );
      },
    );
  }

  kEmbeddedChildProvider.addEmbeddedChildBuilder(
    'order-receipt',
    (dynamic args) {
      return new EmbeddedChild(
        widgetBuilder: (BuildContext context) => new InteractiveReceipt(),
        // Flutter version doesn't need a specific disposer.
        disposer: () {},
      );
    },
  );
}
