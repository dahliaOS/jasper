// Copyright 2018 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:lib.app.dart/app.dart';
import 'package:lib.widgets/modular.dart';

import 'home_page.dart';
import 'module_model.dart';

void main() {
  // ModuleWidget is the top level widget for this module. The type parameter
  // specifies the ModuleModel class, and the instance of that class is provided
  // as a parameter.
  ModuleWidget<__ProjectName__ModuleModel> moduleWidget =
      new ModuleWidget<__ProjectName__ModuleModel>(
    // The StartupContext encapsulates how this module (application) can
    // exchange services with the outside world. For example, the Module service
    // is exposed via this application context. Similarly, this module can
    // access other services provided by the environment via application
    // context.
    startupContext: new StartupContext.fromStartupInfo(),
    moduleModel: new __ProjectName__ModuleModel(),
    child: new MaterialApp(
      home: const HomePage(),
    ),
  );

  // The advertise() call exposes the Module service interface to the underlying
  // Fuchsia framework. This call is mandatory, and this application will not
  // function properly as a module if advertise() is not called.
  // ignore: cascade_invocations
  moduleWidget.advertise();

  runApp(moduleWidget);
}
