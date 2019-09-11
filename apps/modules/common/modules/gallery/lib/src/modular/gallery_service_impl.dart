// Copyright 2017 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert' show JSON;

import 'package:apps.modular.services.component/component_context.fidl.dart';
import 'package:apps.modular.services.component/message_queue.fidl.dart';
import 'package:apps.modules.common.services.gallery/gallery.fidl.dart';
import 'package:lib.fidl.dart/bindings.dart';

/// A concrete implementation of the [GalleryService] FIDL interface.
class GalleryServiceImpl extends GalleryService {
  final List<GalleryServiceBinding> _bindings = <GalleryServiceBinding>[];

  final ComponentContext _componentContext;

  final Map<String, MessageSenderProxy> _messageSenders =
      <String, MessageSenderProxy>{};

  /// Creates a new instance of [GalleryServiceImpl].
  GalleryServiceImpl(ComponentContext componentContext)
      : _componentContext = componentContext {
    assert(componentContext != null);
  }

  @override
  void subscribe(String messageQueueToken) {
    MessageSenderProxy messageSender = new MessageSenderProxy();
    _componentContext.getMessageSender(
      messageQueueToken,
      messageSender.ctrl.request(),
    );
    _messageSenders[messageQueueToken] = messageSender;
  }

  @override
  void unsubscribe(String messageQueueToken) {
    MessageSenderProxy messageSender = _messageSenders[messageQueueToken];
    if (messageSender != null) {
      messageSender.ctrl.close();
      _messageSenders.remove(messageSender);
    }
  }

  /// Binds the request with this instance of [GalleryServiceImpl].
  void bind(InterfaceRequest<GalleryService> request) {
    GalleryServiceBinding binding = new GalleryServiceBinding();
    binding.bind(this, request);
    _bindings.add(binding);
  }

  /// Notifies all the subscribers of the list of selected images when the user
  /// clicked the "Add" button.
  void notify(List<String> imageUrls) {
    print('[gallery_service_impl] notify call: $imageUrls');
    // TODO(youngseokyoon): use a formal document object for encoding/decoding.
    // https://fuchsia.atlassian.net/browse/SO-404
    Map<String, dynamic> jsonObject = <String, dynamic>{
      'selected_images': imageUrls,
    };

    // TODO(youngseokyoon): better error handling in JSON encoding/decoding.
    // https://fuchsia.atlassian.net/browse/SO-403
    String json = JSON.encode(jsonObject);
    _messageSenders.values.forEach((MessageSenderProxy ms) {
      ms.send(json);
    });
  }

  /// Closes all the FIDL bindings.
  void close() {
    _messageSenders.values.forEach((MessageSenderProxy ms) => ms.ctrl.close());
    _bindings.forEach((GalleryServiceBinding binding) => binding.close());
  }
}
