// Copyright 2017 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io';

import 'package:path/path.dart' as path;

/// Returns the test data path.
String getTestDataPath() {
  return path.normalize(
    path.join(
      Directory.current.path,
      'testdata',
    ),
  );
}
