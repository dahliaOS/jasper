// Copyright 2017 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/widgets.dart';

/// Provides the default scroll configuration for armadillo to its [child].
class DefaultScrollConfiguration extends StatelessWidget {
  /// The child to apply the default scroll configuration to.
  final Widget child;

  /// Constructor.
  DefaultScrollConfiguration({Key key, this.child}) : super(key: key);

  @override
  Widget build(BuildContext context) => new ScrollConfiguration(
        behavior: const _BouncingScrollBehavior(),
        child: child,
      );
}

class _BouncingScrollBehavior extends ScrollBehavior {
  const _BouncingScrollBehavior();

  @override
  ScrollPhysics getScrollPhysics(BuildContext context) =>
      const BouncingScrollPhysics();
}
