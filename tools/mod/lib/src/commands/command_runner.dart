// Copyright 2017 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:path/path.dart' as path;

/// Function signature for a log printer.
typedef LogPrinter = void Function(String msg);

/// The mod tool command runner.
class ModCommandRunner extends CommandRunner<Null> {
  /// The working directory.
  ///
  /// The sub-commands should use this variable instead of calling
  /// [Directory.current] directly.
  final Directory workingDir;

  /// Log printer for displaying normal status messages.
  final LogPrinter _statusPrinter;

  /// Creates a new [ModCommandRunner].
  ModCommandRunner({Directory workingDir, LogPrinter statusPrinter})
      : workingDir = workingDir ?? Directory.current,
        _statusPrinter = statusPrinter ?? print,
        super('mod', 'mod: A scaffolding tool for Fuchsia mods.');

  /// Gets the `mod` package root.
  Directory get modPackageRoot =>
      new Directory(path.dirname(path.dirname(Platform.script.toFilePath())));

  /// Displays the given message at the normal status level.
  void printStatus(String msg) => _statusPrinter(msg);
}

/// Base class for the mod tool commands.
abstract class ModCommand extends Command<Null> {
  @override
  ModCommandRunner get runner => super.runner;

  /// Gets the `mod` package root.
  Directory get modPackageRoot => runner.modPackageRoot;

  /// The working directory.
  ///
  /// The sub-commands should use this variable instead of calling
  /// [Directory.current] directly.
  Directory get workingDir => runner.workingDir;

  /// Displays the given message at the normal status level.
  void printStatus(String msg) => runner.printStatus(msg);
}
