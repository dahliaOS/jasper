// Copyright 2017 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

/// The direction of a candidate being dragged.
enum DragDirection {
  /// The candidate is begin dragged from right to left.
  left,

  /// The candidate is begin dragged from left to right.
  right,

  /// The candidate is begin dragged from bottom to top.
  up,

  /// The candidate is begin dragged from top to bottom.
  down,

  /// The candidate is not being dragged in any particular direction.
  none,
}
