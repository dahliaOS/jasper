// Copyright 2017 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:meta/meta.dart';

import 'qr_code_widget.dart';

const Color _kFuchsiaColor = const Color(0xFFFF0080);

final String _kBootTimeStamp = new DateFormat('MM.dd h:mm aaa', 'en_US')
    .format(new DateTime.now())
    .toLowerCase();

/// Displays a kernel panic log.
class KernelPanic extends StatelessWidget {
  /// The kernel panic info.
  final String kernelPanic;

  /// Called when the kernel panic is dismissed.
  final VoidCallback onDismiss;

  /// Constructor.
  KernelPanic({Key key, @required this.kernelPanic, this.onDismiss})
      : super(key: key);

  @override
  Widget build(BuildContext context) => new GestureDetector(
        onTap: onDismiss,
        child: new Container(
          color: _kFuchsiaColor,
          child: new LayoutBuilder(
            builder: (BuildContext context, BoxConstraints constraints) =>
                _adaptiveFlexibleList(
                  constraints: constraints,
                  children: <Widget>[
                    new Expanded(
                      flex: 1,
                      child: new Align(
                        alignment: FractionalOffset.topLeft,
                        child: new Container(
                          padding: const EdgeInsets.all(16.0),
                          child: new ListView(
                            children: <Widget>[
                              new Text(
                                'Panic occurred at $_kBootTimeStamp',
                                style: new TextStyle(
                                  color: Colors.white,
                                  fontFamily: 'RobotoMono',
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              new Divider(color: Colors.white),
                              new Text(
                                'Tap anywhere to dismiss.',
                                style: new TextStyle(
                                  color: Colors.white,
                                  fontFamily: 'RobotoMono',
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              new Divider(color: Colors.white),
                              new Text(
                                kernelPanic,
                                style: new TextStyle(
                                  color: Colors.white,
                                  fontFamily: 'RobotoMono',
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    new Expanded(
                      flex: 1,
                      child: new Center(
                        child: new Container(
                          margin: const EdgeInsets.all(16.0),
                          child: new QrCodeWidget(kernelPanic),
                        ),
                      ),
                    ),
                  ],
                ),
          ),
        ),
      );

  Widget _adaptiveFlexibleList({
    BoxConstraints constraints,
    List<Widget> children,
  }) =>
      (constraints.maxWidth > constraints.maxHeight)
          ? new Row(children: children)
          : new Column(children: children);
}
