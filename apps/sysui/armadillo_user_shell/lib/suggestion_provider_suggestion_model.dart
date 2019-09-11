// Copyright 2016 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io';

import 'package:apps.maxwell.services.suggestion/suggestion_display.fidl.dart'
    as maxwell;
import 'package:apps.maxwell.services.suggestion/suggestion_provider.fidl.dart'
    as maxwell;
import 'package:apps.maxwell.services.suggestion/user_input.fidl.dart'
    as maxwell;
import 'package:apps.modular.services.user/focus.fidl.dart';
import 'package:armadillo/interruption_overlay.dart';
import 'package:armadillo/story.dart';
import 'package:armadillo/story_cluster.dart';
import 'package:armadillo/story_cluster_id.dart';
import 'package:armadillo/story_model.dart';
import 'package:armadillo/suggestion.dart';
import 'package:armadillo/suggestion_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:lib.logging/logging.dart';
import 'package:meta/meta.dart';

import 'hit_test_model.dart';

const int _kMaxSuggestions = 100;

final Map<maxwell.SuggestionImageType, ImageType> _kImageTypeMap =
    <maxwell.SuggestionImageType, ImageType>{
  maxwell.SuggestionImageType.person: ImageType.circular,
  maxwell.SuggestionImageType.other: ImageType.rectangular,
};

/// Listens to a maxwell suggestion list.  As suggestions change it
/// notifies its [suggestionListener].
class _MaxwellSuggestionListenerImpl extends maxwell.SuggestionListener {
  final String prefix;
  final VoidCallback suggestionListener;
  final _InterruptionListener interruptionListener;
  final bool downgradeInterruptions;
  final List<Suggestion> _suggestions = <Suggestion>[];
  final List<Suggestion> _interruptions = <Suggestion>[];

  _MaxwellSuggestionListenerImpl({
    this.prefix,
    this.suggestionListener,
    this.interruptionListener,
    this.downgradeInterruptions: false,
  });

  List<Suggestion> get suggestions => _suggestions.toList();
  List<Suggestion> get interruptions => _interruptions.toList();

  @override
  void onAdd(List<maxwell.Suggestion> suggestions) {
    log.fine('$prefix onAdd $suggestions');
    suggestions.forEach(
      (maxwell.Suggestion suggestion) {
        if (downgradeInterruptions ||
            suggestion.display.annoyance == maxwell.AnnoyanceType.none) {
          _suggestions.add(_convert(suggestion));
        } else {
          Suggestion interruption = _convert(suggestion);
          _interruptions.add(interruption);
          interruptionListener.onInterruptionAdded(interruption);
        }
      },
    );
    suggestionListener?.call();
  }

  @override
  void onRemove(String uuid) {
    log.fine('$prefix onRemove $uuid');
    _suggestions.removeWhere(
      (Suggestion suggestion) => suggestion.id.value == uuid,
    );
    if (_interruptions
        .where((Suggestion suggestion) => suggestion.id.value == uuid)
        .isNotEmpty) {
      _interruptions.removeWhere(
        (Suggestion suggestion) => suggestion.id.value == uuid,
      );
      interruptionListener.onInterruptionRemoved(uuid);
    }
    suggestionListener?.call();
  }

  @override
  void onRemoveAll() {
    log.fine('$prefix onRemoveAll');
    List<Suggestion> interruptionsToRemove = _interruptions.toList();
    _interruptions.clear();
    interruptionsToRemove.forEach(
      (Suggestion suggestion) => interruptionListener.onInterruptionRemoved(
            suggestion.id.value,
          ),
    );
    _suggestions.clear();
    suggestionListener?.call();
  }
}

/// Called when an interruption occurs.
typedef void OnInterruptionAdded(Suggestion interruption);

/// Called when an interruption has been removed.
typedef void OnInterruptionRemoved(String id);

/// Listens for interruptions from maxwell.
class _InterruptionListener extends maxwell.SuggestionListener {
  /// Called when an interruption occurs.
  final OnInterruptionAdded onInterruptionAdded;

  /// Called when an interruption is finished.
  final OnInterruptionRemoved onInterruptionRemoved;

  /// Called when all interruptions are finished.
  final VoidCallback onInterruptionsRemoved;

  /// Constructor.
  _InterruptionListener({
    @required this.onInterruptionAdded,
    @required this.onInterruptionRemoved,
    @required this.onInterruptionsRemoved,
  });

  @override
  void onAdd(List<maxwell.Suggestion> suggestions) => suggestions.forEach(
        (maxwell.Suggestion suggestion) =>
            onInterruptionAdded(_convert(suggestion)),
      );

  @override
  void onRemove(String uuid) {
    // TODO(apwilson): decide what to do with a removed interruption.
    onInterruptionRemoved(uuid);
  }

  @override
  void onRemoveAll() {
    // TODO(apwilson): decide what to do with a removed interruption.
    onInterruptionsRemoved();
  }
}

Suggestion _convert(maxwell.Suggestion suggestion) {
  bool hasImage = suggestion.display.imageUrl?.isNotEmpty ?? false;
  bool hasIcon = suggestion.display.iconUrls?.isNotEmpty ?? false
      ? suggestion.display.iconUrls[0]?.isNotEmpty ?? false
      : false;
  ImageType imageType = (hasImage &&
              suggestion.display.imageType ==
                  maxwell.SuggestionImageType.person) ||
          (!hasImage && hasIcon)
      ? ImageType.circular
      : ImageType.rectangular;
  String imageUrl = hasImage
      ? suggestion.display.imageUrl
      : hasIcon ? suggestion.display.iconUrls[0] : null;
  return new Suggestion(
    id: new SuggestionId(suggestion.uuid),
    title: suggestion.display.headline,
    description: suggestion.display.subheadline,
    themeColor: new Color(suggestion.display.color),
    selectionType: SelectionType.launchStory,
    icons: const <WidgetBuilder>[],
    image: imageUrl != null
        ? (_) => imageUrl.startsWith('http')
            ? new Image.network(
                imageUrl,
                fit: BoxFit.cover,
                alignment: FractionalOffset.center,
              )
            : new Image.file(
                new File(imageUrl),
                fit: BoxFit.cover,
                alignment: FractionalOffset.center,
              )
        : null,
    imageType: imageType,
    imageSide: hasImage &&
            suggestion.display.imageType == maxwell.SuggestionImageType.person
        ? ImageSide.left
        : ImageSide.right,
  );
}

/// Creates a list of suggestions for the SuggestionList using the
/// [maxwell.SuggestionProvider].
class SuggestionProviderSuggestionModel extends SuggestionModel {
  // Controls how many suggestions we receive from maxwell's Ask suggestion
  // stream as well as indicates what the user is asking.
  final maxwell.AskControllerProxy _askControllerProxy =
      new maxwell.AskControllerProxy();

  final maxwell.SuggestionListenerBinding _askListenerBinding =
      new maxwell.SuggestionListenerBinding();

  // Listens for changes to maxwell's ask suggestion list.
  _MaxwellSuggestionListenerImpl _askListener;

  // Controls how many suggestions we receive from maxwell's Next suggestion
  // stream.
  final maxwell.NextControllerProxy _nextControllerProxy =
      new maxwell.NextControllerProxy();

  final maxwell.SuggestionListenerBinding _nextListenerBinding =
      new maxwell.SuggestionListenerBinding();

  // Listens for changes to maxwell's next suggestion list.
  _MaxwellSuggestionListenerImpl _nextListener;

  _InterruptionListener _interruptionListener;

  /// The key for the interruption overlay.
  final GlobalKey<InterruptionOverlayState> interruptionOverlayKey;

  final List<Suggestion> _currentInterruptions = <Suggestion>[];

  /// When the user is asking via text or voice we want to show the maxwell ask
  /// suggestions rather than the normal maxwell suggestion list.
  String _askText;
  bool _asking = false;

  /// Set from an external source - typically the UserShell.
  maxwell.SuggestionProviderProxy _suggestionProviderProxy;

  /// Set from an external source - typically the UserShell.
  FocusControllerProxy _focusController;

  /// Set from an external source - typically the UserShell.
  VisibleStoriesControllerProxy _visibleStoriesController;

  // Set from an external source - typically the UserShell.
  StoryModel _storyModel;

  StoryClusterId _lastFocusedStoryClusterId;

  final Set<VoidCallback> _focusLossListeners = new Set<VoidCallback>();

  /// Listens for changes to visible stories.
  final HitTestModel hitTestModel;

  /// Constructor.
  SuggestionProviderSuggestionModel({
    this.hitTestModel,
    this.interruptionOverlayKey,
  });

  /// Call to close all the handles opened by this model.
  void close() {
    _askControllerProxy.ctrl.close();
    _askListenerBinding.close();
    _nextControllerProxy.ctrl.close();
    _nextListenerBinding.close();
  }

  /// Setting [suggestionProvider] triggers the loading on suggestions.
  /// This is typically set by the UserShell.
  set suggestionProvider(
    maxwell.SuggestionProviderProxy suggestionProviderProxy,
  ) {
    _suggestionProviderProxy = suggestionProviderProxy;
    _interruptionListener = new _InterruptionListener(
      onInterruptionAdded: (Suggestion interruption) {
        interruptionOverlayKey.currentState.onInterruptionAdded(interruption);
      },
      onInterruptionRemoved: (String uuid) {
        interruptionOverlayKey.currentState.onInterruptionRemoved(uuid);
        _onInterruptionRemoved(uuid);
      },
      onInterruptionsRemoved: () {
        interruptionOverlayKey.currentState.onInterruptionsRemoved();
        _onInterruptionsRemoved();
      },
    );
    _askListener = new _MaxwellSuggestionListenerImpl(
      prefix: 'ask',
      suggestionListener: _onAskSuggestionsChanged,
      interruptionListener: _interruptionListener,
      downgradeInterruptions: true,
    );
    _nextListener = new _MaxwellSuggestionListenerImpl(
      prefix: 'next',
      suggestionListener: _onNextSuggestionsChanged,
      interruptionListener: _interruptionListener,
    );
    _load();
  }

  /// Sets the [FocusController] called when focus changes.
  set focusController(FocusControllerProxy focusController) {
    _focusController = focusController;
  }

  /// Sets the [VisibleStoriesController] called when the list of visible
  /// stories changes.
  set visibleStoriesController(
    VisibleStoriesControllerProxy visibleStoriesController,
  ) {
    _visibleStoriesController = visibleStoriesController;
  }

  /// Sets the [StoryModel] used to get the currently focused and visible
  /// stories.
  set storyModel(StoryModel storyModel) {
    _storyModel = storyModel;
    storyModel.addListener(_onStoryClusterListChanged);
  }

  /// [listener] will be called when no stories are in focus.
  void addOnFocusLossListener(VoidCallback listener) {
    _focusLossListeners.add(listener);
  }

  /// Called when an interruption is no longer showing.
  void onInterruptionDismissal(
    Suggestion interruption,
    DismissalReason reason,
  ) {
    // Ignore the interruption dismissal if its stale.
    switch (reason) {
      case DismissalReason.snoozed:
      case DismissalReason.timedOut:
        if (!_askListener.interruptions.contains(interruption) &&
            !_nextListener.interruptions.contains(interruption)) {
          return;
        }
        _currentInterruptions.insert(0, interruption);
        notifyListeners();
        break;
      default:
        break;
    }
  }

  /// Called when an interruption has been removed.
  void _onInterruptionRemoved(String uuid) {
    _currentInterruptions.removeWhere(
      (Suggestion interruption) => interruption.id.value == uuid,
    );
    notifyListeners();
  }

  /// Called when an interruption has been removed.
  void _onInterruptionsRemoved() {
    _currentInterruptions.clear();
    notifyListeners();
  }

  void _load() {
    _suggestionProviderProxy.initiateAsk(
      _askListenerBinding.wrap(_askListener),
      _askControllerProxy.ctrl.request(),
    );
    _askControllerProxy.setResultCount(_kMaxSuggestions);

    _suggestionProviderProxy.subscribeToNext(
      _nextListenerBinding.wrap(_nextListener),
      _nextControllerProxy.ctrl.request(),
    );
    _nextControllerProxy.setResultCount(_kMaxSuggestions);
  }

  @override
  List<Suggestion> get suggestions {
    if (_asking) {
      return _askListener?.suggestions ?? <Suggestion>[];
    }
    List<Suggestion> suggestions = new List<Suggestion>.from(
      _currentInterruptions,
    );
    suggestions.addAll(_nextListener?.suggestions ?? <Suggestion>[]);
    return suggestions;
  }

  @override
  void onSuggestionSelected(Suggestion suggestion) {
    _suggestionProviderProxy.notifyInteraction(
      suggestion.id.value,
      new maxwell.Interaction()..type = maxwell.InteractionType.selected,
    );
  }

  @override
  set askText(String text) {
    if (_askText != text) {
      _askText = text;
      _askControllerProxy
          .setUserInput(new maxwell.UserInput()..text = text ?? '');
    }
  }

  @override
  set asking(bool asking) {
    if (_asking != asking) {
      _asking = asking;
      if (!_asking) {
        _askControllerProxy.setUserInput(new maxwell.UserInput()..text = '');
      }
      notifyListeners();
    }
  }

  @override
  void storyClusterFocusChanged(StoryCluster storyCluster) {
    _lastFocusedStoryCluster?.removeStoryListListener(_onStoryListChanged);
    storyCluster?.addStoryListListener(_onStoryListChanged);
    _lastFocusedStoryClusterId = storyCluster?.id;
    _onStoryListChanged();
  }

  void _onStoryClusterListChanged() {
    if (_lastFocusedStoryClusterId != null) {
      if (_lastFocusedStoryCluster == null) {
        _lastFocusedStoryClusterId = null;
        _onStoryListChanged();
        _focusLossListeners.forEach((VoidCallback listener) => listener());
      }
    }
  }

  void _onStoryListChanged() {
    _focusController.set(_lastFocusedStoryCluster?.focusedStoryId?.value);

    List<String> visibleStoryIds = _lastFocusedStoryCluster?.stories
            ?.map<String>((Story story) => story.id.value)
            ?.toList() ??
        <String>[];
    hitTestModel.onVisibleStoriesChanged(visibleStoryIds);
    _visibleStoriesController.set(visibleStoryIds);
  }

  StoryCluster get _lastFocusedStoryCluster {
    if (_lastFocusedStoryClusterId == null) {
      return null;
    }
    Iterable<StoryCluster> storyClusters = _storyModel.storyClusters.where(
      (StoryCluster storyCluster) =>
          storyCluster.id == _lastFocusedStoryClusterId,
    );
    if (storyClusters.isEmpty) {
      return null;
    }
    assert(storyClusters.length == 1);
    return storyClusters.first;
  }

  void _onAskSuggestionsChanged() {
    if (_asking) {
      notifyListeners();
    }
  }

  void _onNextSuggestionsChanged() {
    if (!_asking) {
      notifyListeners();
    }
  }
}
