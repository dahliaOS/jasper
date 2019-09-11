// Copyright 2017 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:application.lib.app.dart/app.dart';
import 'package:apps.modular.services.module/module.fidl.dart';
import 'package:flutter/widgets.dart';
import 'package:lib.fidl.dart/bindings.dart';
import 'package:lib.modular/modular.dart';
import 'package:meta/meta.dart';

import '../widgets/window_media_query.dart';
import 'module_model.dart';

/// A wrapper widget intended to be the root of the application that is
/// a [Module].  Its main purpose is to hold the [ApplicationContext] and
/// [Module] instances so they aren't garbage collected.
/// For convenience, [advertise] does the advertising of the app as a
/// [Module] to the rest of the system via the [ApplicationContext].
/// Also for convienence, the [ModuleModel] given to this widget will be
/// made available to [child] and [child]'s descendants.
class ModuleWidget<T extends ModuleModel> extends StatelessWidget {
  final ModuleBinding _binding = new ModuleBinding();

  /// The [Module] to [advertise].
  final Module _module;

  /// The [ApplicationContext] to [advertise] its [Module] services to.
  final ApplicationContext applicationContext;

  /// The [ModuleModel] to notify when the [Module] is ready.
  final T _moduleModel;

  /// The rest of the application.
  final Widget child;

  /// Constructor.
  ModuleWidget({
    @required this.applicationContext,
    @required T moduleModel,
    @required this.child,
  })
      : _moduleModel = moduleModel,
        _module = new ModuleImpl(
          onReady: moduleModel?.onReady,
          onStop: moduleModel?.onStop,
          onNotify: moduleModel?.onNotify,
          watchAll: moduleModel?.watchAll,
          outgoingServiceProvider: moduleModel?.outgoingServiceProvider,
        );

  @override
  Widget build(BuildContext context) => new WindowMediaQuery(
        child: _moduleModel == null
            ? child
            : new ScopedModel<T>(
                model: _moduleModel,
                child: child,
              ),
      );

  /// Advertises [_module] as a [Module] to the rest of the system via the
  /// [applicationContext].
  void advertise() => applicationContext.outgoingServices.addServiceForName(
        (InterfaceRequest<Module> request) => _binding.bind(_module, request),
        Module.serviceName,
      );
}
