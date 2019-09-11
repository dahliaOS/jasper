// Copyright 2018 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';
import 'dart:io';

import 'interact.dart';
import 'remote_vm.dart';

void main(List<String> args) async {
  stdin.lineMode = false;
  stdin.echoMode = false;

  var fromUtf8 = Utf8Decoder();
  var inputs = stdin.map((input) => fromUtf8.convert(input));

  // How to connect to a Fuchsia Dart test:
  //  1. Add a debugger() pause to a test.
  //  2. Run the test on a Fuchsia device.
  //  3. Tunnel to all available Dart VMs with `fx dart-tunnel`
  //  4. Use the port associated with the test process
  //
  // Or, to test the REPL with a fake main() locally:
  //    dart --observe=$port/::1 fake_main.dart
  var vm = RemoteVm();
  var port = args[0];
  await vm.connect('ws://[::1]:$port/ws');

  await for (var output in interact(inputs)) {
    if (output[0] == Output.evaluate) {
      String expression = output[1];
      print('');
      print(await vm.evaluate(expression));
    } else if (output[0] == Output.prompt) {
      var line = output[1];
      // Escape codes use one-based indexing.
      var position = output[2] + 1;
      stdout
          // Go to the start of the line.
          ..write('\u{1b}[G')
          // Delete to the end.
          ..write('\u{1b}[K')
          ..write(line)
          ..write('\u{1b}[${position}G');
    } else if (output[0] == Output.bell) {
      stdout.write('\u{7}');
    } else {
      assert(false);
    }
    await stdout.flush();
  }
}
