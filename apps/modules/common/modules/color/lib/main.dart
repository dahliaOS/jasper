// Copyright 2016 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';

import 'package:application.lib.app.dart/app.dart';
import 'package:application.services/service_provider.fidl.dart';
import 'package:apps.modular.services.module/module.fidl.dart';
import 'package:apps.modular.services.module/module_context.fidl.dart';
import 'package:apps.modular.services.story/link.fidl.dart';
import 'package:flutter/widgets.dart';
import 'package:lib.fidl.dart/bindings.dart';
import 'package:util/parse_int.dart';

final ApplicationContext _context = new ApplicationContext.fromStartupInfo();

final ModuleBinding _moduleBinding = new ModuleBinding();

/// Main entry point to the color module.
void main() {
  _log('Color module started with context: $_context');

  final GlobalKey<_ColorWidgetState> colorWidgetKey =
      new GlobalKey<_ColorWidgetState>();

  /// Add _ModuleImpl to this application's outgoing ServiceProvider.
  _context.outgoingServices.addServiceForName(
    (InterfaceRequest<Module> request) {
      _moduleBinding.bind(
        new _ModuleImpl(
          (String json) {
            _log('JSON: $json');
            // Expects Link to look something like this:
            // { "color" : 255 } or { "color" : '0xFF1DE9B6' }
            final dynamic doc = json.decode(json);
            if (doc is Map && (doc['color'] is int || doc['color'] is String)) {
              int num = parseInt(doc['color']);
              colorWidgetKey.currentState.color = new Color(num);
            }
          },
        ),
        request,
      );
    },
    Module.serviceName,
  );

  runApp(new _ColorWidget(key: colorWidgetKey));
}

void _log(String msg) {
  print('[Color Module] $msg');
}

typedef void _OnNotify(String json);

class _LinkWatcherImpl extends LinkWatcher {
  final _OnNotify _onNotify;

  _LinkWatcherImpl(this._onNotify);

  @override
  void notify(String json) {
    _onNotify?.call(json);
  }
}

/// An implementation of the [Module] interface.
class _ModuleImpl extends Module {
  /// [Link] service provided by the framework.
  final LinkProxy _link = new LinkProxy();

  final LinkWatcherBinding _linkWatcherBinding = new LinkWatcherBinding();

  final _OnNotify _onNotify;

  _ModuleImpl(this._onNotify);

  /// Implementation of the Initialize(Story story, Link link) method.
  @override
  void initialize(
    InterfaceHandle<ModuleContext> moduleContextHandle,
    InterfaceHandle<ServiceProvider> incomingServices,
    InterfaceRequest<ServiceProvider> outgoingServices,
  ) {
    _log('ModuleImpl::initialize call');
    new ModuleContextProxy()
      ..ctrl.bind(moduleContextHandle)
      ..getLink(null, _link.ctrl.request())
      ..ctrl.close();

    _link.watch(_linkWatcherBinding.wrap(new _LinkWatcherImpl(_onNotify)));
  }

  @override
  void stop(void callback()) {
    _log('ModuleImpl::stop call');

    _link.ctrl.close();
    _linkWatcherBinding.close();

    // Invoke the callback to signal that the clean-up process is done.
    callback();
  }
}

class _ColorWidget extends StatefulWidget {
  _ColorWidget({Key key}) : super(key: key);

  @override
  _ColorWidgetState createState() => new _ColorWidgetState();
}

class _ColorWidgetState extends State<_ColorWidget> {
  Color _color = new Color(0x00000000);

  set color(Color color) {
    setState(() {
      _color = color;
    });
  }

  @override
  Widget build(BuildContext context) => new Container(color: _color);
}
