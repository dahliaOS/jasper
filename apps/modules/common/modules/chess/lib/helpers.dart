// Copyright 2017 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

/// Returns whether the given string is an integer value.
bool isAnInt(String s) {
  if (s == null) return false;
  return int.parse(s, onError: (String source) => null) != null;
}
