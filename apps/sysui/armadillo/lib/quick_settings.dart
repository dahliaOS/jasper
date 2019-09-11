// Copyright 2016 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io';
import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:sysui_widgets/icon_slider.dart';
import 'package:sysui_widgets/rk4_spring_simulation.dart';
import 'package:sysui_widgets/ticking_state.dart';

import 'elevation_constants.dart';
import 'now.dart';
import 'toggle_icon.dart';
import 'volume_model.dart';

// Width and height of the icons
const double _kIconSize = 24.0;

// Image assets
const String _kAirplaneModeInactiveGrey600 =
    'packages/armadillo/res/ic_airplanemode_inactive_grey600.png';
const String _kAirplaneModeActiveBlack =
    'packages/armadillo/res/ic_airplanemode_active_black.png';
const String _kDoNoDisturbOffGrey600 =
    'packages/armadillo/res/ic_do_not_disturb_off_grey600.png';
const String _kDoNoDisturbOnBlack =
    'packages/armadillo/res/ic_do_not_disturb_on_black.png';
const String _kScreenLockRotationBlack =
    'packages/armadillo/res/ic_screen_lock_rotation_black.png';
const String _kScreenRotationBlack =
    'packages/armadillo/res/ic_screen_rotation_black.png';
const String _kBatteryImageGrey600 =
    'packages/armadillo/res/ic_battery_90_grey600_1x_web_24dp.png';
const String _kMicImageGrey600 =
    'packages/armadillo/res/ic_mic_grey600_1x_web_24dp.png';
const String _kBrightnessHighGrey600 =
    'packages/armadillo/res/ic_brightness_high_grey600.png';
const String _kVolumeUpGrey600 =
    'packages/armadillo/res/ic_volume_up_grey600.png';

const Color _kTurquoise = const Color(0xFF1DE9B6);
const Color _kActiveSliderColor = _kTurquoise;

/// If [QuickSettings size] is wider than this, the contents will be laid out
/// into multiple columns instead of a single column.
const double _kMultiColumnWidthThreshold = 450.0;

const RK4SpringDescription _kSimulationDesc =
    const RK4SpringDescription(tension: 450.0, friction: 50.0);
const double _kShowSimulationTarget = 100.0;

/// An overlay that slides up over the bottom of its parent when shown.
class QuickSettingsOverlay extends StatefulWidget {
  /// The size of [Now] when minimized.
  final double minimizedNowBarHeight;

  /// Called each tick as the overlay is shown or hidden.
  final ValueChanged<double> onProgressChanged;

  /// Called when logout is tapped.
  final VoidCallback onLogoutTapped;

  /// Called when logout is long pressed.
  final VoidCallback onLogoutLongPressed;

  /// Constructor.
  QuickSettingsOverlay({
    Key key,
    this.minimizedNowBarHeight,
    this.onProgressChanged,
    this.onLogoutTapped,
    this.onLogoutLongPressed,
  })
      : super(key: key);

  @override
  QuickSettingsOverlayState createState() => new QuickSettingsOverlayState();
}

/// Holds the simulation for the show/hide transition of the
/// [QuickSettingsOverlay].
class QuickSettingsOverlayState extends TickingState<QuickSettingsOverlay> {
  final RK4SpringSimulation _showSimulation = new RK4SpringSimulation(
    initValue: 0.0,
    desc: _kSimulationDesc,
  );

  /// Shows the overlay.
  void show() {
    _showSimulation.target = _kShowSimulationTarget;
    startTicking();
  }

  /// Hides the overlay.
  void hide() {
    _showSimulation.target = 0.0;
    startTicking();
  }

  double get _showProgress => _showSimulation.value / _kShowSimulationTarget;

  Widget _buildQuickSettingsOverlayContent() => new Align(
        alignment: FractionalOffset.bottomCenter,
        child: new RepaintBoundary(
          child: new Container(
              decoration: new BoxDecoration(
                  color: Colors.white,
                  borderRadius: new BorderRadius.circular(
                    4.0,
                  )),
              child: new QuickSettings(
                opacity: 1.0,
                onLogoutTapped: widget.onLogoutTapped,
                onLogoutLongPressed: widget.onLogoutLongPressed,
              )),
        ),
      );

  @override
  Widget build(BuildContext context) => new Offstage(
        offstage: _showProgress == 0.0,
        child: new PhysicalModel(
          elevation: Elevations.quickSettings,
          color: Colors.transparent,
          child: new Stack(
            fit: StackFit.passthrough,
            children: <Widget>[
              new Positioned(
                left: 0.0,
                top: 0.0,
                right: 0.0,
                bottom: 0.0,
                child: new Offstage(
                  offstage: _showSimulation.target != _kShowSimulationTarget,
                  child: new Listener(
                    behavior: HitTestBehavior.opaque,
                    onPointerDown: (_) {
                      hide();
                    },
                  ),
                ),
              ),
              new Positioned(
                bottom: lerpDouble(
                  // Hack(dayang): We are not able to use transparencies with
                  // Mozart 2.
                  // MZ-221
                  -220.0,
                  8.0 + widget.minimizedNowBarHeight,
                  _showProgress,
                ),
                left: 8.0,
                right: 8.0,
                child: _buildQuickSettingsOverlayContent(),
              ),
            ],
          ),
        ),
      );

  @override
  bool handleTick(double elapsedSeconds) {
    _showSimulation.elapseTime(elapsedSeconds);
    widget.onProgressChanged?.call(_showProgress);
    return !_showSimulation.isDone;
  }
}

/// Displays the quick settings.
class QuickSettings extends StatefulWidget {
  /// The opacity of the quick settings.
  final double opacity;

  /// Called when logout is tapped.
  final VoidCallback onLogoutTapped;

  /// Called when logout is long pressed.
  final VoidCallback onLogoutLongPressed;

  /// Constructor.
  QuickSettings({this.opacity, this.onLogoutTapped, this.onLogoutLongPressed});

  @override
  _QuickSettingsState createState() => new _QuickSettingsState();
}

class _QuickSettingsState extends State<QuickSettings> {
  double _brightnessSliderValue = 0.0;

  final GlobalKey _kAirplaneModeToggle = new GlobalKey();
  final GlobalKey _kDoNotDisturbModeToggle = new GlobalKey();
  final GlobalKey _kScreenRotationToggle = new GlobalKey();

  Widget _divider({double opacity: 1.0}) {
    return new Divider(
      height: 4.0,
      color: Colors.grey[300].withOpacity(opacity),
    );
  }

  Widget _volumeIconSlider() => new ScopedModelDescendant<VolumeModel>(
        builder: (
          BuildContext context,
          Widget child,
          VolumeModel model,
        ) =>
            new IconSlider(
              value: model.level,
              min: 0.0,
              max: 1.0,
              activeColor: _kActiveSliderColor,
              thumbImage: new AssetImage(_kVolumeUpGrey600),
              onChanged: (double value) {
                model.level = value;
              },
            ),
      );

  Widget _brightnessIconSlider() => new IconSlider(
        value: _brightnessSliderValue,
        min: 0.0,
        max: 100.0,
        activeColor: _kActiveSliderColor,
        thumbImage: new AssetImage(_kBrightnessHighGrey600),
        onChanged: (double value) {
          setState(() {
            _brightnessSliderValue = value;
          });
        },
      );

  Widget _airplaneModeToggleIcon() => new ToggleIcon(
        key: _kAirplaneModeToggle,
        imageList: <String>[
          _kAirplaneModeInactiveGrey600,
          _kAirplaneModeActiveBlack,
        ],
        initialImageIndex: 1,
        width: _kIconSize,
        height: _kIconSize,
      );

  Widget _doNotDisturbToggleIcon() => new ToggleIcon(
        key: _kDoNotDisturbModeToggle,
        imageList: <String>[
          _kDoNoDisturbOnBlack,
          _kDoNoDisturbOffGrey600,
        ],
        initialImageIndex: 0,
        width: _kIconSize,
        height: _kIconSize,
      );

  Widget _screenRotationToggleIcon() => new ToggleIcon(
        key: _kScreenRotationToggle,
        imageList: <String>[
          _kScreenLockRotationBlack,
          _kScreenRotationBlack,
        ],
        initialImageIndex: 0,
        width: _kIconSize,
        height: _kIconSize,
      );

  Widget _buildForNarrowScreen(BuildContext context) {
    return new Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          new Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: _volumeIconSlider()),
          new Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: _brightnessIconSlider()),
          new Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: _divider()),
          new Row(children: <Widget>[
            new Expanded(
              flex: 1,
              child: _airplaneModeToggleIcon(),
            ),
            new Expanded(
              flex: 1,
              child: _doNotDisturbToggleIcon(),
            ),
            new Expanded(
              flex: 1,
              child: _screenRotationToggleIcon(),
            ),
          ]),
        ]);
  }

  Widget _buildForWideScreen(BuildContext context) =>
      new Row(children: <Widget>[
        new Expanded(
          flex: 3,
          child: _volumeIconSlider(),
        ),
        new Expanded(
          flex: 3,
          child: _brightnessIconSlider(),
        ),
        new Expanded(
          flex: 1,
          child: _airplaneModeToggleIcon(),
        ),
        new Expanded(
          flex: 1,
          child: _doNotDisturbToggleIcon(),
        ),
        new Expanded(
          flex: 1,
          child: _screenRotationToggleIcon(),
        ),
      ]);

  @override
  Widget build(BuildContext context) {
    return new Material(
      type: MaterialType.canvas,
      color: Colors.transparent,
      child: new Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          new Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: new LayoutBuilder(
              builder: (BuildContext context, BoxConstraints constraints) =>
                  new Opacity(
                    opacity: widget.opacity,
                    child: (constraints.maxWidth > _kMultiColumnWidthThreshold)
                        ? _buildForWideScreen(context)
                        : _buildForNarrowScreen(context),
                  ),
            ),
          ),
          new Container(
            padding: const EdgeInsets.all(16.0),
            child: new Text(
              '${Platform.localHostname}',
              textAlign: TextAlign.center,
              style: new TextStyle(
                fontFamily: 'RobotoMono',
                color: Colors.grey[600],
              ),
            ),
          ),
          _divider(opacity: widget.opacity),
          new GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => widget.onLogoutTapped?.call(),
            onLongPress: () => widget.onLogoutLongPressed?.call(),
            child: new Container(
              padding: const EdgeInsets.all(16.0),
              child: new Opacity(
                opacity: widget.opacity,
                child: new Text(
                  'LOG OUT',
                  textAlign: TextAlign.center,
                  style: new TextStyle(
                    fontWeight: FontWeight.w700,
                    color: Colors.grey[600],
                  ),
                ),
              ),
            ),
          ),
          _divider(opacity: widget.opacity),
          new GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () {
              print('Make Inline Quick Settings into Story!');
            },
            child: new Container(
              padding: const EdgeInsets.all(16.0),
              child: new Opacity(
                opacity: widget.opacity,
                child: new Text(
                  'MORE',
                  textAlign: TextAlign.center,
                  style: new TextStyle(
                    fontWeight: FontWeight.w700,
                    color: Colors.grey[600],
                  ),
                ),
              ),
            ),
          )
        ],
      ),
    );
  }
}
