// Copyright 2016 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert';

import 'package:application.lib.app.dart/app.dart';
import 'package:application.services/service_provider.fidl.dart';
import 'package:apps.modular.services.module/module.fidl.dart';
import 'package:apps.modular.services.module/module_context.fidl.dart';
import 'package:apps.modular.services.module/module_controller.fidl.dart';
import 'package:apps.modular.services.story/link.fidl.dart';
import 'package:apps.mozart.lib.flutter/child_view.dart';
import 'package:apps.mozart.services.views/view_token.fidl.dart';
import 'package:config/config.dart';
import 'package:flutter/material.dart';
import 'package:lib.fidl.dart/bindings.dart';
import 'package:widgets/usps.dart';

final ApplicationContext _context = new ApplicationContext.fromStartupInfo();

final GlobalKey<HomeScreenState> _kHomeKey = new GlobalKey<HomeScreenState>();

// This module expects to obtain the USPS tracking code string through the link
// provided from the parent, in the following document id / property key.
final String _kMapDocRoot = 'map-doc';
final String _kMapLocationKey = 'map-location-key';
final String _kMapHeightKey = 'map-height-key';
final String _kMapWidthKey = 'map-width-key';
final String _kMapZoomkey = 'map-zoom-key';
final int _kMapZoomValue = 10;
final double _kMapHeightValue = 200.0;
final double _kMapWidthValue = 1200.0;

final String _kMapModuleUrl = 'file:///system/apps/map';

ModuleImpl _module;

// TODO(dayang): Remove when we have a parent module passes in a this through
// the link.
/// A USPS tracking code for a given package
/// Hard coding the tracking code for now
String _trackingCode = '9374889676090175041871';

/// The api key for the USPS tracking service
String _apiKey;

void _log(String msg) {
  print('[usps] $msg');
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
    _log('LinkWatcherImpl::notify call');

    final dynamic doc = json.decode(json);
    try {
      _trackingCode = doc['view']['query parameters']['qtc_tLabels1'];
    } catch (_) {
      _trackingCode = null;
    }

    if (_trackingCode == null) {
      _log('No usps tracking key found in json.');
    } else {
      _log('_trackingCode: $_trackingCode');
      _kHomeKey.currentState?.updateUI();
    }
  }
}

/// An implementation of the [Module] interface.
class ModuleImpl extends Module {
  final ModuleBinding _binding = new ModuleBinding();

  /// [ModuleContext] service provided by the framework.
  final ModuleContextProxy moduleContext = new ModuleContextProxy();

  /// The [LinkProxy] from which this module gets the tracking code
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

    moduleContext.ctrl.bind(moduleContextHandle);
    moduleContext.getLink(null, link.ctrl.request());
    link.watchAll(_linkWatcher.getHandle());

    _readAPIKey();

    _addEmbeddedChildBuilders();

    runApp(new MaterialApp(
      title: 'USPS Tracking',
      home: new HomeScreen(key: _kHomeKey),
      theme: new ThemeData(primarySwatch: Colors.blue),
      debugShowCheckedModeBanner: false,
    ));

    // Initially set the location to null
    // We wont know the location until the USPS logic runs and fetches the
    // locations
    updateLocation('');
  }

  /// Update Link with location
  void updateLocation(String location) {
    _log('location is updated to: $location');
    Map<String, dynamic> mapDoc = <String, dynamic>{
      _kMapZoomkey: _kMapZoomValue,
      _kMapHeightKey: _kMapHeightValue,
      _kMapWidthKey: _kMapWidthValue,
      _kMapLocationKey: location,
    };

    link.updateObject(<String>[_kMapDocRoot], JSON.encode(mapDoc));
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
    return new Material(
      color: Colors.white,
      child: new Container(
        alignment: FractionalOffset.center,
        constraints: const BoxConstraints.expand(),
        color: Colors.white,
        child: new Container(
          constraints: const BoxConstraints.expand(),
          child: _trackingCode != null && _apiKey != null
              ? new TrackingStatus(
                  trackingCode: _trackingCode,
                  apiKey: _apiKey,
                  onLocationSelect: (String location) {
                    _log('selecting location: $location');
                    _module.updateLocation(location);
                  })
              : new Text('Error: either _trackingCode or _apiKey is null. '
                  'Please check if you have "usps_api_key" in your'
                  'config.json file.'),
        ),
      ),
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
  String uspsApiKey = config.get('usps_api_key');
  if (uspsApiKey == null) {
    _log('"usps_aki_key" value is not specified in config.json.');
  } else {
    _log('"usps_api_key" has been retrieved form config.json');
    _apiKey = uspsApiKey;
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
      _module = new ModuleImpl()..bind(request);
    },
    Module.serviceName,
  );
}

/// Adds all the [EmbeddedChildBuilder]s that this module supports.
void _addEmbeddedChildBuilders() {
  // USPS Tracking.
  _log("calling addEmbeddedChildBuilder('map')");
  kEmbeddedChildProvider.addEmbeddedChildBuilder(
    'map',
    (dynamic args) {
      _log('trying to launch map!');
      // Initialize the sub-module.
      ModuleControllerProxy moduleController = new ModuleControllerProxy();
      InterfacePair<ViewOwner> viewOwnerPair = new InterfacePair<ViewOwner>();

      _log('before startModule!');
      _module.moduleContext.startModule(
        'map',
        _kMapModuleUrl,
        null, // Pass our default link down.
        null,
        null,
        moduleController.ctrl.request(),
        viewOwnerPair.passRequest(),
      );
      _log('after startModule!');

      InterfaceHandle<ViewOwner> viewOwner = viewOwnerPair.passHandle();
      ChildViewConnection conn = new ChildViewConnection(viewOwner);

      return new EmbeddedChild(
        widgetBuilder: (BuildContext context) {
          ChildView childView = new ChildView(connection: conn);
          _log('widgetBuilder call. conn: $conn, childView: $childView');
          return childView;
        },
        disposer: () {
          moduleController.stop(() {
            viewOwner.close();
            // NOTE(youngseokyoon): Not sure if it is safe to close the module
            // controller within a callback passed to module controller, so do
            // it in the next idle cycle.
            scheduleMicrotask(() {
              moduleController.ctrl.close();
            });
          });
        },
        additionalData: <dynamic>[moduleController, conn],
      );
    },
  );
  _log("called addEmbeddedChildBuilder('map')");
}
