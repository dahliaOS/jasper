// Copyright 2016 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

/// Represents the state of data loading
enum LoadingState {
  /// Still fetching data
  inProgress,

  /// Data has completed loading
  completed,

  /// Data failed to load
  failed,
}
