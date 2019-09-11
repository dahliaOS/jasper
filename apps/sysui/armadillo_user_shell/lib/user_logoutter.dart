// Copyright 2017 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:apps.modular.services.user/user_shell.fidl.dart';

/// Performs the logging out of the user.
class UserLogoutter {
  UserShellContext _userShellContext;

  /// Set from an external source - typically the UserShell.
  set userShellContext(UserShellContext userShellContext) {
    _userShellContext = userShellContext;
  }

  /// Logs out the user.
  void logout() {
    _userShellContext?.logout();
  }

  /// Logs out the user and resets the user's ledger state at the same time.
  void logoutAndResetLedgerState() {
    _userShellContext?.logoutAndResetLedgerState();
  }
}
