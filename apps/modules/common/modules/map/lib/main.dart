// Copyright 2016 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert';

import 'package:application.lib.app.dart/app.dart';
import 'package:application.services/service_provider.fidl.dart';
import 'package:apps.modular.services.module/module.fidl.dart';
import 'package:apps.modular.services.module/module_context.fidl.dart';
import 'package:apps.modular.services.story/link.fidl.dart';
import 'package:config/config.dart';
import 'package:flutter/material.dart';
import 'package:lib.fidl.dart/bindings.dart';
import 'package:widgets/map.dart';

final ApplicationContext _context = new ApplicationContext.fromStartupInfo();

final GlobalKey<HomeScreenState> _kHomeKey = new GlobalKey<HomeScreenState>();

// This module expects to obtain the location string through the link
// provided from the parent, in the following document id / property key.
final String _kMapDocRoot = 'map-doc';
final String _kMapLocationKey = 'map-location-key';
final String _kMapHeightKey = 'map-height-key';
final String _kMapWidthKey = 'map-width-key';
final String _kMapZoomkey = 'map-zoom-key';

/// The location string.
String _mapLocation;

/// Height for map, this should most likely match the height of the child view
/// of the map module
double _mapHeight;

/// Width for map
double _mapWidth;

/// Zoom level for map
int _mapZoom;

ModuleImpl _module;

/// The api for Google Static Maps
String _apiKey;

void _log(String msg) {
  print('[map] $msg');
}

/// An implementation of the [LinkWatcher] interface.
class LinkWatcherImpl extends LinkWatcher {
  final LinkWatcherBinding _binding = new LinkWatcherBinding();

  /// Gets the [InterfaceHandle] for this [LinkWatcher] implementation.
  ///
  /// The returned handle should only be used once.
  InterfaceHandle<LinkWatcher> getHandle() => _binding.wrap(this);

  /// Correctly close the Link Binding
  void close() => _binding.close();

  @override
  void notify(String json) {
    _log('LinkWatcherImpl::notify call $json');

    final dynamic doc = json.decode(json);
    if (doc is! Map || doc[_kMapDocRoot] is! Map) {
      _log('No map root found in json.');
      return;
    }
    final Map<String, dynamic> mapDoc = doc[_kMapDocRoot];

    if (mapDoc[_kMapLocationKey] is! String ||
        mapDoc[_kMapHeightKey] is! double ||
        mapDoc[_kMapWidthKey] is! double ||
        mapDoc[_kMapZoomkey] is! int) {
      _log('Bad json values in LinkWatcherImpl.notify');
      return;
    }

    _mapLocation = mapDoc[_kMapLocationKey];
    _mapHeight = mapDoc[_kMapHeightKey];
    _mapWidth = mapDoc[_kMapWidthKey];
    _mapZoom = mapDoc[_kMapZoomkey];

    _log('_location: $_mapLocation');
    _log('_mapHeight: $_mapHeight');
    _log('_mapWidth: $_mapWidth');
    _log('_mapZoom: $_mapZoom');

    _kHomeKey.currentState?.updateUI();
  }
}

/// An implementation of the [Module] interface.
class ModuleImpl extends Module {
  final ModuleBinding _binding = new ModuleBinding();

  /// The [LinkProxy] from which this module gets the map parameters.
  final LinkProxy link = new LinkProxy();

  final LinkWatcherImpl _linkWatcher = new LinkWatcherImpl();

  /// Bind an [InterfaceRequest] for a [Module] interface to this object.
  void bind(InterfaceRequest<Module> request) {
    _binding.bind(this, request);
  }

  @override
  void initialize(
    InterfaceHandle<ModuleContext> moduleContextHandle,
    InterfaceHandle<ServiceProvider> incomingServicesHandle,
    InterfaceRequest<ServiceProvider> outgoingServices,
  ) {
    _log('ModuleImpl::initialize call');

    // Bind the link handle and register the link watcher.
    new ModuleContextProxy()
      ..ctrl.bind(moduleContextHandle)
      ..getLink(null, link.ctrl.request())
      ..ctrl.close();
    link.watchAll(_linkWatcher.getHandle());
  }

  @override
  void stop(void callback()) {
    _log('ModuleImpl::stop call');
    _linkWatcher.close();
    link.ctrl.close();
    callback();
  }
}

/// Main screen for this module.
class HomeScreen extends StatefulWidget {
  /// Creates a new instance of [HomeScreen].
  HomeScreen({Key key}) : super(key: key);

  @override
  HomeScreenState createState() => new HomeScreenState();
}

/// State class for the main screen widget.
class HomeScreenState extends State<HomeScreen> {
  @override
  Widget build(BuildContext context) {
    return new Container(
      alignment: FractionalOffset.center,
      constraints: const BoxConstraints.expand(),
      child: _mapLocation != null && _apiKey != null
          ? new StaticMap(
              location: _mapLocation,
              zoom: _mapZoom,
              width: _mapWidth,
              height: _mapHeight,
              apiKey: _apiKey,
            )
          : new CircularProgressIndicator(),
    );
  }

  /// Convenient method for other entities to call setState to cause UI updates.
  void updateUI() {
    _log('updateUI call');
    setState(() {});
  }
}

Future<Null> _readAPIKey() async {
  Config config = await Config.read('/system/data/modules/config.json');
  String googleApiKey = config.get('google_api_key');
  if (googleApiKey == null) {
    _log('"google_api_key" value is not specified in config.json.');
  } else {
    _log('"google_api_key" has been retrieved from config.json');
    _apiKey = googleApiKey;
    _kHomeKey.currentState?.updateUI();
  }
}

/// Main entry point to the email folder list module.
void main() {
  _log('Module started with context: $_context');

  /// Add [ModuleImpl] to this application's outgoing ServiceProvider.
  _context.outgoingServices.addServiceForName(
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

  _readAPIKey();

  runApp(new MaterialApp(
    title: 'Map',
    home: new HomeScreen(key: _kHomeKey),
    theme: new ThemeData(primarySwatch: Colors.blue),
    debugShowCheckedModeBanner: false,
  ));
}
