// Copyright 2017 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:meta/meta.dart';

import 'launcher.dart';
import 'launcher_toggle.dart';
import 'status_panel.dart';
import 'status_tray.dart';
import 'widgets/system_overlay.dart';
import 'widgets/toggle.dart';
import 'window_playground.dart';

/// Base widget of the user shell.
class RootWidget extends StatefulWidget {
  @override
  _RootState createState() => new _RootState();
}

class _RootState extends State<RootWidget> with TickerProviderStateMixin {
  final GlobalKey<ToggleState> _launcherToggleKey =
      new GlobalKey<ToggleState>();
  final GlobalKey<SystemOverlayState> _launcherOverlayKey =
      new GlobalKey<SystemOverlayState>();
  final GlobalKey<ToggleState> _statusToggleKey = new GlobalKey<ToggleState>();
  final GlobalKey<SystemOverlayState> _statusOverlayKey =
      new GlobalKey<SystemOverlayState>();

  final Tween<double> _overlayScaleTween =
      new Tween<double>(begin: 0.9, end: 1.0);
  final Tween<double> _overlayOpacityTween =
      new Tween<double>(begin: 0.0, end: 1.0);

  @override
  Widget build(BuildContext context) {
    return new Stack(
      fit: StackFit.passthrough,
      children: <Widget>[
        // 1 - Desktop background image.
        new Image.asset(
          'packages/capybara_user_shell/res/background.jpg',
          fit: BoxFit.cover,
        ),

        // 2 - The space where windows live.
        new WindowPlaygroundWidget(),

        // 3 - Launcher panel.
        new SystemOverlay(
          key: _launcherOverlayKey,
          builder: (Animation<double> animation) => new Center(
                child: new AnimatedBuilder(
                  animation: animation,
                  builder: (BuildContext context, Widget child) =>
                      new FadeTransition(
                        opacity: _overlayOpacityTween.animate(animation),
                        child: new ScaleTransition(
                          scale: _overlayScaleTween.animate(animation),
                          child: child,
                        ),
                      ),
                  child: new Launcher(),
                ),
              ),
          callback: (bool visible) {
            _launcherToggleKey.currentState.toggled = visible;
          },
        ),

        // 4 - Status panel.
        new SystemOverlay(
          key: _statusOverlayKey,
          builder: (Animation<double> animation) => new Positioned(
                right: 0.0,
                bottom: 48.0,
                child: new AnimatedBuilder(
                  animation: animation,
                  builder: (BuildContext context, Widget child) =>
                      new FadeTransition(
                        opacity: _overlayOpacityTween.animate(animation),
                        child: new ScaleTransition(
                          scale: _overlayScaleTween.animate(animation),
                          alignment: FractionalOffset.bottomRight,
                          child: child,
                        ),
                      ),
                  child: new StatusPanel(),
                ),
              ),
          callback: (bool visible) {
            _statusToggleKey.currentState.toggled = visible;
          },
        ),

        // 5 - The bottom bar.
        new Positioned(
          left: 0.0,
          right: 0.0,
          bottom: 0.0,
          child: new GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: _hideOverlays,
            child: new Container(
              height: 48.0,
              padding: const EdgeInsets.all(8.0),
              decoration: const BoxDecoration(
                color: Colors.black87,
              ),
              child: new Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  new LauncherToggleWidget(
                    toggleKey: _launcherToggleKey,
                    callback: (bool toggled) => _setOverlayVisibility(
                        overlay: _launcherOverlayKey, visible: toggled),
                  ),
                  new StatusTrayWidget(
                    toggleKey: _statusToggleKey,
                    callback: (bool toggled) => _setOverlayVisibility(
                        overlay: _statusOverlayKey, visible: toggled),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// Hides all overlays except [except] if applicable.
  void _hideOverlays({GlobalKey<SystemOverlayState> except}) {
    <GlobalKey<SystemOverlayState>>[
      _launcherOverlayKey,
      _statusOverlayKey,
    ]
        .where((GlobalKey<SystemOverlayState> overlay) => overlay != except)
        .forEach((GlobalKey<SystemOverlayState> overlay) =>
            overlay.currentState.visible = false);
  }

  /// Sets the given [overlay]'s visibility to [visible].
  /// When showing an overlay, this also hides every other overlay.
  void _setOverlayVisibility({
    @required GlobalKey<SystemOverlayState> overlay,
    @required bool visible,
  }) {
    if (visible) {
      _hideOverlays(except: overlay);
    }
    overlay.currentState.visible = visible;
  }
}
