// Copyright 2016 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:apps.modular.services.story/story_controller.fidl.dart';
import 'package:apps.modular.services.story/story_info.fidl.dart';
import 'package:apps.modular.services.story/story_state.fidl.dart';
import 'package:apps.modular.services.story/story_provider.fidl.dart';
import 'package:apps.mozart.lib.flutter/child_view.dart';
import 'package:apps.mozart.services.views/view_token.fidl.dart';
import 'package:armadillo/story.dart';
import 'package:armadillo/story_cluster.dart';
import 'package:armadillo/story_cluster_id.dart';
import 'package:armadillo/story_generator.dart';
import 'package:flutter/material.dart';
import 'package:lib.fidl.dart/bindings.dart' as bindings;
import 'package:lib.logging/logging.dart';

import 'hit_test_model.dart';
import 'story_importance_watcher_impl.dart';
import 'story_provider_watcher_impl.dart';

const String _kUserImage = 'packages/armadillo/res/User.png';
const int _kMaxActiveClusters = 6;

/// Called when the [StoryProvider] returns no stories.
typedef void OnNoStories(StoryProviderProxy storyProvider);

/// Creates a list of stories for the StoryList using
/// modular's [StoryProvider].
class StoryProviderStoryGenerator extends StoryGenerator {
  final Set<VoidCallback> _listeners = new Set<VoidCallback>();
  bool _firstTime = true;

  /// Set from an external source - typically the UserShell.
  StoryProviderProxy _storyProvider;

  final List<StoryCluster> _storyClusters = <StoryCluster>[];

  final Map<String, StoryControllerProxy> _storyControllerMap =
      <String, StoryControllerProxy>{};

  final StoryProviderWatcherBinding _storyProviderWatcherBinding =
      new StoryProviderWatcherBinding();

  final StoryImportanceWatcherBinding _storyImportanceWatcherBinding =
      new StoryImportanceWatcherBinding();

  /// Called when the [StoryProvider] returns no stories.
  final OnNoStories onNoStories;

  /// Called the first time the [StoryProvider] returns stories.
  final VoidCallback onStoriesFirstAvailable;

  /// Constructor.
  StoryProviderStoryGenerator({this.onNoStories, this.onStoriesFirstAvailable});

  /// Call to close all the handles opened by this story generator.
  void close() {
    _storyProviderWatcherBinding.close();
    _storyImportanceWatcherBinding.close();
    _storyControllerMap.values.forEach(
      (StoryControllerProxy storyControllerProxy) =>
          storyControllerProxy.ctrl.close(),
    );
  }

  /// Sets the [StoryProvider] used to get and start stories.
  set storyProvider(StoryProviderProxy storyProvider) {
    _storyProvider = storyProvider;
    _storyProvider.watch(
      _storyProviderWatcherBinding.wrap(
        new StoryProviderWatcherImpl(
          onStoryChanged: _onStoryChanged,
          onStoryDeleted: (String storyId) => _removeStory(storyId),
        ),
      ),
    );

    _storyProvider.watchImportance(
      _storyImportanceWatcherBinding.wrap(
        new StoryImportanceWatcherImpl(
          onImportanceChanged: () {
            _storyProvider.getImportance((Map<String, double> importance) {
              _currentStories.forEach((Story story) {
                story.importance = importance[story.id.value] ?? 1.0;
              });
              _notifyListeners();
            });
          },
        ),
      ),
    );
    update();
  }

  @override
  void addListener(VoidCallback listener) {
    _listeners.add(listener);
  }

  @override
  void removeListener(VoidCallback listener) {
    _listeners.remove(listener);
  }

  @override
  List<StoryCluster> get storyClusters => _storyClusters;

  /// Removes all the stories in the [StoryCluster] with [storyClusterId] from
  /// the [StoryProvider].
  void removeStoryCluster(StoryClusterId storyClusterId) {
    StoryCluster storyCluster = _storyClusters
        .where((StoryCluster storyCluster) => storyCluster.id == storyClusterId)
        .single;
    storyCluster.stories.forEach((Story story) {
      _storyProvider.deleteStory(story.id.value, () {});
      _removeStory(story.id.value, notify: false);
    });
    _storyClusters.remove(storyCluster);

    _notifyListeners();
  }

  /// Loads the list of previous stories from the [StoryProvider].
  /// If no stories exist, we create some.
  /// If stories do exist, we resume them.
  /// If set, [callback] will be called when the stories have been updated.
  void update([VoidCallback callback]) {
    _storyProvider.previousStories((List<String> storyIds) {
      if (storyIds.isEmpty && storyClusters.isEmpty) {
        // We have no previous stories, so create some!
        onNoStories?.call(_storyProvider);
      } else {
        // Remove any stories that aren't in the previous story list.
        _currentStories
            .where((Story story) => !storyIds.contains(story.id.value))
            .toList()
            .forEach((Story story) {
          log.info('Story ${story.id.value} has been removed!');
          _removeStoryFromClusters(story);
        });

        // Add only those stories we don't already know about.
        final List<String> storiesToAdd = storyIds
            .where((String storyId) => !containsStory(storyId))
            .toList();

        if (storiesToAdd.isEmpty) {
          callback?.call();
        }

        // We have previous stories so lets resume them so they can be
        // displayed in a child view.
        int added = 0;
        storiesToAdd.forEach((String storyId) {
          _getController(storyId);
          _storyControllerMap[storyId]
              .getInfo((StoryInfo storyInfo, StoryState state) {
            _startStory(storyInfo, _storyClusters.length);
            added++;
            if (added == storiesToAdd.length) {
              if (_firstTime) {
                _firstTime = false;
                onStoriesFirstAvailable();
              }
              callback?.call();
            }
          });
        });
      }
    });
  }

  Iterable<Story> get _currentStories => storyClusters.expand(
        (StoryCluster cluster) => cluster.stories,
      );

  /// Returns true if [storyId] is in the list of current stories.
  bool containsStory(String storyId) => _currentStories.any(
        (Story story) => story.id == new StoryId(storyId),
      );

  void _onStoryChanged(StoryInfo storyInfo, StoryState storyState) {
    if (!_storyControllerMap.containsKey(storyInfo.id)) {
      assert(
          storyState == StoryState.initial || storyState == StoryState.stopped);
      _getController(storyInfo.id);
      _startStory(storyInfo, 0);
    }
  }

  void _removeStory(String storyId, {bool notify: true}) {
    if (_storyControllerMap.containsKey(storyId)) {
      _storyControllerMap[storyId].ctrl.close();
      _storyControllerMap.remove(storyId);
      Iterable<Story> stories = _currentStories.where(
        (Story story) => story.id.value == storyId,
      );
      assert(stories.length <= 1);
      if (stories.isNotEmpty) {
        _removeStoryFromClusters(stories.first);
      }
      if (notify) {
        _notifyListeners();
      }
    }
  }

  void _removeStoryFromClusters(Story story) {
    storyClusters
        .where(
            (StoryCluster storyCluster) => storyCluster.stories.contains(story))
        .toList()
        .forEach((StoryCluster storyCluster) {
      if (storyCluster.stories.length == 1) {
        _storyClusters.remove(storyCluster);
        _notifyListeners();
      } else {
        storyCluster.absorb(story);
      }
    });
  }

  void _getController(String storyId) {
    final StoryControllerProxy controller = new StoryControllerProxy();
    _storyControllerMap[storyId] = controller;
    _storyProvider.getController(
      storyId,
      controller.ctrl.request(),
    );
  }

  void _startStory(StoryInfo storyInfo, int startingIndex) {
    log.info('Adding story: $storyInfo');

    // Start it!

    // Create a flutter view from its view!
    StoryCluster storyCluster = new StoryCluster(stories: <Story>[
      _createStory(
        storyInfo: storyInfo,
        storyController: _storyControllerMap[storyInfo.id],
        startingIndex: startingIndex,
      ),
    ]);

    _storyClusters.add(storyCluster);
    _notifyListeners();
  }

  void _notifyListeners() {
    _listeners.toList().forEach((VoidCallback listener) => listener());
  }

  Story _createStory({
    StoryInfo storyInfo,
    StoryController storyController,
    int startingIndex,
  }) {
    String storyTitle = Uri
        .parse(storyInfo.url)
        .pathSegments[Uri.parse(storyInfo.url).pathSegments.length - 1]
        ?.toUpperCase();

    // Add story ID to title only when we're in debug mode.
    assert(() {
      storyTitle = '[$storyTitle // ${storyInfo.id}]';
      return true;
    });
    int initialIndex = startingIndex;

    return new Story(
        id: new StoryId(storyInfo.id),
        builder: (BuildContext context) => new _StoryWidget(
              key: new GlobalObjectKey<_StoryWidgetState>(storyController),
              storyInfo: storyInfo,
              storyController: storyController,
              startingIndex: initialIndex,
            ),
        // TODO(apwilson): Improve title.
        title: storyTitle,
        icons: <OpacityBuilder>[],
        avatar: (_, double opacity) => new Opacity(
              opacity: opacity,
              child: new Image.asset(_kUserImage, fit: BoxFit.cover),
            ),
        lastInteraction: new DateTime.fromMicrosecondsSinceEpoch(
          (storyInfo.lastFocusTime / 1000).round(),
        ),
        cumulativeInteractionDuration: new Duration(
          minutes: 0,
        ),
        themeColor: storyInfo.extra['color'] == null
            ? Colors.grey[500]
            : new Color(int.parse(storyInfo.extra['color'])),
        inactive: false,
        onClusterIndexChanged: (int clusterIndex) {
          _StoryWidgetState state =
              new GlobalObjectKey<_StoryWidgetState>(storyController)
                  .currentState;
          if (state != null) {
            state.index = clusterIndex;
          } else {
            initialIndex = clusterIndex;
          }
        });
  }
}

class _StoryWidget extends StatefulWidget {
  final StoryInfo storyInfo;
  final StoryController storyController;
  final int startingIndex;

  _StoryWidget({
    Key key,
    this.storyInfo,
    this.storyController,
    this.startingIndex,
  })
      : super(key: key);

  @override
  _StoryWidgetState createState() => new _StoryWidgetState();
}

class _StoryWidgetState extends State<_StoryWidget> {
  Completer<Null> _stoppingCompleter;
  ChildViewConnection _childViewConnection;
  int _currentIndex;
  bool _shouldBeStopped = true;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.startingIndex;
    _toggleStartOrStop();
  }

  @override
  Widget build(BuildContext context) {
    return new ScopedModelDescendant<HitTestModel>(
      builder: (
        BuildContext context,
        Widget child,
        HitTestModel hitTestModel,
      ) =>
          _childViewConnection == null
              ? new Offstage()
              : new ChildView(
                  hitTestable:
                      hitTestModel.isStoryHitTestable(widget.storyInfo.id),
                  connection: _childViewConnection,
                ),
    );
  }

  set index(int index) {
    if (_currentIndex != index) {
      _currentIndex = index;
      _toggleStartOrStop();
    }
  }

  void _toggleStartOrStop() {
    if (_currentIndex < _kMaxActiveClusters) {
      _start();
    } else {
      _stop();
    }
  }

  void _start() {
    _shouldBeStopped = false;
    if (_childViewConnection == null) {
      if (_stoppingCompleter != null) {
        _stoppingCompleter.future.then((_) => _startStory);
      } else {
        _startStory();
      }
    }
  }

  void _startStory() {
    if (_shouldBeStopped) {
      return;
    }
    log.info('Starting story: ${widget.storyInfo.id}');
    bindings.InterfacePair<ViewOwner> viewOwner =
        new bindings.InterfacePair<ViewOwner>();
    widget.storyController.start(viewOwner.passRequest());
    setState(() {
      _childViewConnection = new ChildViewConnection(
        viewOwner.passHandle(),
      );
    });
  }

  void _stop() {
    _shouldBeStopped = true;
    if (_childViewConnection != null) {
      if (_stoppingCompleter != null) {
        return;
      }
      _stoppingCompleter = new Completer<Null>();
      log.info('Stopping story: ${widget.storyInfo.id}');
      setState(() {
        _childViewConnection = null;
      });
      widget.storyController.stop(() {
        _stoppingCompleter.complete();
        _stoppingCompleter = null;
      });
    }
  }
}
