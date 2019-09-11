// Copyright 2017 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:application.services/service_provider.fidl.dart';
import 'package:apps.modular.services.module/module.fidl.dart';
import 'package:apps.modular.services.module/module_context.fidl.dart';
import 'package:apps.modular.services.story/link.fidl.dart';
import 'package:lib.fidl.dart/bindings.dart';

import 'link_watcher_impl.dart';

/// Called when [Module.initialize] occurs.
typedef void OnModuleReady(
  ModuleContext moduleContext,
  Link link,
  ServiceProvider incomingServiceProvider,
);

/// Called when [Module.stop] occurs.
typedef void OnModuleStop();

/// Implements a Module for receiving the services a [Module] needs to
/// operate.  When [initialize] is called, the services it receives are routed
/// by this class to the various classes which need them.
class ModuleImpl extends Module {
  final ModuleContextProxy _moduleContextProxy = new ModuleContextProxy();
  final LinkProxy _linkProxy = new LinkProxy();
  final ServiceProviderProxy _incomingServiceProviderProxy =
      new ServiceProviderProxy();
  final ServiceProviderBinding _outgoingServiceProviderBinding =
      new ServiceProviderBinding();

  LinkWatcherBinding _linkWatcherBinding;
  LinkWatcherImpl _linkWatcherImpl;

  /// The [ServiceProvider] to provide when outgoing services are requested.
  final ServiceProvider outgoingServiceProvider;

  /// Called when [Module] is initialied with its services.
  final OnModuleReady onReady;

  /// Called when [Module] is stopped.
  final OnModuleStop onStop;

  /// Called when [LinkWatcher.notify] is called.
  final OnNotify onNotify;

  /// Indicates whether the [LinkWatcher] should watch for all changes including
  /// the changes made by this [Module]. If [true], it calls [Link.watchAll] to
  /// register the [LinkWatcher], and [Link.watch] otherwise. Only takes effect
  /// when the [onNotify] callback is also provided. Defaults to false.
  final bool watchAll;

  /// Constuctor.
  ModuleImpl({
    this.outgoingServiceProvider,
    this.onReady,
    this.onStop,
    this.onNotify,
    bool watchAll,
  })
      : watchAll = watchAll ?? false;

  @override
  void initialize(
    InterfaceHandle<ModuleContext> moduleContext,
    InterfaceHandle<ServiceProvider> incomingServices,
    InterfaceRequest<ServiceProvider> outgoingServices,
  ) {
    if (onReady != null) {
      _moduleContextProxy.ctrl.bind(moduleContext);
      _moduleContextProxy.getLink(null, _linkProxy.ctrl.request());

      if (incomingServices != null) {
        _incomingServiceProviderProxy.ctrl.bind(incomingServices);
      }

      onReady(_moduleContextProxy, _linkProxy, _incomingServiceProviderProxy);
    }

    if (outgoingServices != null && outgoingServiceProvider != null) {
      _outgoingServiceProviderBinding.bind(
        outgoingServiceProvider,
        outgoingServices,
      );
    }

    if (onNotify != null) {
      _linkWatcherImpl = new LinkWatcherImpl(onNotify: onNotify);
      _linkWatcherBinding = new LinkWatcherBinding();

      if (watchAll) {
        _linkProxy.watchAll(_linkWatcherBinding.wrap(_linkWatcherImpl));
      } else {
        _linkProxy.watch(_linkWatcherBinding.wrap(_linkWatcherImpl));
      }
    }
  }

  @override
  void stop(void done()) {
    onStop?.call();
    _linkWatcherBinding?.close();
    _moduleContextProxy.ctrl.close();
    _linkProxy.ctrl.close();
    _incomingServiceProviderProxy.ctrl.close();
    _outgoingServiceProviderBinding.close();
    done();
  }
}
