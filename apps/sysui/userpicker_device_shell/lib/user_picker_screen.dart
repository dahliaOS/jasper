// Copyright 2017 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:ui' show lerpDouble;

import 'package:apps.modular.services.auth.account/account.fidl.dart';
import 'package:flutter/material.dart';

import 'user_picker.dart';

const double _kRemovalTargetSize = 112.0;

/// Called when the user is removing [account].
typedef void OnRemoveUser(Account account);

/// Displays a [UserPicker] a shutdown button, a new user button, the
/// fuchsia logo, and a background image.
class UserPickerScreen extends StatelessWidget {
  /// The widget that allows a user to be picked.
  final UserPicker userPicker;

  /// Called when the user is removing an account.
  final OnRemoveUser onRemoveUser;

  /// Indicates the remove user indicator should be shown.
  final bool showUserRemovalTarget;

  /// Constructor.
  UserPickerScreen({
    this.userPicker,
    this.onRemoveUser,
    this.showUserRemovalTarget,
  });

  @override
  Widget build(BuildContext context) => new Material(
        color: Colors.grey[900],
        child: new Container(
          child: new Stack(
            fit: StackFit.passthrough,
            children: <Widget>[
              new FractionallySizedBox(
                heightFactor: 1.1,
                alignment: FractionalOffset.topCenter,
                child: new Stack(
                  fit: StackFit.passthrough,
                  children: <Widget>[
                    new Image.asset(
                      'packages/userpicker_device_shell/res/bg.jpg',
                      fit: BoxFit.cover,
                    ),
                    new Container(color: Colors.black.withAlpha(125)),
                  ],
                ),
              ),

              /// Add Fuchsia logo.
              new Align(
                alignment: FractionalOffset.topLeft,
                child: new Container(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 16.0,
                    vertical: 16.0,
                  ),
                  child: new Image.asset(
                    'packages/userpicker_device_shell/res/Fuchsia_Logo_40dp_Accent.png',
                    width: 40.0,
                    height: 40.0,
                  ),
                ),
              ),

              /// Add user picker for selecting users and adding new users
              new Align(
                alignment: FractionalOffset.bottomRight,
                child: new RepaintBoundary(
                  child: userPicker,
                ),
              ),

              // Add user removal target
              new Align(
                alignment: FractionalOffset.center,
                child: new RepaintBoundary(
                  child: new Container(
                    child: new DragTarget<Account>(
                      onWillAccept: (Account data) => true,
                      onAccept: (Account data) => onRemoveUser?.call(data),
                      builder: (
                        _,
                        List<Account> candidateData,
                        __,
                      ) =>
                          new _UserRemovalTarget(
                            show: showUserRemovalTarget,
                            grow: candidateData.isNotEmpty,
                          ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
}

/// Displays a removal target for removing users
class _UserRemovalTarget extends StatefulWidget {
  /// Grows the target by some percentage.
  final bool grow;

  /// Shows the target.
  final bool show;

  /// Constructor.
  _UserRemovalTarget({this.show, this.grow});

  @override
  _UserRemovalTargetState createState() => new _UserRemovalTargetState();
}

class _UserRemovalTargetState extends State<_UserRemovalTarget>
    with TickerProviderStateMixin {
  AnimationController _masterAnimationController;
  AnimationController _initialScaleController;
  CurvedAnimation _initialScaleCurvedAnimation;
  AnimationController _scaleController;
  CurvedAnimation _scaleCurvedAnimation;

  @override
  void initState() {
    super.initState();
    _masterAnimationController = new AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _initialScaleController = new AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );
    _initialScaleCurvedAnimation = new CurvedAnimation(
      parent: _initialScaleController,
      curve: Curves.fastOutSlowIn,
      reverseCurve: Curves.fastOutSlowIn,
    );
    _scaleController = new AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );
    _scaleCurvedAnimation = new CurvedAnimation(
      parent: _scaleController,
      curve: Curves.fastOutSlowIn,
      reverseCurve: Curves.fastOutSlowIn,
    );
    _initialScaleController.addStatusListener((AnimationStatus status) {
      if (!widget.show && _initialScaleController.isDismissed) {
        _masterAnimationController.stop();
      }
    });

    if (widget.show) {
      _masterAnimationController.repeat();
      _initialScaleController.forward();
      if (widget.grow) {
        _scaleController.forward();
      }
    }
  }

  @override
  void didUpdateWidget(_) {
    super.didUpdateWidget(_);
    if (widget.grow) {
      _scaleController.forward();
    } else {
      _scaleController.reverse();
    }
    if (widget.show) {
      _masterAnimationController.repeat();
      _initialScaleController.forward();
    } else {
      _initialScaleController.value = 0.0;
    }
  }

  @override
  void dispose() {
    _scaleController.dispose();
    _initialScaleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => new Container(
        child: new AnimatedBuilder(
          animation: _masterAnimationController,
          builder: (BuildContext context, Widget child) => new Transform(
                alignment: FractionalOffset.center,
                transform: new Matrix4.identity().scaled(
                  lerpDouble(1.0, 0.7, _scaleCurvedAnimation.value) *
                      _initialScaleCurvedAnimation.value,
                  lerpDouble(1.0, 0.7, _scaleCurvedAnimation.value) *
                      _initialScaleCurvedAnimation.value,
                ),
                child: new Container(
                  width: _kRemovalTargetSize,
                  height: _kRemovalTargetSize,
                  decoration: new BoxDecoration(
                    borderRadius:
                        new BorderRadius.circular(_kRemovalTargetSize / 2.0),
                    border: new Border.all(color: Colors.white.withAlpha(200)),
                    color: Colors.white.withAlpha(
                        lerpDouble(0, 100.0, _scaleCurvedAnimation.value)
                            .toInt()),
                  ),
                  child: new Center(
                    child: new Text(
                      'REMOVE',
                      style: new TextStyle(
                        color: Colors.white,
                        fontSize: 16.0,
                      ),
                    ),
                  ),
                ),
              ),
        ),
      );
}
