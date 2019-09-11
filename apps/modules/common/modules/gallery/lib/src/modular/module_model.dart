// Copyright 2017 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:collection';
import 'dart:convert' show JSON;

import 'package:application.lib.app.dart/app.dart';
import 'package:application.services/service_provider.fidl.dart';
import 'package:apps.modular.services.component/component_context.fidl.dart';
import 'package:apps.modular.services.module/module_context.fidl.dart';
import 'package:apps.modular.services.story/link.fidl.dart';
import 'package:apps.modules.common.services.gallery/gallery.fidl.dart';
import 'package:config/config.dart';
import 'package:lib.widgets/modular.dart';

import 'gallery_service_impl.dart';

const String _kContract = 'image search';
const String _kQueryKey = 'query';

void _log(String msg) {
  print('[gallery_module_model] $msg');
}

/// A [ModuleModel] providing the api id / key values for the gallery module.
class GalleryModuleModel extends ModuleModel {
  /// Gets the custom search id.
  String get customSearchId => _customSearchId;
  String _customSearchId;

  /// Gets the api key.
  String get apiKey => _apiKey;
  String _apiKey;

  /// Gets the initial query string provided by the [Link].
  String get queryString => _queryString;
  String _queryString;

  /// Gets the list of initially selected image urls.
  List<String> get initialSelection =>
      new UnmodifiableListView<String>(_initialSelection);
  final List<String> _initialSelection = <String>[];

  /// [Link] object for storing the internal state of the selected images.
  final LinkProxy _selectionLink = new LinkProxy();
  final LinkWatcherBinding _selectionLinkWatcherBinding =
      new LinkWatcherBinding();

  final ComponentContextProxy _componentContext = new ComponentContextProxy();

  /// Outgoing [ServiceProvider] instance to be exposed.
  final ServiceProviderImpl _outgoingServiceProvider =
      new ServiceProviderImpl();

  @override
  ServiceProvider get outgoingServiceProvider => _outgoingServiceProvider;
  GalleryServiceImpl _galleryServiceImpl;

  @override
  Future<Null> onReady(
    ModuleContext moduleContext,
    Link link,
    ServiceProvider incomingServices,
  ) async {
    super.onReady(moduleContext, link, incomingServices);

    // Obtain the component context.
    moduleContext.getComponentContext(_componentContext.ctrl.request());

    // Create the GalleryServiceImpl instance and add it to the outgoing service
    // provider.
    _galleryServiceImpl = new GalleryServiceImpl(_componentContext);
    _outgoingServiceProvider.addServiceForName(
      _galleryServiceImpl.bind,
      GalleryService.serviceName,
    );

    // Check for the config values.
    Config config = await Config.read('/system/data/modules/config.json');
    try {
      config.validate(<String>['google_search_key', 'google_search_id']);
      _customSearchId = config.get('google_search_id');
      _apiKey = config.get('google_search_key');
      notifyListeners();
    } catch (e) {
      _log('$e');
    }

    // Obtain the selection Link.
    moduleContext.getLink('selection', _selectionLink.ctrl.request());
    _selectionLink.watch(_selectionLinkWatcherBinding.wrap(new LinkWatcherImpl(
      onNotify: handleNotifySelection,
    )));
  }

  @override
  void onNotify(String json) {
    dynamic decoded = json.decode(json);
    try {
      _queryString = decoded[_kContract][_kQueryKey];
    } catch (e) {
      _log('No image picker query key found in json.');
    }
    notifyListeners();
  }

  @override
  void onStop() {
    _componentContext.ctrl.close();
    _selectionLinkWatcherBinding.close();
    _selectionLink.ctrl.close();

    super.onStop();
  }

  /// This handles the notification coming from the [Link] where we store the
  /// list of selected image urls. In this handler, we need to update the list
  /// of initial selection and pass it to the gallery widget so that the
  /// selection is rehydrated when the module is restored.
  ///
  /// We assume that the json simply contains the list of urls.
  void handleNotifySelection(String json) {
    if (json != null) {
      List<String> urls = json.decode(json);
      if (urls != null) {
        _initialSelection.clear();
        _initialSelection.addAll(urls);
        notifyListeners();
      }
    }
  }

  /// This handles the notification coming from the UI of any changes that the
  /// user made on the selection. We have to store this information to Link, so
  /// that the selection may be restored correctly later.
  void handleSelectionChanged(List<String> imageUrls) {
    String json = JSON.encode(imageUrls);
    _selectionLink.set(const <String>[], json);
  }

  /// Called when the user clicks the "Add" button from the UI.
  void handleAdd(List<String> imageUrls) {
    _log('handleAdd call: $imageUrls');
    _galleryServiceImpl.notify(imageUrls);
  }
}
