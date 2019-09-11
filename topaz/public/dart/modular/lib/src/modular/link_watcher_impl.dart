// Copyright 2017 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:apps.modular.services.story/link.fidl.dart';

/// Called when [LinkWatcher.notify] is called.
typedef void OnNotify(String json);

/// Implements a [LinkWatcher] for receiving notifications from a [Link]
/// instance.
class LinkWatcherImpl extends LinkWatcher {
  /// Called when [LinkWatcher.notify] is called.
  final OnNotify onNotify;

  /// Creates a new instance of [LinkWatcherImpl].
  LinkWatcherImpl({this.onNotify});

  @override
  void notify(String json) {
    onNotify?.call(json);
  }
}
