// Copyright 2018 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io';
import 'package:test/test.dart';

import 'package:repl/remote_vm.dart';

void main(List<String> args) async {
  if (args.length != 1) {
    stderr.writeln(
        'This test requires a single argument: the observatory port to use.');
    exitCode = 1;
    return;
  }
  var port = args[0];
  var dart = Platform.resolvedExecutable;
  var fakeMainPath = Platform.script.toString().replaceFirst(
      RegExp(r'test/remote_vm_e2e_test.dart$'), 'lib/fake_main.dart');

  Process fakeMain;

  setUp(() async {
    fakeMain = await Process.start(dart, ['--observe=$port', fakeMainPath]);
  });

  tearDown(() async {
    fakeMain.kill();
    await fakeMain.exitCode;
  });

  test('connect to VM and evaluate', () async {
    var vm = RemoteVm();
    await vm.connect('ws://127.0.0.1:$port/ws');

    expect(await vm.evaluate('triple(1)'), equals('3'));
    expect(await vm.evaluate('nope'), contains('Error:'));
  });
}
