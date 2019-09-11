// Copyright 2017 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

class _WidthParam {
  const _WidthParam();
}

/// An annotation to specify that a parameter is meant to be the width, and thus
/// should be associated with the width controller value of the gallery page.
///
/// This annotation must not be used with the `@sizeParam` annotation.
const _WidthParam widthParam = const _WidthParam();
