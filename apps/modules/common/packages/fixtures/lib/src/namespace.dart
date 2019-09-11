// Copyright 2016 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:util/ok.dart';

const String _basename = 'fuchsia.googlesource.com/fixtures';
final Set<String> _namespaces = new Set<String>();

/// Returns a fixtures url namespace for value.
String namespace(String value) {
  String ns = '$_basename/$value';

  ok(_namespaces.add(ns),
      'Namespaces must be unique, the namespace \'$ns\' has already been created.');

  return ns;
}
