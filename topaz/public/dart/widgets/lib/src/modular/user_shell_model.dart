// Copyright 2017 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:apps.maxwell.services.context/context_provider.fidl.dart';
import 'package:apps.maxwell.services.context/context_publisher.fidl.dart';
import 'package:apps.maxwell.services.suggestion/suggestion_provider.fidl.dart';
import 'package:apps.modular.services.story/story_provider.fidl.dart';
import 'package:apps.modular.services.user/focus.fidl.dart';
import 'package:apps.modular.services.user/user_shell.fidl.dart';
import 'package:lib.widgets/model.dart';
import 'package:meta/meta.dart';

export 'package:lib.widgets/model.dart' show ScopedModel, ScopedModelDescendant;

/// The [Model] that provides services provided to this app's [UserShell].
class UserShellModel extends Model {
  UserShellContext _userShellContext;
  FocusProvider _focusProvider;
  FocusController _focusController;
  VisibleStoriesController _visibleStoriesController;
  StoryProvider _storyProvider;
  SuggestionProvider _suggestionProvider;
  ContextProvider _contextProvider;
  ContextPublisher _contextPublisher;

  /// The [UserShellContext] given to this app's [UserShell].
  UserShellContext get userShellContext => _userShellContext;

  /// The [FocusProvider] given to this app's [UserShell].
  FocusProvider get focusProvider => _focusProvider;

  /// The [FocusController] given to this app's [UserShell].
  FocusController get focusController => _focusController;

  /// The [VisibleStoriesController] given to this app's [UserShell].
  VisibleStoriesController get visibleStoriesController =>
      _visibleStoriesController;

  /// The [StoryProvider] given to this app's [UserShell].
  StoryProvider get storyProvider => _storyProvider;

  /// The [SuggestionProvider] given to this app's [UserShell].
  SuggestionProvider get suggestionProvider => _suggestionProvider;

  /// The [ContextProvider] given to this app's [UserShell].
  ContextProvider get contextProvider => _contextProvider;

  /// The [SuggestionProvider] given to this app's [UserShell].
  ContextPublisher get contextPublisher => _contextPublisher;

  /// Called when this app's [UserShell] is given its services.
  @mustCallSuper
  void onReady(
    UserShellContext userShellContext,
    FocusProvider focusProvider,
    FocusController focusController,
    VisibleStoriesController visibleStoriesController,
    StoryProvider storyProvider,
    SuggestionProvider suggestionProvider,
    ContextProvider contextProvider,
    ContextPublisher contextPublisher,
  ) {
    _userShellContext = userShellContext;
    _focusProvider = focusProvider;
    _focusController = focusController;
    _visibleStoriesController = visibleStoriesController;
    _storyProvider = storyProvider;
    _suggestionProvider = suggestionProvider;
    _contextProvider = contextProvider;
    _contextPublisher = contextPublisher;
    notifyListeners();
  }

  /// Called when the app's [UserShell] stops.
  void onStop() => null;
}
