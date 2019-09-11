// Copyright 2017 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:lib.widgets/model.dart';
import 'package:widgets/image_picker.dart';

import 'module_model.dart';

/// Top-level widget for the gallery module.
class GalleryScreen extends StatelessWidget {
  /// Creates a new instacne of [GalleryScreen].
  GalleryScreen({Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return new MaterialApp(
      theme: new ThemeData(primarySwatch: Colors.blue),
      home: new Material(
        child: new ScopedModelDescendant<GalleryModuleModel>(
          builder: (
            BuildContext context,
            Widget child,
            GalleryModuleModel model,
          ) {
            return model.apiKey != null && model.customSearchId != null
                ? new GoogleSearchImagePicker(
                    apiKey: model.apiKey,
                    customSearchId: model.customSearchId,
                    query: model.queryString,
                    initialSelection: model.initialSelection,
                    onSelectionChanged: model.handleSelectionChanged,
                    onAdd: model.handleAdd,
                  )
                : new Center(child: new CircularProgressIndicator());
          },
        ),
      ),
    );
  }
}
