// Copyright 2017 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:apps.modular.services.auth.account/account.fidl.dart';
import 'package:apps.modular.services.device/user_provider.fidl.dart';
import 'package:flutter/material.dart';
import 'package:lib.widgets/widgets.dart';

import 'user_picker_device_shell_model.dart';

const double _kUserAvatarSizeLarge = 56.0;
const double _kUserAvatarSizeSmall = 48.0;
const double _kButtonWidthLarge = 128.0;
const double _kButtonWidthSmall = 116.0;
const double _kButtonFontSizeLarge = 16.0;
const double _kButtonFontSizeSmall = 14.0;

final BorderRadius _kButtonBorderRadiusPhone =
    new BorderRadius.circular(_kUserAvatarSizeSmall / 2.0);
final BorderRadius _kButtonBorderRadiusLarge =
    new BorderRadius.circular(_kUserAvatarSizeLarge / 2.0);
final Color _kButtonBackgroundColor = Colors.white.withAlpha(100);

/// Called when the user wants to login as [accountId] using [userProvider].
typedef void OnLoginRequest(String accountId, UserProvider userProvider);

/// See [UserPicker.onUserDragStarted].
typedef void OnUserDragStarted(Account account);

/// See [UserPicker.onUserDragCanceled].
typedef void OnUserDragCanceled(Account account);

/// Provides a UI for picking a user.
class UserPicker extends StatelessWidget {
  /// Called when the user want's to log in.
  final OnLoginRequest onLoginRequest;

  /// Indicates if the user is currently logging in.
  final bool loggingIn;

  /// Called when a user starts being dragged.
  final OnUserDragStarted onUserDragStarted;

  /// Called when a user cancels its drag.
  final OnUserDragCanceled onUserDragCanceled;

  /// Called when the add user button is pressed.
  final VoidCallback onAddUser;

  /// Flag for when user is being dragged
  final bool userDragged;

  /// Constructor.
  UserPicker({
    this.onLoginRequest,
    this.loggingIn,
    this.onUserDragStarted,
    this.onUserDragCanceled,
    this.onAddUser,
    this.userDragged,
  });

  Widget _buildUserCircle({
    Account account,
    VoidCallback onTap,
    bool isSmall,
  }) {
    double size = isSmall ? _kUserAvatarSizeSmall : _kUserAvatarSizeLarge;
    return new GestureDetector(
      onTap: () => onTap?.call(),
      child: new Container(
        height: size,
        width: size,
        margin: const EdgeInsets.only(left: 16.0),
        child: new Alphatar.fromNameAndUrl(
          name: account.displayName,
          avatarUrl: _getImageUrl(account),
          size: size,
        ),
      ),
    );
  }

  Widget _buildIconButton({
    VoidCallback onTap,
    bool isSmall,
    IconData icon,
  }) {
    double size = isSmall ? _kUserAvatarSizeSmall : _kUserAvatarSizeLarge;
    return _buildUserActionButton(
      onTap: () => onTap?.call(),
      width: size,
      isSmall: isSmall,
      child: new Center(
        child: new Icon(
          icon,
          color: Colors.white,
          size: size / 2.0,
        ),
      ),
    );
  }

  Widget _buildUserActionButton({
    Widget child,
    VoidCallback onTap,
    bool isSmall,
    double width,
  }) {
    return new GestureDetector(
      onTap: () => onTap?.call(),
      child: new Container(
        height: (isSmall ? _kUserAvatarSizeSmall : _kUserAvatarSizeLarge),
        width: width ?? (isSmall ? _kButtonWidthSmall : _kButtonWidthLarge),
        alignment: FractionalOffset.center,
        margin: const EdgeInsets.only(left: 16.0),
        decoration: new BoxDecoration(
          borderRadius:
              isSmall ? _kButtonBorderRadiusPhone : _kButtonBorderRadiusLarge,
          border: new Border.all(
            color: Colors.white,
            width: 1.0,
          ),
        ),
        child: child,
      ),
    );
  }

  Widget _buildExpandedUserActions({
    UserPickerDeviceShellModel model,
    bool isSmall,
  }) {
    double fontSize = isSmall ? _kButtonFontSizeSmall : _kButtonFontSizeLarge;
    return new Row(
      children: <Widget>[
        _buildIconButton(
          onTap: () => model.hideUserActions(),
          isSmall: isSmall,
          icon: Icons.close,
        ),
        _buildUserActionButton(
          child: new Text(
            'LOGIN',
            style: new TextStyle(
              fontSize: fontSize,
              color: Colors.white,
            ),
          ),
          onTap: () {
            onAddUser?.call();
            model.hideUserActions();
          },
          isSmall: isSmall,
        ),
        _buildUserActionButton(
          child: new Text(
            'GUEST',
            style: new TextStyle(
              fontSize: fontSize,
              color: Colors.white,
            ),
          ),
          onTap: () {
            _loginUser(null, model);
            model.hideUserActions();
          },
          isSmall: isSmall,
        ),
      ],
    );
  }

  String _getImageUrl(Account account) {
    if (account.imageUrl == null) {
      return null;
    }
    Uri uri = Uri.parse(account.imageUrl);
    if (uri.queryParameters['sz'] != null) {
      Map<String, dynamic> queryParameters = new Map<String, dynamic>.from(
        uri.queryParameters,
      );
      queryParameters['sz'] = '160';
      uri = uri.replace(queryParameters: queryParameters);
    }
    return uri.toString();
  }

  Widget _buildUserEntry({
    Account account,
    VoidCallback onTap,
    bool removable: true,
    bool isSmall,
  }) {
    Widget userCard = _buildUserCircle(
      account: account,
      onTap: onTap,
      isSmall: isSmall,
    );

    if (!removable) {
      return userCard;
    }

    return new LongPressDraggable<Account>(
      child: userCard,
      feedback: userCard,
      data: account,
      childWhenDragging: new Opacity(opacity: 0.0, child: userCard),
      feedbackOffset: Offset.zero,
      dragAnchor: DragAnchor.child,
      maxSimultaneousDrags: 1,
      onDragStarted: () => onUserDragStarted?.call(account),
      onDraggableCanceled: (_, __) => onUserDragCanceled?.call(account),
    );
  }

  Widget _buildUserList(UserPickerDeviceShellModel model) {
    return new LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        List<Widget> children = <Widget>[];

        bool isSmall =
            constraints.maxWidth < 600.0 || constraints.maxHeight < 600.0;

        if (model.showingUserActions) {
          children.add(_buildExpandedUserActions(
            model: model,
            isSmall: isSmall,
          ));
        } else {
          children.add(_buildIconButton(
            onTap: model.showUserActions,
            isSmall: isSmall,
            icon: Icons.add,
          ));
        }

        children.addAll(
          model.accounts.map(
            (Account account) => _buildUserEntry(
                  account: account,
                  onTap: () {
                    _loginUser(account.id, model);
                    model.hideUserActions();
                  },
                  isSmall: isSmall,
                ),
          ),
        );

        return new Container(
          height:
              (isSmall ? _kUserAvatarSizeSmall : _kUserAvatarSizeLarge) + 24.0,
          child: new AnimatedOpacity(
            duration: new Duration(milliseconds: 250),
            opacity: userDragged ? 0.0 : 1.0,
            child: new ListView(
              controller: model.userPickerScrollController,
              padding: const EdgeInsets.only(
                bottom: 24.0,
                right: 24.0,
              ),
              scrollDirection: Axis.horizontal,
              reverse: true,
              physics: const BouncingScrollPhysics(),
              shrinkWrap: true,
              children: children,
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) =>
      new ScopedModelDescendant<UserPickerDeviceShellModel>(builder: (
        BuildContext context,
        Widget child,
        UserPickerDeviceShellModel model,
      ) {
        if (model.accounts != null && !loggingIn && model.showingNetworkInfo) {
          return new Stack(
            fit: StackFit.passthrough,
            children: <Widget>[
              _buildUserList(model),
            ],
          );
        } else {
          return new Stack(
            fit: StackFit.passthrough,
            children: <Widget>[
              new Center(
                child: new Container(
                  width: 64.0,
                  height: 64.0,
                  child: new FuchsiaSpinner(),
                ),
              ),
            ],
          );
        }
      });

  void _loginUser(String accountId, UserPickerDeviceShellModel model) =>
      onLoginRequest?.call(accountId, model.userProvider);
}
