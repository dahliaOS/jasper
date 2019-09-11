// Copyright 2016 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/widgets.dart';

import 'wrapper_builder.dart';

/// Builds [builder] with [child] if [useWrapper] is true.
/// Builds only [child] if [useWrapper] is false.
class OptionalWrapper extends StatelessWidget {
  /// Builds the [Widget] which wraps [child] when [useWrapper] is true.
  final WrapperBuilder builder;

  /// The [Widget] which should exist regardless of [useWrapper]'s value.
  final Widget child;

  /// If true, [build] uses [builder] to wrap [child].  Otherwise [child] is
  /// returned.
  final bool useWrapper;

  /// Constructor.
  OptionalWrapper({this.builder, this.child, this.useWrapper: true});

  @override
  Widget build(BuildContext context) =>
      useWrapper ? builder(context, child) : child;
}
