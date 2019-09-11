// Copyright 2017 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:apps.maxwell.services.context/context_provider.fidl.dart';
import 'package:apps.maxwell.services.context/context_publisher.fidl.dart';
import 'package:apps.maxwell.services.suggestion/suggestion_provider.fidl.dart';
import 'package:apps.modular.services.story/story_provider.fidl.dart';
import 'package:apps.modular.services.user/focus.fidl.dart';
import 'package:apps.modular.services.user/user_shell.fidl.dart';
import 'package:lib.fidl.dart/bindings.dart';

/// Called when [UserShell.initialize] occurs.
typedef void OnUserShellReady(
  UserShellContext userShellContext,
  FocusProvider focusProvider,
  FocusController focusController,
  VisibleStoriesController visibleStoriesController,
  StoryProvider storyProvider,
  SuggestionProvider suggestionProvider,
  ContextProvider contextProvider,
  ContextPublisher contextPublisher,
);

/// Called when [UserShell.terminate] occurs.
typedef void OnUserShellStop();

/// Implements a UserShell for receiving the services a [UserShell] needs to
/// operate.
class UserShellImpl extends UserShell {
  final UserShellContextProxy _userShellContextProxy =
      new UserShellContextProxy();
  final FocusProviderProxy _focusProviderProxy = new FocusProviderProxy();
  final FocusControllerProxy _focusControllerProxy = new FocusControllerProxy();
  final VisibleStoriesControllerProxy _visibleStoriesControllerProxy =
      new VisibleStoriesControllerProxy();
  final StoryProviderProxy _storyProviderProxy = new StoryProviderProxy();
  final SuggestionProviderProxy _suggestionProviderProxy =
      new SuggestionProviderProxy();
  final ContextProviderProxy _contextProviderProxy = new ContextProviderProxy();
  final ContextPublisherProxy _contextPublisherProxy =
      new ContextPublisherProxy();

  /// Called when [initialize] occurs.
  final OnUserShellReady onReady;

  /// Called when the [UserShell] terminates.
  final OnUserShellStop onStop;

  /// Constructor.
  UserShellImpl({
    this.onReady,
    this.onStop,
  });

  @override
  void initialize(
    InterfaceHandle<UserShellContext> userShellContextHandle,
  ) {
    if (onReady != null) {
      _userShellContextProxy.ctrl.bind(userShellContextHandle);
      _userShellContextProxy.getStoryProvider(
        _storyProviderProxy.ctrl.request(),
      );
      _userShellContextProxy.getSuggestionProvider(
        _suggestionProviderProxy.ctrl.request(),
      );
      _userShellContextProxy.getVisibleStoriesController(
        _visibleStoriesControllerProxy.ctrl.request(),
      );
      _userShellContextProxy.getFocusController(
        _focusControllerProxy.ctrl.request(),
      );
      _userShellContextProxy.getFocusProvider(
        _focusProviderProxy.ctrl.request(),
      );

      _userShellContextProxy.getContextProvider(
        _contextProviderProxy.ctrl.request(),
      );
      _userShellContextProxy.getContextPublisher(
        _contextPublisherProxy.ctrl.request(),
      );

      onReady(
        _userShellContextProxy,
        _focusProviderProxy,
        _focusControllerProxy,
        _visibleStoriesControllerProxy,
        _storyProviderProxy,
        _suggestionProviderProxy,
        _contextProviderProxy,
        _contextPublisherProxy,
      );
    }
  }

  @override
  void terminate(void done()) {
    onStop?.call();
    _userShellContextProxy.ctrl.close();
    _storyProviderProxy.ctrl.close();
    _suggestionProviderProxy.ctrl.close();
    _visibleStoriesControllerProxy.ctrl.close();
    _focusControllerProxy.ctrl.close();
    _focusProviderProxy.ctrl.close();
    _contextProviderProxy.ctrl.close();
    _contextPublisherProxy.ctrl.close();
    done();
  }
}
