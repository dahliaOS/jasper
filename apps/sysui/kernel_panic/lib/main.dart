// Copyright 2017 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:io';

import 'package:flutter/widgets.dart';

import 'kernel_panic.dart';

Future<Null> main() async {
  runApp(new _KernelPanicReader());
}

class _KernelPanicReader extends StatefulWidget {
  @override
  _KernelPanicReaderState createState() => new _KernelPanicReaderState();
}

class _KernelPanicReaderState extends State<_KernelPanicReader> {
  String _lastPanicString = '';

  @override
  void initState() {
    super.initState();

    File lastPanic = new File('/boot/log/last-panic.txt');
    lastPanic.exists().then((bool exists) {
      if (exists) {
        lastPanic.readAsString().then((String lastPanicString) {
          if (lastPanicString.isEmpty) {
            exit(0);
          } else {
            setState(
              () {
                _lastPanicString = lastPanicString;
              },
            );
          }
        });
      } else {
        exit(0);
      }
    });
  }

  @override
  Widget build(BuildContext context) => _lastPanicString.isEmpty
      ? new Container()
      : new KernelPanic(
          kernelPanic: _lastPanicString,
          onDismiss: () => exit(0),
        );
}
