// Copyright 2017 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:application.lib.app.dart/app.dart';
import 'package:apps.modular.services.device/device_shell.fidl.dart';
import 'package:apps.mozart.services.input/ime_service.fidl.dart';
import 'package:flutter/widgets.dart';
import 'package:lib.fidl.dart/bindings.dart';
import 'package:lib.modular/modular.dart';
import 'package:meta/meta.dart';

import '../widgets/window_media_query.dart';
import 'device_shell_model.dart';

/// A wrapper widget intended to be the root of the application that is
/// a [DeviceShell].  Its main purpose is to hold the [ApplicationContext] and
/// [DeviceShell] instances so they aren't garbage collected.
/// For convenience, [advertise] does the advertising of the app as a
/// [DeviceShell] to the rest of the system via the [ApplicationContext].
/// Also for convienence, the [DeviceShellModel] given to this widget
/// will be made available to [child] and [child]'s descendants.
class DeviceShellWidget<T extends DeviceShellModel> extends StatelessWidget {
  /// The [ApplicationContext] to [advertise] its [DeviceShell] services to.
  final ApplicationContext applicationContext;
  final Set<DeviceShellBinding> _deviceShellBindingSet =
      new Set<DeviceShellBinding>();
  final Set<SoftKeyboardContainerBinding> _softKeyboardContainerBindingSet =
      new Set<SoftKeyboardContainerBinding>();

  /// The [DeviceShell] to [advertise].
  final DeviceShellImpl _deviceShell;

  /// The rest of the application.
  final Widget child;

  /// A service that displays a soft keyboard.
  final SoftKeyboardContainer softKeyboardContainer;

  final T _deviceShellModel;

  /// Constructor.
  DeviceShellWidget({
    @required this.applicationContext,
    T deviceShellModel,
    AuthenticationContext authenticationContext,
    this.softKeyboardContainer,
    this.child,
  })
      : _deviceShellModel = deviceShellModel,
        _deviceShell = _createDeviceShell(
          deviceShellModel,
          authenticationContext,
        );

  @override
  Widget build(BuildContext context) => new WindowMediaQuery(
        child: _deviceShellModel == null
            ? child
            : new ScopedModel<T>(model: _deviceShellModel, child: child),
      );

  /// Advertises [_deviceShell] as a [DeviceShell] to the rest of the system via
  /// the [ApplicationContext].
  void advertise() {
    applicationContext.outgoingServices.addServiceForName(
      (InterfaceRequest<DeviceShell> request) {
        DeviceShellBinding binding = new DeviceShellBinding();
        binding.bind(_deviceShell, request);
        _deviceShellBindingSet.add(binding);
      },
      DeviceShell.serviceName,
    );
    if (softKeyboardContainer != null) {
      applicationContext.outgoingServices.addServiceForName(
        (InterfaceRequest<SoftKeyboardContainer> request) {
          SoftKeyboardContainerBinding binding =
              new SoftKeyboardContainerBinding();
          binding.bind(softKeyboardContainer, request);
          _softKeyboardContainerBindingSet.add(binding);
        },
        SoftKeyboardContainer.serviceName,
      );
    }
  }

  static DeviceShell _createDeviceShell(
    DeviceShellModel deviceShellModel,
    AuthenticationContext authenticationContext,
  ) {
    DeviceShellImpl deviceShell;
    VoidCallback onStop = () {
      deviceShellModel?.onStop?.call();
      deviceShell.onStop();
    };
    deviceShell = new DeviceShellImpl(
      authenticationContext: authenticationContext,
      onReady: deviceShellModel?.onReady,
      onStop: onStop,
    );
    return deviceShell;
  }
}
