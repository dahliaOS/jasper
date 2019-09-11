// Copyright 2016 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:sysui_widgets/rk4_spring_simulation.dart';
import 'package:sysui_widgets/three_column_aligned_layout_delegate.dart';
import 'package:sysui_widgets/ticking_state.dart';

import 'story.dart';
import 'story_title.dart';

const RK4SpringDescription _kHeightSimulationDesc =
    const RK4SpringDescription(tension: 450.0, friction: 50.0);
const double _kPartMargin = 8.0;

const bool _kShowTitleOnly = true;

/// The bar to be shown at the top of a story.
class StoryBar extends StatefulWidget {
  /// The [Story] this bar represents.
  final Story story;

  /// The height of the bar when minimized.
  final double minimizedHeight;

  /// The height of the bar when maximized.
  final double maximizedHeight;

  /// True if the story is in focus.
  final bool focused;

  /// True if the story should show its title only.
  final bool showTitleOnly;

  /// Elevation for the Physical Model that wraps the StoryBar
  final double elevation;

  /// Constructor.
  StoryBar({
    Key key,
    this.story,
    this.minimizedHeight,
    this.maximizedHeight,
    this.focused,
    this.showTitleOnly: _kShowTitleOnly,
    this.elevation,
  })
      : super(key: key);

  @override
  StoryBarState createState() => new StoryBarState();
}

/// Holds the simulations for focus and height transitions.
class StoryBarState extends TickingState<StoryBar> {
  RK4SpringSimulation _heightSimulation;
  RK4SpringSimulation _focusedSimulation;
  double _showHeight;

  @override
  void initState() {
    super.initState();
    _heightSimulation = new RK4SpringSimulation(
      initValue: widget.minimizedHeight,
      desc: _kHeightSimulationDesc,
    );
    _focusedSimulation = new RK4SpringSimulation(
      initValue: 0.0,
      desc: _kHeightSimulationDesc,
    );
    _focusedSimulation.target = widget.focused ? 0.0 : 4.0;
    _showHeight = widget.minimizedHeight;
  }

  @override
  void didUpdateWidget(StoryBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.focused != oldWidget.focused) {
      _focusedSimulation.target = widget.focused ? 0.0 : 4.0;
      startTicking();
    }
  }

  @override
  Widget build(BuildContext context) => new PhysicalModel(
        color: widget.story.themeColor,
        elevation: widget.elevation,
        child: new Container(
          color: widget.story.themeColor,
          height: _height - _focusedSimulation.value,
          padding: new EdgeInsets.symmetric(horizontal: 12.0),
          margin: new EdgeInsets.only(bottom: _focusedSimulation.value),
          child: new OverflowBox(
            minHeight: widget.maximizedHeight,
            maxHeight: widget.maximizedHeight,
            alignment: FractionalOffset.topCenter,
            child: widget.showTitleOnly
                ? new Center(
                    child: new StoryTitle(
                      title: widget.story.title,
                      opacity: _opacity,
                      baseColor: _textColor,
                    ),
                  )
                : new Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 0.0,
                      vertical: 12.0,
                    ),
                    child: new CustomMultiChildLayout(
                      delegate: new ThreeColumnAlignedLayoutDelegate(
                        partMargin: _kPartMargin,
                      ),
                      children: <Widget>[
                        new LayoutId(
                          id: ThreeColumnAlignedLayoutDelegateParts.left,
                          child: new Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            mainAxisAlignment: MainAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: widget.story.icons
                                .map(
                                  (OpacityBuilder builder) => builder(
                                        context,
                                        _opacity,
                                      ),
                                )
                                .toList(),
                          ),
                        ),
                        new LayoutId(
                          id: ThreeColumnAlignedLayoutDelegateParts.center,
                          child: new StoryTitle(
                            title: widget.story.title,
                            opacity: _opacity,
                            baseColor: _textColor,
                          ),
                        ),
                        new LayoutId(
                          id: ThreeColumnAlignedLayoutDelegateParts.right,
                          child: new ClipOval(
                            child: new Container(
                              foregroundDecoration: new BoxDecoration(
                                border: new Border.all(
                                  color: _textColor.withOpacity(_opacity),
                                  width: 1.0,
                                ),
                                shape: BoxShape.circle,
                              ),
                              child: widget.story.avatar(context, _opacity),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
          ),
        ),
      );

  Color get _textColor {
    // See http://www.w3.org/TR/AERT#color-contrast for the details of this
    // algorithm.
    int brightness = (((widget.story.themeColor.red * 299) +
                (widget.story.themeColor.green * 587) +
                (widget.story.themeColor.blue * 114)) /
            1000)
        .round();

    return (brightness > 125) ? Colors.black : Colors.white;
  }

  @override
  bool handleTick(double elapsedSeconds) {
    if (_heightSimulation.isDone && _focusedSimulation.isDone) {
      return false;
    }

    // Tick the height simulation.
    _heightSimulation.elapseTime(elapsedSeconds);

    // Tick the focus simulation.
    _focusedSimulation.elapseTime(elapsedSeconds);

    return !_heightSimulation.isDone || !_focusedSimulation.isDone;
  }

  /// Shows the story bar.
  void show() {
    _heightSimulation.target = _showHeight;
    startTicking();
  }

  /// Hides the story bar.
  void hide() {
    _heightSimulation.target = 0.0;
    startTicking();
  }

  /// Maximizes the height of the story bar when shown.  If [jumpToFinish] is
  /// true the story bar height will jump to its maximized value instead of
  /// transitioning to it.
  void maximize({bool jumpToFinish: false}) {
    if (jumpToFinish) {
      _heightSimulation = new RK4SpringSimulation(
        initValue: widget.maximizedHeight,
        desc: _kHeightSimulationDesc,
      );
    }
    _showHeight = widget.maximizedHeight;
    _focusedSimulation.target = widget.focused ? 0.0 : 4.0;
    show();
  }

  /// Minimizes the height of the story bar when shown.
  void minimize() {
    _showHeight = widget.minimizedHeight;
    _focusedSimulation.target = 0.0;
    show();
  }

  double get _opacity => math.max(
      0.0,
      (_height - widget.minimizedHeight) /
          (widget.maximizedHeight - widget.minimizedHeight));

  double get _height => _heightSimulation.value;
}
