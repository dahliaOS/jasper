// Copyright 2017 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

import 'constraints_model.dart';
import 'rounded_corner_decoration.dart';

/// Bezel constants.  Used to give the illusion of a device.
const double _kBezelMinimumWidth = 8.0;
const double _kBezelExtension = 16.0;
const double _kOuterBezelRadius = 16.0;
const double _kInnerBezelRadius = 8.0;

/// A widget that changes [child]'s constraints to one within
/// [constraintsModel]. An affordance to perform this change is placed in
/// [ChildConstraintsChanger]'s top right.  Each tap of the affordance steps
/// through the [constraintsModel] list applying each constraint to [child] in
/// turn.
class ChildConstraintsChanger extends StatefulWidget {
  /// The model containing the constraints [child] should be constrained by.
  final ConstraintsModel constraintsModel;

  /// The [Widget] whose constrants will be set.
  final Widget child;

  /// Constructor.
  ChildConstraintsChanger({Key key, this.constraintsModel, this.child})
      : super(key: key);

  @override
  ChildConstraintsChangerState createState() =>
      new ChildConstraintsChangerState();
}

/// Keeps track of the current constraints.
class ChildConstraintsChangerState extends State<ChildConstraintsChanger> {
  final GlobalKey _containerKey = new GlobalKey();
  List<BoxConstraints> _constraints;
  int _currentConstraintIndex = 0;
  bool _useConstraints = false;

  @override
  void initState() {
    super.initState();
    _constraints = widget.constraintsModel.constraints;
    widget.constraintsModel.addListener(_onChange);
  }

  @override
  void dispose() {
    widget.constraintsModel.removeListener(_onChange);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => new Stack(
        fit: StackFit.loose,
        alignment: FractionalOffset.center,
        children:
            _useConstraints && _constraints != null && _constraints.isNotEmpty
                ? <Widget>[
                    _exitConstraintsChild,
                    _switchConstraintsButton,
                    _constrainedChild,
                  ]
                : <Widget>[
                    _exitConstraintsChild,
                    _switchConstraintsButton,
                    _unconstrainedChild,
                    _enterConstraintsChild,
                  ],
      );

  Widget get _constrainedChild => _decoratedChild(
        _currentConstraint.maxWidth +
            (2.0 * _kBezelMinimumWidth) +
            (_currentConstraint.maxHeight <= _currentConstraint.maxWidth
                ? _kBezelExtension
                : 0.0),
        _currentConstraint.maxHeight +
            (2.0 * _kBezelMinimumWidth) +
            (_currentConstraint.maxHeight > _currentConstraint.maxWidth
                ? _kBezelExtension
                : 0.0),
      );

  Widget get _unconstrainedChild => new LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) =>
            _decoratedChild(constraints.maxWidth, constraints.maxHeight,
                bezel: false),
      );

  Widget _decoratedChild(double width, double height, {bool bezel: true}) =>
      new AnimatedContainer(
        key: _containerKey,
        width: width,
        height: height,
        duration: const Duration(milliseconds: 300),
        curve: Curves.fastOutSlowIn,
        padding: new EdgeInsets.only(
          bottom: bezel && height > width ? _kBezelExtension : 0.0,
          right: bezel && height <= width ? _kBezelExtension : 0.0,
        ),
        decoration: new BoxDecoration(
          color: Colors.black,
          border: new Border.all(
            color: Colors.black,
            width: bezel ? _kBezelMinimumWidth : 0.0,
          ),
          borderRadius: new BorderRadius.circular(
            bezel ? _kOuterBezelRadius : 0.0,
          ),
        ),
        child: new Container(
          foregroundDecoration: new RoundedCornerDecoration(
            radius: _kInnerBezelRadius,
            color: Colors.black,
          ),
          child: widget.child,
        ),
      );

  Widget get _enterConstraintsChild => new Positioned(
        top: 0.0,
        left: 0.0,
        width: 80.0,
        height: 80.0,
        child: new GestureDetector(
          behavior: HitTestBehavior.translucent,
          onTap: _enterConstraints,
        ),
      );

  Widget get _switchConstraintsButton => new Positioned(
        right: 20.0,
        bottom: 20.0,
        width: 60.0,
        height: 60.0,
        child: new FloatingActionButton(
          backgroundColor: const Color(0xFFFFFFFF),
          child: new Icon(
            Icons.devices,
            color: const Color(0xFF404040),
          ),
          onPressed: _switchConstraints,
          elevation: 0.0,
        ),
      );

  Widget get _exitConstraintsChild => new Positioned(
        left: 0.0,
        right: 0.0,
        top: 0.0,
        bottom: 0.0,
        child: new Container(
          color: const Color(0xFF404040),
          child: new GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTap: _exitConstraints,
          ),
        ),
      );

  BoxConstraints get _currentConstraint {
    if (_constraints == null || _constraints.isEmpty) {
      return new BoxConstraints();
    }
    return _constraints[_currentConstraintIndex % _constraints.length];
  }

  void _enterConstraints() => setState(() {
        _useConstraints = true;
      });

  void _switchConstraints() => setState(() {
        _currentConstraintIndex++;
      });

  void _exitConstraints() => setState(() {
        _useConstraints = false;
      });

  /// Toggles through the constraints.
  void toggleConstraints() {
    if (!_useConstraints) {
      _enterConstraints();
    } else {
      _switchConstraints();
      if (_currentConstraintIndex % _constraints.length == 0) {
        _exitConstraints();
      }
    }
  }

  void _onChange() {
    setState(() {
      _constraints = widget.constraintsModel.constraints;
    });
  }
}
