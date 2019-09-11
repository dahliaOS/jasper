// Copyright 2016 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';

import 'package:application.lib.app.dart/app.dart';
import 'package:application.services/service_provider.fidl.dart';
import 'package:apps.modular.services.module/module.fidl.dart';
import 'package:apps.modular.services.module/module_context.fidl.dart';
import 'package:apps.modular.services.story/link.fidl.dart';
import 'package:flutter/material.dart';
import 'package:lib.fidl.dart/bindings.dart';
import 'package:widgets/youtube.dart';

final ApplicationContext _context = new ApplicationContext.fromStartupInfo();

final GlobalKey<HomeScreenState> _kHomeKey = new GlobalKey<HomeScreenState>();

// This module expects to obtain the youtube video id string through the link
// provided from the parent, in the following document id / property key.
// The JSON string in the Link looks something like this:
// { "youtube-doc" : { "youtube-video-id" : "https://www.youtube.com/blah" } }
// TODO(youngseokyoon): add this information to the module manifest.
final String _kYoutubeDocRoot = 'youtube-doc';
final String _kYoutubeVideoIdKey = 'youtube-video-id';

ModuleImpl _module;

// The youtube video id.
String _videoId;

void _log(String msg) {
  print('[youtube_thumbnail] $msg');
}

/// An implementation of the [LinkWatcher] interface.
class LinkWatcherImpl extends LinkWatcher {
  final LinkWatcherBinding _binding = new LinkWatcherBinding();

  /// Gets the [InterfaceHandle] for this [LinkWatcher] implementation.
  ///
  /// The returned handle should only be used once.
  InterfaceHandle<LinkWatcher> getHandle() => _binding.wrap(this);

  @override
  void notify(String json) {
    _log('LinkWatcherImpl::notify call');

    final dynamic doc = json.decode(json);
    if (doc is! Map ||
        doc[_kYoutubeDocRoot] is! Map ||
        doc[_kYoutubeDocRoot][_kYoutubeVideoIdKey] is! String) {
      _log('No youtube key found in json.');
      return;
    }

    _videoId = doc[_kYoutubeDocRoot][_kYoutubeVideoIdKey];

    _log('_videoId: $_videoId');
    _kHomeKey.currentState?.updateUI();
  }
}

/// An implementation of the [Module] interface.
class ModuleImpl extends Module {
  final ModuleBinding _binding = new ModuleBinding();

  /// The [LinkProxy] from which this module gets the youtube video id.
  final LinkProxy link = new LinkProxy();

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

    new ModuleContextProxy()
      ..ctrl.bind(moduleContextHandle)
      ..getLink(null, link.ctrl.request())
      ..ctrl.close();

    link.watchAll(new LinkWatcherImpl().getHandle());
  }

  @override
  void stop(void callback()) {
    _log('ModuleImpl::stop call');
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
      child: _videoId != null
          ? new YoutubeThumbnail(
              videoId: _videoId,
              onSelect: (String id) => _log('Thumbnail Selected: $id'),
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

  runApp(new MaterialApp(
    title: 'Youtube Thumbnail',
    home: new HomeScreen(key: _kHomeKey),
    theme: new ThemeData(primarySwatch: Colors.blue),
    debugShowCheckedModeBanner: false,
  ));
}
