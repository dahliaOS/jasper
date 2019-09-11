// Copyright 2016 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:path/path.dart' as path;

/// Resolve a pathname from $JIRI_ROOT/apps/modules/tools/auth.
String resolve(String pathname) {
  // The absolute directory relative to package:tools source root.
  String dirname = path.normalize(path.absolute('..'));
  return path.join(dirname, pathname);
}
