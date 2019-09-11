// Copyright 2017 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

/// Keeps track of the currently chosen user shell.
class UserShellChooser {
  final List<_UserShellEntry> _userShells = <_UserShellEntry>[
    new _UserShellEntry(
      assetName: 'packages/userpicker_device_shell/res/ArmadilloSilhouette.png',
      appUrl: 'armadillo_user_shell',
    ),
    new _UserShellEntry(
      assetName: 'packages/userpicker_device_shell/res/CapybaraSilhouette.png',
      appUrl: 'capybara_user_shell',
    ),
  ];

  int _currentUserShellIndex = 0;

  /// Chooses the next user shell in the list.
  void next() {
    _currentUserShellIndex = (_currentUserShellIndex + 1) % _userShells.length;
  }

  /// Gets the current user shell's asset name.
  String get assetName => _userShells[_currentUserShellIndex].assetName;

  /// Gets the current user shell's app url.
  String get appUrl => _userShells[_currentUserShellIndex].appUrl;
}

class _UserShellEntry {
  final String assetName;
  final String appUrl;
  _UserShellEntry({this.assetName, this.appUrl});
}
