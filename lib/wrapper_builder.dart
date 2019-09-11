// Copyright 2016 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/widgets.dart';

/// Returns a [Widget] tree that returns [child] wrapped by other [Widget]s.
typedef Widget WrapperBuilder(BuildContext context, Widget child);
