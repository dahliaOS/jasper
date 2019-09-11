// Copyright 2016 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:sysui_widgets/default_bundle.dart';

import 'armadillo.dart';
import 'conductor.dart';
import 'context_model.dart';
import 'debug_enabler.dart';
import 'debug_model.dart';
import 'dummy_volume_model.dart';
import 'json_story_generator.dart';
import 'json_suggestion_model.dart';
import 'now_model.dart';
import 'panel_resizing_model.dart';
import 'story_cluster_drag_state_model.dart';
import 'story_drag_transition_model.dart';
import 'story_model.dart';
import 'story_time_randomizer.dart';
import 'story_rearrangement_scrim_model.dart';
import 'suggestion_model.dart';
import 'volume_model.dart';

/// Set to true to enable the performance overlay.
const bool _kShowPerformanceOverlay = false;

/// Set to true to enable dumping of all errors, not just the first one.
const bool _kDumpAllErrors = false;

Future<Null> main() async {
  if (_kDumpAllErrors) {
    FlutterError.onError =
        (FlutterErrorDetails details) => FlutterError.dumpErrorToConsole(
              details,
              forceReport: true,
            );
  }

  JsonSuggestionModel jsonSuggestionModel = new JsonSuggestionModel()
    ..load(defaultBundle);
  JsonStoryGenerator jsonStoryGenerator = new JsonStoryGenerator()
    ..load(defaultBundle);
  StoryModel storyModel = new StoryModel(
    onFocusChanged: jsonSuggestionModel.storyClusterFocusChanged,
  );
  jsonStoryGenerator.addListener(
    () => storyModel.onStoryClustersChanged(jsonStoryGenerator.storyClusters),
  );
  ContextModel contextModel = new ContextModel();
  NowModel nowModel = new NowModel();
  DebugModel debugModel = new DebugModel();
  PanelResizingModel panelResizingModel = new PanelResizingModel();
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

  VolumeModel volumeModel = new DummyVolumeModel();

  Widget app = MaterialApp(
    home: Material(
      type: MaterialType.transparency,
      child: _buildApp(
        suggestionModel: jsonSuggestionModel,
        storyModel: storyModel,
        nowModel: nowModel,
        storyClusterDragStateModel: storyClusterDragStateModel,
        storyRearrangementScrimModel: storyRearrangementScrimModel,
        storyDragTransitionModel: storyDragTransitionModel,
        debugModel: debugModel,
        panelResizingModel: panelResizingModel,
        contextModel: contextModel,
        volumeModel: volumeModel,
       ),
    ),
  );

  runApp(_kShowPerformanceOverlay ? _buildPerformanceOverlay(child: app) : app);

  await SystemChrome.setEnabledSystemUIOverlays(<SystemUiOverlay>[]);
}

Widget _buildApp({
  SuggestionModel suggestionModel,
  StoryModel storyModel,
  NowModel nowModel,
  StoryClusterDragStateModel storyClusterDragStateModel,
  StoryRearrangementScrimModel storyRearrangementScrimModel,
  StoryDragTransitionModel storyDragTransitionModel,
  DebugModel debugModel,
  PanelResizingModel panelResizingModel,
  ContextModel contextModel,
  VolumeModel volumeModel,
}) =>
    new CheckedModeBanner(
      child: new StoryTimeRandomizer(
        storyModel: storyModel,
        child: new DebugEnabler(
          debugModel: debugModel,
          child: new DefaultAssetBundle(
            bundle: defaultBundle,
            child: new Armadillo(
              scopedModelBuilders: <WrapperBuilder>[
                (_, Widget child) => new ScopedModel<VolumeModel>(
                      model: volumeModel,
                      child: child,
                    ),
                (_, Widget child) => new ScopedModel<ContextModel>(
                      model: contextModel,
                      child: child,
                    ),
                (_, Widget child) => new ScopedModel<StoryModel>(
                      model: storyModel,
                      child: child,
                    ),
                (_, Widget child) => new ScopedModel<SuggestionModel>(
                      model: suggestionModel,
                      child: child,
                    ),
                (_, Widget child) => new ScopedModel<NowModel>(
                      model: nowModel,
                      child: child,
                    ),
                (_, Widget child) =>
                    new ScopedModel<StoryClusterDragStateModel>(
                      model: storyClusterDragStateModel,
                      child: child,
                    ),
                (_, Widget child) =>
                    new ScopedModel<StoryRearrangementScrimModel>(
                      model: storyRearrangementScrimModel,
                      child: child,
                    ),
                (_, Widget child) => new ScopedModel<StoryDragTransitionModel>(
                      model: storyDragTransitionModel,
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
              conductor: new Conductor(
                storyClusterDragStateModel: storyClusterDragStateModel,
                nowModel: nowModel,
              ),
            ),
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
          child: new PerformanceOverlay.allEnabled(),
        ),
      ],
    );
