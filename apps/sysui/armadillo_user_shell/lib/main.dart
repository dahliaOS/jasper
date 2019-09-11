// Copyright 2016 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:application.lib.app.dart/app.dart';
import 'package:apps.media.lib.dart/audio_policy.dart';
import 'package:armadillo/armadillo.dart';
import 'package:armadillo/armadillo_drag_target.dart';
import 'package:armadillo/conductor.dart';
import 'package:armadillo/context_model.dart';
import 'package:armadillo/debug_enabler.dart';
import 'package:armadillo/debug_model.dart';
import 'package:armadillo/interruption_overlay.dart';
import 'package:armadillo/now_model.dart';
import 'package:armadillo/panel_resizing_model.dart';
import 'package:armadillo/story_cluster.dart';
import 'package:armadillo/story_cluster_drag_data.dart';
import 'package:armadillo/story_cluster_drag_state_model.dart';
import 'package:armadillo/story.dart';
import 'package:armadillo/story_drag_transition_model.dart';
import 'package:armadillo/story_model.dart';
import 'package:armadillo/story_rearrangement_scrim_model.dart';
import 'package:armadillo/story_time_randomizer.dart';
import 'package:armadillo/suggestion_model.dart';
import 'package:armadillo/volume_model.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:lib.logging/logging.dart';
import 'package:lib.widgets/modular.dart';
import 'package:lib.widgets/widgets.dart';
import 'package:sysui_widgets/default_bundle.dart';

import 'armadillo_user_shell_model.dart';
import 'audio_policy_volume_model.dart';
import 'context_provider_context_model.dart';
import 'focus_request_watcher_impl.dart';
import 'hit_test_model.dart';
import 'initial_focus_setter.dart';
import 'initial_story_generator.dart';
import 'story_provider_story_generator.dart';
import 'suggestion_provider_suggestion_model.dart';
import 'user_logoutter.dart';

/// Set to true to enable the performance overlay.
const bool _kShowPerformanceOverlay = false;

/// Set to true to enable dumping of all errors, not just the first one.
const bool _kDumpAllErrors = false;

Future<Null> main() async {
  setupLogger(name: 'armadillo');

  if (_kDumpAllErrors) {
    FlutterError.onError =
        (FlutterErrorDetails details) => FlutterError.dumpErrorToConsole(
              details,
              forceReport: true,
            );
  }

  HitTestModel hitTestModel = new HitTestModel();
  InitialStoryGenerator initialStoryGenerator = new InitialStoryGenerator()
    ..load(defaultBundle);
  InitialFocusSetter initialFocusSetter = new InitialFocusSetter();

  StoryProviderStoryGenerator storyProviderStoryGenerator =
      new StoryProviderStoryGenerator(
    onNoStories: initialStoryGenerator.createStories,
    onStoriesFirstAvailable: initialFocusSetter.onStoriesFirstAvailable,
  );
  StoryClusterDragStateModel storyClusterDragStateModel =
      new StoryClusterDragStateModel();
  StoryRearrangementScrimModel storyRearrangementScrimModel =
      new StoryRearrangementScrimModel();
  storyClusterDragStateModel.addListener(
    () => storyRearrangementScrimModel
        .onDragAcceptableStateChanged(storyClusterDragStateModel.isAcceptable),
  );
  StoryDragTransitionModel storyDragTransitionModel =
      new StoryDragTransitionModel();
  storyClusterDragStateModel.addListener(
    () => storyDragTransitionModel
        .onDragStateChanged(storyClusterDragStateModel.isDragging),
  );

  UserLogoutter userLogoutter = new UserLogoutter();
  GlobalKey<ConductorState> conductorKey = new GlobalKey<ConductorState>();
  GlobalKey<InterruptionOverlayState> interruptionOverlayKey =
      new GlobalKey<InterruptionOverlayState>();
  SuggestionProviderSuggestionModel suggestionProviderSuggestionModel =
      new SuggestionProviderSuggestionModel(
    hitTestModel: hitTestModel,
    interruptionOverlayKey: interruptionOverlayKey,
  );

  StoryModel storyModel = new StoryModel(
    onFocusChanged: suggestionProviderSuggestionModel.storyClusterFocusChanged,
  );
  storyProviderStoryGenerator.addListener(
    () => storyModel.onStoryClustersChanged(
          storyProviderStoryGenerator.storyClusters,
        ),
  );

  suggestionProviderSuggestionModel.storyModel = storyModel;
  suggestionProviderSuggestionModel.addOnFocusLossListener(() {
    conductorKey.currentState.goToOrigin(storyModel);
  });

  StoryFocuser storyFocuser = (String storyId) {
    scheduleMicrotask(() {
      conductorKey.currentState.requestStoryFocus(
        new StoryId(storyId),
        storyModel,
        jumpToFinish: false,
      );
    });
  };

  initialFocusSetter.storyFocuser = storyFocuser;

  FocusRequestWatcherImpl focusRequestWatcher = new FocusRequestWatcherImpl(
    onFocusRequest: (String storyId) {
      // If we don't know about the story that we've been asked to focus, update
      // the story list first.
      if (!storyProviderStoryGenerator.containsStory(storyId)) {
        log.info(
          'Story $storyId isn\'t in the list, querying story provider...',
        );
        storyProviderStoryGenerator.update(() => storyFocuser(storyId));
      } else {
        storyFocuser(storyId);
      }
    },
  );

  ContextProviderContextModel contextProviderContextModel =
      new ContextProviderContextModel();

  ArmadilloUserShellModel model = new ArmadilloUserShellModel(
    storyProviderStoryGenerator: storyProviderStoryGenerator,
    suggestionProviderSuggestionModel: suggestionProviderSuggestionModel,
    focusRequestWatcher: focusRequestWatcher,
    initialFocusSetter: initialFocusSetter,
    userLogoutter: userLogoutter,
    onContextUpdated: contextProviderContextModel.onContextUpdated,
    onUserUpdated: contextProviderContextModel.onUserUpdated,
    contextTopics: ContextProviderContextModel.topics,
  );

  NowModel nowModel = new NowModel();

  Conductor conductor = new Conductor(
    key: conductorKey,
    blurScrimmedChildren: false,
    onQuickSettingsOverlayChanged: hitTestModel.onQuickSettingsOverlayChanged,
    onSuggestionsOverlayChanged: hitTestModel.onSuggestionsOverlayChanged,
    storyClusterDragStateModel: storyClusterDragStateModel,
    nowModel: nowModel,
    onLogoutTapped: userLogoutter.logout,
    onLogoutLongPressed: userLogoutter.logoutAndResetLedgerState,
    interruptionOverlayKey: interruptionOverlayKey,
    onInterruptionDismissed:
        suggestionProviderSuggestionModel.onInterruptionDismissal,
    onUserContextTapped: model.onUserContextTapped,
  );

  DebugModel debugModel = new DebugModel();
  PanelResizingModel panelResizingModel = new PanelResizingModel();
  ApplicationContext applicationContext =
      new ApplicationContext.fromStartupInfo();
  VolumeModel volumeModel = new AudioPolicyVolumeModel(
    audioPolicy: new AudioPolicy(applicationContext.environmentServices),
  );

  Widget app = new ScopedModel<StoryDragTransitionModel>(
    model: storyDragTransitionModel,
    child: _buildApp(
      storyModel: storyModel,
      storyProviderStoryGenerator: storyProviderStoryGenerator,
      debugModel: debugModel,
      armadillo: new Armadillo(
        scopedModelBuilders: <WrapperBuilder>[
          (_, Widget child) => new ScopedModel<VolumeModel>(
                model: volumeModel,
                child: child,
              ),
          (_, Widget child) => new ScopedModel<ContextModel>(
                model: contextProviderContextModel,
                child: child,
              ),
          (_, Widget child) => new ScopedModel<StoryModel>(
                model: storyModel,
                child: child,
              ),
          (_, Widget child) => new ScopedModel<SuggestionModel>(
                model: suggestionProviderSuggestionModel,
                child: child,
              ),
          (_, Widget child) => new ScopedModel<NowModel>(
                model: nowModel,
                child: child,
              ),
          (_, Widget child) => new ScopedModel<StoryClusterDragStateModel>(
                model: storyClusterDragStateModel,
                child: child,
              ),
          (_, Widget child) => new ScopedModel<StoryRearrangementScrimModel>(
                model: storyRearrangementScrimModel,
                child: child,
              ),
          (_, Widget child) => new ScopedModel<DebugModel>(
                model: debugModel,
                child: child,
              ),
          (_, Widget child) => new ScopedModel<PanelResizingModel>(
                model: panelResizingModel,
                child: child,
              ),
        ],
        conductor: conductor,
      ),
      hitTestModel: hitTestModel,
    ),
  );

  UserShellWidget<ArmadilloUserShellModel> userShellWidget =
      new UserShellWidget<ArmadilloUserShellModel>(
    applicationContext: applicationContext,
    userShellModel: model,
    child:
        _kShowPerformanceOverlay ? _buildPerformanceOverlay(child: app) : app,
  )..advertise();

  runApp(
    new WindowMediaQuery(
      child: userShellWidget,
    ),
  );

  await contextProviderContextModel.load();
}

Widget _buildApp({
  StoryModel storyModel,
  StoryProviderStoryGenerator storyProviderStoryGenerator,
  DebugModel debugModel,
  Armadillo armadillo,
  HitTestModel hitTestModel,
}) =>
    new StoryTimeRandomizer(
      storyModel: storyModel,
      child: new DebugEnabler(
        debugModel: debugModel,
        child: new DefaultAssetBundle(
          bundle: defaultBundle,
          child: new Stack(
            fit: StackFit.passthrough,
            children: <Widget>[
              new ScopedModel<HitTestModel>(
                model: hitTestModel,
                child: armadillo,
              ),
              new Positioned(
                left: 0.0,
                top: 0.0,
                bottom: 0.0,
                width: 108.0,
                child: _buildDiscardDragTarget(
                  storyModel: storyModel,
                  storyProviderStoryGenerator: storyProviderStoryGenerator,
                  controller: new AnimationController(
                    vsync: new _TickerProvider(),
                    duration: const Duration(milliseconds: 200),
                  ),
                ),
              ),
              new Positioned(
                right: 0.0,
                top: 0.0,
                bottom: 0.0,
                width: 108.0,
                child: _buildDiscardDragTarget(
                  storyModel: storyModel,
                  storyProviderStoryGenerator: storyProviderStoryGenerator,
                  controller: new AnimationController(
                    vsync: new _TickerProvider(),
                    duration: const Duration(milliseconds: 200),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );

Widget _buildPerformanceOverlay({Widget child}) => new Stack(
      fit: StackFit.passthrough,
      children: <Widget>[
        child,
        new Positioned(
          top: 0.0,
          left: 0.0,
          right: 0.0,
          child: new IgnorePointer(child: new PerformanceOverlay.allEnabled()),
        ),
        new Align(
          alignment: FractionalOffset.topCenter,
          child: new Text(
            'User shell performance',
            style: new TextStyle(color: Colors.black),
          ),
        ),
      ],
    );

Widget _buildDiscardDragTarget({
  StoryModel storyModel,
  StoryProviderStoryGenerator storyProviderStoryGenerator,
  AnimationController controller,
}) {
  CurvedAnimation curve = new CurvedAnimation(
    parent: controller,
    curve: Curves.fastOutSlowIn,
    reverseCurve: Curves.fastOutSlowIn,
  );
  bool wasEmpty = true;
  return new ArmadilloDragTarget<StoryClusterDragData>(
    onWillAccept: (_, __) => storyModel.storyClusters.every(
        (StoryCluster storyCluster) =>
            storyCluster.focusSimulationKey.currentState.progress == 0.0),
    onAccept: (StoryClusterDragData data, _, __) =>
        storyProviderStoryGenerator.removeStoryCluster(
          data.id,
        ),
    builder: (_, Map<StoryClusterDragData, Offset> candidateData, __) {
      if (candidateData.isEmpty && !wasEmpty) {
        controller.reverse();
      } else if (candidateData.isNotEmpty && wasEmpty) {
        controller.forward();
      }
      wasEmpty = candidateData.isEmpty;

      return new IgnorePointer(
        child: new ScopedModelDescendant<StoryDragTransitionModel>(
          builder: (
            BuildContext context,
            Widget child,
            StoryDragTransitionModel model,
          ) =>
              new Opacity(
                opacity: model.progress,
                child: child,
              ),
          child: new Container(
            color: Colors.black38,
            child: new Center(
              child: new ScaleTransition(
                scale: new Tween<double>(begin: 1.0, end: 1.4).animate(curve),
                child: new Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: <Widget>[
                    new Icon(
                      Icons.delete,
                      color: Colors.white,
                      size: 24.0,
                    ),
                    new Container(height: 8.0),
                    new Text(
                      'REMOVE',
                      style: new TextStyle(
                        fontSize: 10.0,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 1.2,
                        color: Colors.white,
                      ),
                    )
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    },
  );
}

class _TickerProvider extends TickerProvider {
  @override
  Ticker createTicker(TickerCallback onTick) => new Ticker(onTick);
}
