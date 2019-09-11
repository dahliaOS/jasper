// Copyright 2017 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

class _SizeParam {
  const _SizeParam();
}

/// An annotation to specify that a parameter is meant to be the size of the
/// widget, and thus should be associated with the size controller value of the
/// gallery page. When there is a parameter annotated with `@sizeParam`, the
/// gallery page will only provide a single size controller, instead of separate
/// width and height controllers.
///
/// This annotation must not be used with `@widthParam` or `@heightParam`.
const _SizeParam sizeParam = const _SizeParam();
