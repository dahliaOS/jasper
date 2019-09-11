// Copyright 2017 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:apps.mozart.lib.flutter/child_view.dart';
import 'package:flutter/material.dart';
import 'package:lib.widgets/model.dart';

import 'authentication_overlay_model.dart';

/// Displays the authentication window.
class AuthenticationOverlay extends StatelessWidget {
  @override
  Widget build(BuildContext context) =>
      new ScopedModelDescendant<AuthenticationOverlayModel>(
        builder: (
          BuildContext context,
          Widget child,
          AuthenticationOverlayModel model,
        ) =>
            new AnimatedBuilder(
              animation: model.animation,
              builder: (BuildContext context, Widget child) => new Offstage(
                    offstage: model.animation.isDismissed,
                    child: new Opacity(
                      opacity: model.animation.value,
                      child: child,
                    ),
                  ),
              child: new FractionallySizedBox(
                widthFactor: 0.75,
                heightFactor: 0.75,
                child: new ChildView(
                  connection: model.childViewConnection,
                ),
              ),
            ),
      );
}
