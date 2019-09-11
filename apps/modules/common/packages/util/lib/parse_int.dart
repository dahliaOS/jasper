// Copyright 2017 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

/// Parses a value to an integer
/// Handles cases when the value is already an integer
int parseInt(dynamic value, {int onError(String source)}) {
  if (value is int) {
    return value;
  } else {
    return int.parse(value, onError: onError);
  }
}
