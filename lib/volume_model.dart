// Copyright 2017 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/widgets.dart';
import 'package:lib.widgets/model.dart';

export 'package:lib.widgets/model.dart'
    show ScopedModel, Model, ScopedModelDescendant;

/// The base class for volume models.
abstract class VolumeModel extends Model {
  /// Wraps [ModelFinder.of] for this [Model]. See [ModelFinder.of] for more
  /// details.
  static VolumeModel of(BuildContext context) =>
      new ModelFinder<VolumeModel>().of(context);

  /// The volume level from 0.0 to 1.0.
  double get level;

  /// Sets the volume level to [level].
  set level(double level);
}
