// Copyright 2017 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:application.services/service_provider.fidl.dart';
import 'package:apps.modular.services.module/module.fidl.dart';
import 'package:apps.modular.services.module/module_context.fidl.dart';
import 'package:apps.modular.services.story/link.fidl.dart';
import 'package:lib.widgets/model.dart';
import 'package:meta/meta.dart';

import 'module_widget.dart';

export 'package:lib.widgets/model.dart' show ScopedModel, ScopedModelDescendant;

/// A [Model] that waits for the [ModuleWidget] it's given to to call its
/// [onReady].  This [Model] will then be available to all children of
/// [ModuleWidget].
class ModuleModel extends Model {
  ModuleContext _moduleContext;
  Link _link;
  ServiceProvider _incomingServiceProvider;

  final Completer<Null> _readyCompleter = new Completer<Null>();

  /// Indicates whether the [LinkWatcher] should watch for all changes including
  /// the changes made by this [Module]. If [true], it calls [Link.watchAll] to
  /// register the [LinkWatcher], and [Link.watch] otherwise. Only takes effect
  /// when the [onNotify] callback is also provided. Defaults to false.
  final bool watchAll;

  /// Creates a new instance of [ModuleModel].
  ModuleModel({bool watchAll}) : watchAll = watchAll ?? false;

  /// The [ModuleContext] given to this [Module].
  ModuleContext get moduleContext => _moduleContext;

  /// The [Link] given to this [Module].
  Link get link => _link;

  /// The [ServiceProvider] given to this [Module] as incoming services.
  ServiceProvider get incomingServiceProvider => _incomingServiceProvider;

  /// The [ServiceProvider] exposed to the parent module. Modules should
  /// override this to provide an actual instance, if they wish to expose
  /// outgoing services to their parents.
  ServiceProvider get outgoingServiceProvider => null;

  /// Gets a [Future] object which completes when [onReady] is called.
  Future<Null> get ready => _readyCompleter.future;

  /// Called when this [Module] is given its [ModuleContext],
  /// [Link], an incoming services [ServiceProvider].
  @mustCallSuper
  void onReady(
    ModuleContext moduleContext,
    Link link,
    ServiceProvider incomingServiceProvider,
  ) {
    _moduleContext = moduleContext;
    _link = link;
    _incomingServiceProvider = incomingServiceProvider;

    _readyCompleter.complete();

    notifyListeners();
  }

  /// Called when the [Module] stops.
  void onStop() => null;

  /// Called when [LinkWatcher.notify] is called.
  void onNotify(String json) => null;
}
