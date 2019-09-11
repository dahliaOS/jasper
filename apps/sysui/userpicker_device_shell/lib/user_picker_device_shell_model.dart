// Copyright 2017 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:apps.modular.services.auth.account/account.fidl.dart';
import 'package:apps.modular.services.device/device_shell.fidl.dart';
import 'package:apps.modular.services.device/user_provider.fidl.dart';
import 'package:flutter/material.dart';
import 'package:lib.logging/logging.dart';
import 'package:lib.widgets/modular.dart';

export 'package:lib.widgets/model.dart'
    show ScopedModel, ScopedModelDescendant, ModelFinder;

/// Contains all the relevant data for displaying the list of users and for
/// logging in and creating new users.
class UserPickerDeviceShellModel extends DeviceShellModel {
  bool _showingNetworkInfo = false;
  bool _showingUserActions = false;
  List<Account> _accounts;
  final ScrollController _userPickerScrollController = new ScrollController();

  /// The list of previously logged in accounts.
  List<Account> get accounts => _accounts;

  /// Scroll Controller for the user picker
  ScrollController get userPickerScrollController =>
      _userPickerScrollController;

  @override
  void onReady(
    UserProvider userProvider,
    DeviceShellContext deviceShellContext,
  ) {
    super.onReady(userProvider, deviceShellContext);
    _loadUsers();
    _userPickerScrollController.addListener(_scrollListener);
  }

  // Hide user actions on overscroll
  void _scrollListener() {
    if (_userPickerScrollController.offset >
        _userPickerScrollController.position.maxScrollExtent + 40.0) {
      hideUserActions();
    }
  }

  /// Refreshes the list of users.
  void refreshUsers() {
    _accounts = null;
    notifyListeners();
    _loadUsers();
  }

  void _loadUsers() {
    userProvider.previousUsers((List<Account> accounts) {
      print('accounts: $accounts');
      _accounts = new List<Account>.from(accounts);
      notifyListeners();
    });
  }

  /// Permanently removes the user.
  void removeUser(Account account) {
    userProvider.removeUser(account.id, (String errorCode) {
      if (errorCode != null && errorCode != "") {
        log.severe('Error in revoking credentials ${account.id}: $errorCode');
        refreshUsers();
        return;
      }

      _accounts.remove(account);
      notifyListeners();
      _loadUsers();
    });
  }

  /// Called when the network information starts showing.
  void onShowNetwork() {
    _showingNetworkInfo = true;
    notifyListeners();
  }

  /// Show advanced user actions such as:
  /// * Guest login
  /// * Create new account
  void showUserActions() {
    _showingUserActions = true;
    notifyListeners();
  }

  /// Hide advanced user actions such as:
  void hideUserActions() {
    _showingUserActions = false;
    notifyListeners();
  }

  /// Returns true once network information starts showing.
  bool get showingNetworkInfo => _showingNetworkInfo;

  /// If true, show advanced user actions
  bool get showingUserActions => _showingUserActions;
}
