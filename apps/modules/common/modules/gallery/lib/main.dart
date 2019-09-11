// Copyright 2017 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:application.lib.app.dart/app.dart';
import 'package:flutter/widgets.dart';
import 'package:lib.widgets/modular.dart';

import 'src/modular/gallery_screen.dart';
import 'src/modular/module_model.dart';

void main() {
  ModuleWidget<GalleryModuleModel> moduleWidget =
      new ModuleWidget<GalleryModuleModel>(
    applicationContext: new ApplicationContext.fromStartupInfo(),
    moduleModel: new GalleryModuleModel(),
    child: new GalleryScreen(),
  );

  moduleWidget.advertise();

  runApp(moduleWidget);
}
