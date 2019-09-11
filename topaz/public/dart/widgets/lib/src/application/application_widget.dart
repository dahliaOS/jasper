// Copyright 2017 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:application.lib.app.dart/app.dart';
import 'package:application.services/application_controller.fidl.dart';
import 'package:application.services/application_launcher.fidl.dart';
import 'package:application.services/service_provider.fidl.dart';
import 'package:apps.mozart.lib.flutter/child_view.dart';
import 'package:apps.mozart.services.views/view_provider.fidl.dart';
import 'package:flutter/widgets.dart';
import 'package:lib.fidl.dart/bindings.dart';
import 'package:meta/meta.dart';

/// A [Widget] that displays the view of the application it launches.
class ApplicationWidget extends StatefulWidget {
  /// The application to launch.
  final String url;

  /// The [ApplicationLauncher] used to launch the application.
  final ApplicationLauncher launcher;

  /// Called if the application terminates.
  final VoidCallback onDone;

  /// Child can be hit tested.
  final bool hitTestable;

  /// Constructor.
  ApplicationWidget({
    Key key,
    @required this.url,
    @required this.launcher,
    this.onDone,
    this.hitTestable: true,
  })
      : super(key: key);

  @override
  _ApplicationWidgetState createState() => new _ApplicationWidgetState();
}

class _ApplicationWidgetState extends State<ApplicationWidget> {
  ApplicationControllerProxy _applicationController;
  ChildViewConnection _connection;

  @override
  void initState() {
    super.initState();
    _launchApp();
  }

  @override
  void didUpdateWidget(ApplicationWidget old) {
    super.didUpdateWidget(old);
    if (old.url == widget.url && old.launcher == widget.launcher) {
      return;
    }

    _cleanUp();
    _launchApp();
  }

  @override
  void dispose() {
    _cleanUp();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => new ChildView(
        connection: _connection,
        hitTestable: widget.hitTestable,
      );

  void _cleanUp() {
    _applicationController.ctrl.close();
    _connection = null;
  }

  void _launchApp() {
    _applicationController = new ApplicationControllerProxy();

    ServiceProviderProxy incomingServices = new ServiceProviderProxy();
    widget.launcher.createApplication(
      new ApplicationLaunchInfo()
        ..url = widget.url
        ..services = incomingServices.ctrl.request(),
      _applicationController.ctrl.request(),
    );

    _connection = new ChildViewConnection(
      _consumeViewProvider(
        _consumeServiceProvider(incomingServices),
      ),
      onAvailable: (_) {},
      onUnavailable: (_) => widget.onDone?.call(),
    );
  }

  /// Creates a [ViewProviderProxy] from a [ServiceProviderProxy], closing it in
  /// the process.
  ViewProviderProxy _consumeServiceProvider(
    ServiceProviderProxy serviceProvider,
  ) {
    ViewProviderProxy viewProvider = new ViewProviderProxy();
    connectToService(serviceProvider, viewProvider.ctrl);
    serviceProvider.ctrl.close();
    return viewProvider;
  }

  /// Creates a handle to a [ViewOwner] from a [ViewProviderProxy], closing it in
  /// the process.
  InterfaceHandle<ViewOwner> _consumeViewProvider(
    ViewProviderProxy viewProvider,
  ) {
    InterfacePair<ViewOwner> viewOwner = new InterfacePair<ViewOwner>();
    viewProvider.createView(viewOwner.passRequest(), null);
    viewProvider.ctrl.close();
    return viewOwner.passHandle();
  }
}
