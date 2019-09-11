// Copyright 2017 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:application.lib.app.dart/app.dart';
import 'package:application.services/service_provider.fidl.dart';
import 'package:apps.modular.services.module/module.fidl.dart';
import 'package:apps.modular.services.module/module_context.fidl.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:lib.fidl.dart/bindings.dart';

import 'board.dart';

final ApplicationContext _appContext = new ApplicationContext.fromStartupInfo();

ModuleImpl _module;

void _log(String msg) {
  print('[Chess] $msg');
}

/// An implementation of the [Module] interface.
class ModuleImpl extends Module {
  final ModuleBinding _binding = new ModuleBinding();

  /// Bind an [InterfaceRequest] for a [Module] interface to this object.
  void bind(InterfaceRequest<Module> request) {
    _binding.bind(this, request);
  }

  /// Implementation of the Initialize method.
  @override
  void initialize(
    InterfaceHandle<ModuleContext> moduleContextHandle,
    InterfaceHandle<ServiceProvider> incomingServices,
    InterfaceRequest<ServiceProvider> outgoingServices,
  ) {
    _log('ModuleImpl::initialize call');
  }

  /// Implementation of the Stop() => (); method.
  @override
  void stop(void callback()) {
    _log('ModuleImpl::stop call');
    // Do some clean up here.

    // Invoke the callback to signal that the clean-up process is done.
    callback();
  }
}

/// Entry point for this module.
void main() {
  _log('Module started with ApplicationContext: $_appContext');

  /// Add [ModuleImpl] to this application's outgoing ServiceProvider.
  _appContext.outgoingServices.addServiceForName(
    (InterfaceRequest<Module> request) {
      _log('Received binding request for Module');
      if (_module != null) {
        _log('Module interface can only be provided once. Rejecting request.');
        request.channel.close();
        return;
      }
      _module = new ModuleImpl()..bind(request);
    },
    Module.serviceName,
  );

  runApp(new MyApp());
}

/// Top-level widget for this app.
class MyApp extends StatefulWidget {
  // This widget is the root of your application.
  @override
  _MyAppState createState() => new _MyAppState();
}

class _MyAppState extends State<MyApp> {
  void pieceMoved(Map<String, dynamic> data) {}

  @override
  Widget build(BuildContext context) {
    return new MaterialApp(
      title: 'Chesswise',
      theme: new ThemeData(primarySwatch: Colors.cyan),
      // home: new Board('Your', pieceMoved),
      home: new Board(),
    );
  }
}
