// Copyright 2017 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:apps.modular.services.device/user_provider.fidl.dart';
import 'package:lib.fidl.dart/bindings.dart';
import 'package:flutter/widgets.dart';

/// Watches for changes to the user logged in status.
class UserWatcherImpl extends UserWatcher {
  final UserWatcherBinding _binding = new UserWatcherBinding();

  /// Called when the user logs out.
  final VoidCallback onUserLogout;

  /// Constructor.
  UserWatcherImpl({this.onUserLogout});

  /// Gets the handle of this [UserWatcher].
  InterfaceHandle<UserWatcher> getHandle() => _binding.wrap(this);

  @override
  void onLogout() {
    onUserLogout?.call();
  }

  /// Closes any handles owned by this [UserWatcher].
  void close() => _binding.close();
}
