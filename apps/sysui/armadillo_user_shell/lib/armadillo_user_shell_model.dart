// Copyright 2017 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:apps.modular.services.auth.account/account.fidl.dart';
import 'package:apps.maxwell.services.context/context_provider.fidl.dart';
import 'package:apps.maxwell.services.context/context_publisher.fidl.dart';
import 'package:apps.maxwell.services.suggestion/suggestion_provider.fidl.dart';
import 'package:apps.modular.services.story/story_provider.fidl.dart';
import 'package:apps.modular.services.user/focus.fidl.dart';
import 'package:apps.modular.services.user/user_shell.fidl.dart';
import 'package:lib.widgets/modular.dart';

import 'focus_request_watcher_impl.dart';
import 'initial_focus_setter.dart';
import 'story_provider_story_generator.dart';
import 'suggestion_provider_suggestion_model.dart';
import 'user_logoutter.dart';

const String _kLocationTopic = '/location/home_work';

typedef void _OnContextUpdated(Map<String, String> context);
typedef void _OnUserUpdated(String userName, String userImageUrl);

/// Connects [UserShell]'s services to Armadillo's associated classes.
class ArmadilloUserShellModel extends UserShellModel {
  /// Receives the [StoryProvider].
  final StoryProviderStoryGenerator storyProviderStoryGenerator;

  /// Receives the [SuggestionProvider], [FocusController], and
  /// [VisibleStoriesController].
  final SuggestionProviderSuggestionModel suggestionProviderSuggestionModel;

  /// Watches the [FocusController].
  final FocusRequestWatcherImpl focusRequestWatcher;

  /// Receives the [FocusProvider].
  final InitialFocusSetter initialFocusSetter;

  /// Receives the [UserShellContext].
  final UserLogoutter userLogoutter;

  /// Called when the context updates.
  final _OnContextUpdated onContextUpdated;

  /// Called when the user information changes
  final _OnUserUpdated onUserUpdated;

  /// The list of context topics to listen for changes to.
  final List<String> contextTopics;

  final ContextListenerBinding _contextListenerBinding =
      new ContextListenerBinding();

  final FocusRequestWatcherBinding _focusRequestWatcherBinding =
      new FocusRequestWatcherBinding();

  /// Constructor.
  ArmadilloUserShellModel({
    this.storyProviderStoryGenerator,
    this.suggestionProviderSuggestionModel,
    this.focusRequestWatcher,
    this.initialFocusSetter,
    this.userLogoutter,
    this.onContextUpdated,
    this.onUserUpdated,
    this.contextTopics: const <String>[],
  });

  @override
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
    super.onReady(
      userShellContext,
      focusProvider,
      focusController,
      visibleStoriesController,
      storyProvider,
      suggestionProvider,
      contextProvider,
      contextPublisher,
    );
    userLogoutter.userShellContext = userShellContext;
    focusController.watchRequest(
      _focusRequestWatcherBinding.wrap(focusRequestWatcher),
    );
    initialFocusSetter.focusProvider = focusProvider;
    storyProviderStoryGenerator.storyProvider = storyProvider;
    suggestionProviderSuggestionModel.suggestionProvider = suggestionProvider;
    suggestionProviderSuggestionModel.focusController = focusController;
    suggestionProviderSuggestionModel.visibleStoriesController =
        visibleStoriesController;
    contextProvider.subscribe(
      new ContextQuery()..topics = contextTopics,
      _contextListenerBinding.wrap(
        new _ContextListenerImpl(onContextUpdated),
      ),
    );
    userShellContext.getAccount((Account account) {
      if (account == null) {
        onUserUpdated?.call('Guest', null);
      } else {
        onUserUpdated?.call(account.displayName, account.imageUrl);
      }
    });
  }

  @override
  void onStop() {
    _contextListenerBinding.close();
    _focusRequestWatcherBinding.close();
    suggestionProviderSuggestionModel.close();
    storyProviderStoryGenerator.close();
    super.onStop();
  }

  /// Called when the user context is tapped.
  void onUserContextTapped() {
    _currentLocation = _nextLocation;
    contextPublisher.publish(_kLocationTopic, _currentJsonLocation);
  }

  String get _currentJsonLocation => '{"location":"$_currentLocation"}';
  String _currentLocation = 'unknown';
  String get _nextLocation {
    switch (_currentLocation) {
      case 'home':
        return 'unknown';
      case 'work':
        return 'home';
      default:
        return 'work';
    }
  }
}

class _ContextListenerImpl extends ContextListener {
  final _OnContextUpdated onContextUpdated;

  _ContextListenerImpl(this.onContextUpdated);

  @override
  void onUpdate(ContextUpdate result) {
    onContextUpdated?.call(result.values);
  }
}
