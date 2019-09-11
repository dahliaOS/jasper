// Copyright 2016 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

/// Tracks an automatically increasing int [value].
class Sequence {
  int _value = 0;

  /// Create a [Sequence].
  Sequence();

  /// Retrieve the current value of the sequence.
  ///
  /// The [int] value returned will be sequentially increased by one every
  /// time it is retrieved.
  int get value {
    ++_value;
    return _value;
  }
}
