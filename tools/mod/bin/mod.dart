// Copyright 2017 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:mod/commands.dart';

Future<Null> main(List<String> args) async {
  ModCommandRunner runner = new ModCommandRunner()
    ..addCommand(new CreateCommand());

  try {
    await runner.run(args);
  } on UsageException catch (e) {
    print('ERROR: ${e.message}\n');
    print(e.usage);

    // Dart convention uses exit code 2 to indicate errors.
    exitCode = 2;
  }
}
