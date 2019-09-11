// Copyright 2018 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file

/// List of active repos under fuchsia.googlesource.com which can be linked to.
const List<String> validProjects = const <String>[
  'build',
  'buildtools',
  'cobalt',
  'fargo',
  'garnet',
  'infra', // This is a family of projects.
  'jiri',
  'manifest',
  'peridot',
  'scripts',
  'third_party', // This is a family of projects.
  'topaz',
  'zircon',
];
