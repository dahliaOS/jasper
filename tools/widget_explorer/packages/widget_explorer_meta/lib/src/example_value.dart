// Copyright 2017 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

/// An annotation for specifying an example parameter value of a UI widget.
class ExampleValue {
  /// Creates a new instance of [ExampleValue].
  const ExampleValue(this.value);

  /// The example value.
  final dynamic value;
}
