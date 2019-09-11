// Copyright 2017 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:apps.modular.services.device/device_shell.fidl.dart';
import 'package:apps.mozart.lib.flutter/child_view.dart';
import 'package:apps.mozart.services.views/view_token.fidl.dart';
import 'package:flutter/widgets.dart';
import 'package:lib.fidl.dart/bindings.dart';

/// Called when an aunthentication overlay needs to be started.
typedef void OnStartOverlay(InterfaceHandle<ViewOwner> viewOwner);

/// An [AuthenticationContext] which calls its callbacks to show an overlay.
class AuthenticationContextImpl extends AuthenticationContext {
  /// Called when an aunthentication overlay needs to be started.
  final OnStartOverlay onStartOverlay;

  /// Called when an aunthentication overlay needs to be stopped.
  final VoidCallback onStopOverlay;

  /// Constructor.
  AuthenticationContextImpl({this.onStartOverlay, this.onStopOverlay});

  @override
  void startOverlay(InterfaceHandle<ViewOwner> viewOwner) =>
      onStartOverlay?.call(viewOwner);

  @override
  void stopOverlay() => onStopOverlay?.call();
}
