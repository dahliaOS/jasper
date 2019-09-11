// Copyright 2017 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:apps.modular.services.user/focus.fidl.dart';

import 'debug.dart';

/// Called when we receive a request to focus on [storyId];
typedef void OnFocusRequest(String storyId);

/// Listens for requests to change the currently focused story.
class FocusRequestWatcherImpl extends FocusRequestWatcher {
  /// Called when we receive a request to focus on a story.
  final OnFocusRequest _onFocusRequest;

  /// Constructor.
  FocusRequestWatcherImpl({OnFocusRequest onFocusRequest})
      : _onFocusRequest = onFocusRequest;

  @override
  void onFocusRequest(String storyId) {
    armadilloPrint('Received request to focus story: $storyId');
    _onFocusRequest(storyId);
  }
}
