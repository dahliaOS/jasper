// Copyright 2017 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/widgets.dart';

import 'context_model.dart';

const String _kBatteryImageWhite =
    'packages/armadillo/res/ic_battery_90_white_1x_web_24dp.png';
const String _kBatteryImageGrey600 =
    'packages/armadillo/res/ic_battery_90_grey600_1x_web_24dp.png';
const String _kWifiImageGrey600 =
    'packages/armadillo/res/ic_signal_wifi_3_bar_grey600_24dp.png';
const String _kNetworkSignalImageGrey600 =
    'packages/armadillo/res/ic_signal_cellular_connected_no_internet_0_bar_grey600_24dp.png';

enum _ImportantInfoLayoutDelegateParts {
  batteryIcon,
  batteryText,
  wifiIcon,
  wifiText,
  networkIcon,
  networkText,
}

const double _kIconHeight = 20.0;

const TextStyle _kTextStyle = const TextStyle(
  fontSize: 10.0,
  letterSpacing: 1.0,
  fontWeight: FontWeight.w300,
);

const double _kIconSpacing = 8.0;
const double _kTextYShift = 2.0;
const double _kEntrySpacing = 32.0;
const double _kWidthThreshold = 300.0;
const double _kEdgeSpacing = 16.0;
const double _kUserSpacing = 32.0;

/// Displays important info to the user.
class ImportantInfo extends StatelessWidget {
  /// The color of the text of the importnatn info.  This also colors the icons.
  final Color textColor;

  /// Constructor
  ImportantInfo({
    Key key,
    this.textColor,
  })
      : super(key: key);

  @override
  Widget build(BuildContext context) => new ScopedModelDescendant<ContextModel>(
        builder: (BuildContext context, Widget child, ContextModel model) =>
            new LayoutBuilder(
              builder: (BuildContext context, BoxConstraints constraints) {
                List<LayoutId> children = <LayoutId>[
                  new LayoutId(
                    id: _ImportantInfoLayoutDelegateParts.batteryIcon,
                    child: new Image.asset(
                      _kBatteryImageWhite,
                      height: _kIconHeight,
                      color: textColor,
                      fit: BoxFit.cover,
                    ),
                  ),
                  new LayoutId(
                    id: _ImportantInfoLayoutDelegateParts.batteryText,
                    child: new Text(
                      model.batteryPercentage,
                      softWrap: false,
                      overflow: TextOverflow.fade,
                      style: _kTextStyle.copyWith(color: textColor),
                    ),
                  ),
                ];
                if (constraints.maxWidth > _kWidthThreshold) {
                  children.addAll(<LayoutId>[
                    new LayoutId(
                      id: _ImportantInfoLayoutDelegateParts.wifiIcon,
                      child: new Image.asset(
                        _kWifiImageGrey600,
                        height: _kIconHeight,
                        color: textColor,
                        fit: BoxFit.cover,
                      ),
                    ),
                    new LayoutId(
                      id: _ImportantInfoLayoutDelegateParts.wifiText,
                      child: new Text(
                        model.wifiNetwork,
                        softWrap: false,
                        overflow: TextOverflow.fade,
                        style: _kTextStyle.copyWith(color: textColor),
                      ),
                    ),
                  ]);
                }
                return new CustomMultiChildLayout(
                  delegate: new _ImportantInfoLayoutDelegate(),
                  children: children,
                );
              },
            ),
      );
}

class _ImportantInfoLayoutDelegate extends MultiChildLayoutDelegate {
  @override
  void performLayout(Size size) {
    // Lay out children.
    if (hasChild(_ImportantInfoLayoutDelegateParts.wifiIcon)) {
      Size wifiIconSize = layoutChild(
        _ImportantInfoLayoutDelegateParts.wifiIcon,
        new BoxConstraints.loose(size).deflate(
          new EdgeInsets.only(left: _kUserSpacing),
        ),
      );

      Size batteryIconSize = layoutChild(
        _ImportantInfoLayoutDelegateParts.batteryIcon,
        new BoxConstraints.loose(size).deflate(
          new EdgeInsets.only(
              left: wifiIconSize.width + _kIconSpacing + _kUserSpacing),
        ),
      );

      Size batteryTextSize = layoutChild(
        _ImportantInfoLayoutDelegateParts.batteryText,
        new BoxConstraints.loose(size).deflate(
          new EdgeInsets.only(
            left: wifiIconSize.width +
                batteryIconSize.width +
                _kEntrySpacing +
                _kIconSpacing +
                _kUserSpacing,
          ),
        ),
      );

      Size wifiTextSize = layoutChild(
        _ImportantInfoLayoutDelegateParts.wifiText,
        new BoxConstraints.loose(size).deflate(
          new EdgeInsets.only(
            left: wifiIconSize.width +
                batteryIconSize.width +
                batteryTextSize.width +
                _kUserSpacing +
                _kEntrySpacing +
                (2.0 * _kIconSpacing),
          ),
        ),
      );

      // Position children.
      positionChild(
        _ImportantInfoLayoutDelegateParts.wifiText,
        new Offset(_kUserSpacing,
            (size.height - wifiTextSize.height) / 2.0 + _kTextYShift),
      );

      positionChild(
        _ImportantInfoLayoutDelegateParts.wifiIcon,
        new Offset(
          _kUserSpacing + wifiTextSize.width + _kIconSpacing,
          (size.height - wifiIconSize.height) / 2.0,
        ),
      );

      positionChild(
        _ImportantInfoLayoutDelegateParts.batteryText,
        new Offset(
          _kUserSpacing +
              wifiTextSize.width +
              _kIconSpacing +
              wifiIconSize.width +
              _kEntrySpacing,
          (size.height - batteryTextSize.height) / 2.0 + _kTextYShift,
        ),
      );

      positionChild(
        _ImportantInfoLayoutDelegateParts.batteryIcon,
        new Offset(
          _kUserSpacing +
              wifiTextSize.width +
              _kIconSpacing +
              wifiIconSize.width +
              _kEntrySpacing +
              batteryTextSize.width +
              _kIconSpacing,
          (size.height - batteryIconSize.height) / 2.0,
        ),
      );
    } else {
      Size batteryIconSize = layoutChild(
        _ImportantInfoLayoutDelegateParts.batteryIcon,
        new BoxConstraints.loose(size).deflate(
          new EdgeInsets.only(
            left: _kEdgeSpacing + _kUserSpacing / 2.0,
          ),
        ),
      );

      Size batteryTextSize = layoutChild(
        _ImportantInfoLayoutDelegateParts.batteryText,
        new BoxConstraints.loose(size).deflate(
          new EdgeInsets.only(
            left: batteryIconSize.width +
                _kIconSpacing +
                _kEdgeSpacing +
                _kUserSpacing / 2.0,
          ),
        ),
      );

      positionChild(
        _ImportantInfoLayoutDelegateParts.batteryText,
        new Offset(
          size.width -
              _kEdgeSpacing -
              _kIconSpacing -
              batteryIconSize.width -
              batteryTextSize.width,
          (size.height - batteryTextSize.height) / 2.0 + _kTextYShift,
        ),
      );

      positionChild(
        _ImportantInfoLayoutDelegateParts.batteryIcon,
        new Offset(
          size.width - _kEdgeSpacing - batteryIconSize.width,
          (size.height - batteryIconSize.height) / 2.0,
        ),
      );
    }
  }

  @override
  bool shouldRelayout(_ImportantInfoLayoutDelegate oldDelegate) => false;
}
