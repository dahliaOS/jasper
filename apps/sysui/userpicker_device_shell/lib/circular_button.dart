// Copyright 2017 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:meta/meta.dart';

/// A button that is circular
class CircularButton extends StatelessWidget {
  /// Callback that is fired when the button is tapped
  final VoidCallback onTap;

  /// The icon to show in the button
  final IconData icon;

  /// Constructor
  CircularButton({this.onTap, @required this.icon}) {
    assert(icon != null);
  }

  @override
  Widget build(BuildContext context) => new Material(
        type: MaterialType.circle,
        elevation: 2.0,
        color: Colors.grey[200],
        child: new InkWell(
          onTap: () => onTap?.call(),
          child: new Container(
            padding: const EdgeInsets.all(12.0),
            child: new Icon(icon),
          ),
        ),
      );
}
