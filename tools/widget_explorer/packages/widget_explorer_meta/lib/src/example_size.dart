// Copyright 2017 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

/// An annotation for specifying an example dimensions of a UI widget.
class ExampleSize {
  /// Creates a new instance of [ExampleSize].
  const ExampleSize(this.width, this.height);

  /// The widget value.
  final double width;

  /// The height value.
  final double height;
}
