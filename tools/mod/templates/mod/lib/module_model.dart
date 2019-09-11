// Copyright 2018 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert' show json;

import 'package:fidl_fuchsia_modular/fidl.dart';
import 'package:lib.app.dart/logging.dart';
import 'package:lib.widgets/modular.dart';

/// The [ModuleModel] implementation for this project, which encapsulates how
/// this module interacts with the Modular framework.
///
/// There are three methods that you can override, as shown in the code below.
///
/// * [onReady]: This method is called when [Module.initialized()] is called by
///   the framework. You must call [super.onReady()] method, and you can do any
///   additional initialization work needed for this module.
///
/// * [onStop]: This method is called when [Lifecycle.terminate()] is called by
///   the framework. You must clean up any resources, close any FIDL channels,
///   and call [super.onStop()] method.
///
/// * [onNotify]: This method can be overriden, when you want to process change
///   notifications coming from the [Link] service. In this example, we read the
///   counter value from the json, and notify all the listeners so that they can
///   refresh the UI with the new data.
///
/// In the example code below, the counter value is stored in [Link], which is a
/// synchronized, persistent data storage provided by the Modular framework.
/// [Link] stores data in JSON format, so the data should be properly encoded /
/// decoded, when setting and retrieving data.
///
/// Storing this value in [Link] has a few implications.
///
/// * When this module is running in the same story on multiple devices, any
///   changes to counter value on any device is seen by other devices. That is,
///   the [onNotify()] method will be called on all instances of this module and
///   they would be able to update the UI accordingly.
///
/// * The value is persisted and be restored across reboot. When cloudsync is
///   enabled on Fuchsia, the value will be restored correctly even on a
///   previously unused device.
///
/// For other states that are not needed to be synchronized or persisted (e.g.,
/// transient UI states, animation states) can be stored in a `State` of a
/// `StatefulWidget`, as in normal Flutter applications.
class __ProjectName__ModuleModel extends ModuleModel {
  /// Creates a new instance.
  ///
  /// Setting the [watchAll] value to `true` makes sure that you get notified
  /// by [Link] service, even with the changes are made by this model.
  __ProjectName__ModuleModel() : super(watchAll: true);

  int _counter = 0;

  /// Gets and sets the counter value.
  int get counter => _counter;
  set counter(int value) {
    _counter = value;

    // This call notifies all the listeners that something has been changed in
    // this data model. The ScopedModelDescendant widget with this model class
    // as the type parameter (see: home_page.dart) automatically becomes a
    // listener of this model class. Therefore, this notifyListeners() call
    // makes sure that the UI is correctly updated with the new counter value.
    notifyListeners();
  }

  /// Increments the counter value and writes the new value to the link.
  void incrementCounter() {
    // This method does not increment the _counter value directly, to maintain a
    // uni-directional flow and treat the Link value as the source of truth.
    // The onNotify() method will be called by Link with the new value, and we
    // only update the _counter value in response to that notification.
    //
    // This is important for correctly restoring the counter value and keeping
    // it in sync with other devices.
    link.set(<String>['counter'], json.encode(counter + 1));
  }

  @override
  void onReady(
    ModuleContext moduleContext,
    Link link,
  ) {
    super.onReady(moduleContext, link);

    // Do more initialization here.
  }

  @override
  void onStop() {
    // Do any clean-up work as necessary here.

    super.onStop();
  }

  @override
  void onNotify(String encodedJson) {
    // Process any data change notification from the Link.
    log.info('Link data changed: $encodedJson');

    dynamic decodedJson = json.decode(encodedJson);
    if (decodedJson is Map<String, dynamic> && decodedJson['counter'] is int) {
      counter = decodedJson['counter'];
    }
  }
}
