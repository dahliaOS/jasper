// Copyright 2016 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/services.dart';

AssetBundle _initBundle() {
  if (rootBundle != null) return rootBundle;
  return new NetworkAssetBundle(Uri.base);
}

/// Returns the default [AssetBundle] for this flutter app.
final AssetBundle defaultBundle = _initBundle();
