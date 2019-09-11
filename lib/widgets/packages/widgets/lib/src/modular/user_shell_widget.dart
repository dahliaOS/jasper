// Copyright 2017 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:application.lib.app.dart/app.dart';
import 'package:apps.modular.services.user/user_shell.fidl.dart';
import 'package:flutter/widgets.dart';
import 'package:lib.fidl.dart/bindings.dart';
import 'package:lib.modular/modular.dart';

import '../widgets/window_media_query.dart';
import 'user_shell_model.dart';

/// A wrapper widget intended to be the root of the application that is
/// a [UserShell].  Its main purpose is to hold the [ApplicationContext] and
/// [UserShell] instances so they aren't garbage collected.
/// For convenience, [advertise] does the advertising of the app as a
/// [UserShell] to the rest of the system via the [ApplicationContext].
/// Also for convienence, the [UserShellModel] given to this widget
/// will be made available to [child] and [child]'s descendants.
class UserShellWidget<T extends UserShellModel> extends StatelessWidget {
  /// The [ApplicationContext] to [advertise] its [UserShell] services to.
  final ApplicationContext applicationContext;

  final UserShellBinding _binding = new UserShellBinding();

  /// The [UserShell] to [advertise].
  final UserShellImpl _userShell;

  /// The rest of the application.
  final Widget child;

  final T _userShellModel;

  /// Constructor.
  UserShellWidget({
    this.applicationContext,
    T userShellModel,
    this.child,
  })
      : _userShellModel = userShellModel,
        _userShell = new UserShellImpl(
          onReady: userShellModel?.onReady,
          onStop: userShellModel?.onStop,
        );

  @override
  Widget build(BuildContext context) => new WindowMediaQuery(
        child: _userShellModel == null
            ? child
            : new ScopedModel<T>(
                model: _userShellModel,
                child: child,
              ),
      );

  /// Advertises [_userShell] as a [UserShell] to the rest of the system via
  /// the [ApplicationContext].
  void advertise() => applicationContext.outgoingServices.addServiceForName(
        (InterfaceRequest<UserShell> request) =>
            _binding.bind(_userShell, request),
        UserShell.serviceName,
      );
}
