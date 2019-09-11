// Copyright 2017 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:apps.modular.services.device/device_shell.fidl.dart';
import 'package:apps.modular.services.device/user_provider.fidl.dart';
import 'package:lib.fidl.dart/bindings.dart';
import 'package:meta/meta.dart';

/// Called when [DeviceShell.initialize] occurs.
typedef void OnDeviceShellReady(
  UserProvider userProvider,
  DeviceShellContext deviceShellContext,
);

/// Called when [DeviceShell.terminate] occurs.
typedef void OnDeviceShellStop();

/// Implements a DeviceShell for receiving the services a [DeviceShell] needs to
/// operate.
class DeviceShellImpl extends DeviceShell {
  final DeviceShellContextProxy _deviceShellContextProxy =
      new DeviceShellContextProxy();
  final UserProviderProxy _userProviderProxy = new UserProviderProxy();
  final Set<AuthenticationContextBinding> _bindingSet =
      new Set<AuthenticationContextBinding>();

  /// Called when [initialize] occurs.
  final OnDeviceShellReady onReady;

  /// Called when the [DeviceShell] terminates.
  final OnDeviceShellStop onStop;

  /// The [AuthenticationContext] to provide when requested.
  final AuthenticationContext authenticationContext;

  /// Constructor.
  DeviceShellImpl({
    @required this.authenticationContext,
    this.onReady,
    this.onStop,
  });

  @override
  void initialize(
    InterfaceHandle<DeviceShellContext> deviceShellContextHandle,
  ) {
    if (onReady != null) {
      _deviceShellContextProxy.ctrl.bind(deviceShellContextHandle);
      _deviceShellContextProxy
          .getUserProvider(_userProviderProxy.ctrl.request());
      onReady(_userProviderProxy, _deviceShellContextProxy);
    }
  }

  @override
  void terminate(void done()) {
    onStop?.call();
    _userProviderProxy.ctrl.close();
    _deviceShellContextProxy.ctrl.close();
    _bindingSet.forEach(
      (AuthenticationContextBinding binding) => binding.close(),
    );
    done();
  }

  @override
  void getAuthenticationContext(
    String username,
    InterfaceRequest<AuthenticationContext> request,
  ) {
    AuthenticationContextBinding binding = new AuthenticationContextBinding();
    binding.bind(authenticationContext, request);
    _bindingSet.add(binding);
  }
}
