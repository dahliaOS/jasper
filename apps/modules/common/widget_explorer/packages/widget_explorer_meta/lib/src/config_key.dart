// Copyright 2017 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

/// An annotation for specifying a value to be retrieved from the config file.
class ConfigKey {
  /// Creates a new instance of [ConfigKey].
  const ConfigKey(this.key);

  /// The string key of the config value.
  final String key;
}
