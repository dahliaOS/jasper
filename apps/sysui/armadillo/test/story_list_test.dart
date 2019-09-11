// Copyright 2016 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:armadillo/debug_model.dart';
import 'package:armadillo/panel_resizing_model.dart';
import 'package:armadillo/size_model.dart';
import 'package:armadillo/story.dart';
import 'package:armadillo/story_cluster.dart';
import 'package:armadillo/story_cluster_drag_state_model.dart';
import 'package:armadillo/story_drag_transition_model.dart';
import 'package:armadillo/story_list.dart';
import 'package:armadillo/story_list_layout.dart';
import 'package:armadillo/story_model.dart';
import 'package:armadillo/story_rearrangement_scrim_model.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/widgets.dart';

const int _kStoryCount = 4;
const double _kWidthSingleColumn = 500.0;
const double _kHorizontalMarginsSingleColumn = 16.0;
const double _kWidthMultiColumn = 700.0;
const double _kHeight = 600.0;
const double _kStoryBarMaximizedHeight = 48.0;

void main() {
  testWidgets('Single Column StoryList children extend to fit parent',
      (WidgetTester tester) async {
    GlobalKey storyListKey = new GlobalKey();
    ScrollController scrollController = new ScrollController();

    List<GlobalKey> storyKeys =
        new List<GlobalKey>.generate(4, (int index) => new GlobalKey());

    StoryList storyList = new StoryList(
      key: storyListKey,
      overlayKey: new GlobalKey(),
      parentSize: new Size(_kWidthSingleColumn, _kHeight),
      scrollController: scrollController,
    );
    StoryModel storyModel = new _DummyStoryModel(storyKeys: storyKeys);
    await tester.pumpWidget(
      _wrapWithModels(
        storyModel: storyModel,
        child: new Center(
          child: new SizedBox(
            width: _kWidthSingleColumn,
            height: _kHeight,
            child: storyList,
          ),
        ),
      ),
    );
    expect(find.byKey(storyListKey), isNotNull);
    expect(tester.getSize(find.byKey(storyListKey)).width, _kWidthSingleColumn);
    storyKeys.forEach((GlobalKey key) {
      final Finder finder = find.byKey(key);
      expect(finder, isNotNull);
      final Size size = tester.getSize(finder);
      expect(size.width, _kWidthSingleColumn);
    });
  });

  testWidgets(
      'Multicolumn StoryList children do not extend to fit parent and are instead 16/9 aspect ratio',
      (WidgetTester tester) async {
    GlobalKey storyListKey = new GlobalKey();
    ScrollController scrollController = new ScrollController();

    List<GlobalKey> storyKeys =
        new List<GlobalKey>.generate(4, (int index) => new GlobalKey());

    StoryList storyList = new StoryList(
      key: storyListKey,
      overlayKey: new GlobalKey(),
      parentSize: new Size(_kWidthMultiColumn, _kHeight),
      scrollController: scrollController,
    );
    StoryModel storyModel = new _DummyStoryModel(storyKeys: storyKeys);

    await tester.pumpWidget(
      _wrapWithModels(
        storyModel: storyModel,
        child: new Center(
          child: new SizedBox(
            width: _kWidthMultiColumn,
            height: _kHeight,
            child: storyList,
          ),
        ),
      ),
    );
    expect(find.byKey(storyListKey), isNotNull);
    expect(tester.getSize(find.byKey(storyListKey)).width, _kWidthMultiColumn);
    storyKeys.forEach((GlobalKey key) {
      final Finder finder = find.byKey(key);
      expect(finder, isNotNull);
      final Size size = tester.getSize(finder);
      expect(size.width, _kWidthMultiColumn);
      expect(size.height, _kHeight - _kStoryBarMaximizedHeight);
    });
  });
}

class _DummyStoryModel extends StoryModel {
  final List<GlobalKey> storyKeys;

  _DummyStoryModel({this.storyKeys});

  @override
  List<StoryCluster> get storyClusters => new List<StoryCluster>.generate(
        storyKeys.length,
        (int index) => new StoryCluster(
              stories: <Story>[
                new Story(
                  id: new StoryId(storyKeys[index]),
                  builder: (_) => new Container(key: storyKeys[index]),
                  title: '',
                  avatar: (_, __) => new Container(),
                  lastInteraction: new DateTime.now(),
                  cumulativeInteractionDuration: const Duration(minutes: 5),
                  themeColor: new Color(0xFFFFFFFF),
                ),
              ],
              storyLayout: new _DummyStoryLayout(),
            ),
      );

  @override
  List<StoryCluster> get activeSortedStoryClusters => storyClusters;
}

class _DummyStoryLayout extends StoryLayout {
  @override
  Size get size => new Size(200.0, 200.0);

  @override
  Offset get offset => Offset.zero;

  @override
  Rect get bounds => offset & size;
}

Widget _wrapWithModels({Widget child, StoryModel storyModel}) =>
    new ScopedModel<DebugModel>(
      model: new DebugModel(),
      child: new ScopedModel<PanelResizingModel>(
        model: new PanelResizingModel(),
        child: new ScopedModel<StoryModel>(
          model: storyModel,
          child: new ScopedModel<StoryClusterDragStateModel>(
            model: new StoryClusterDragStateModel(),
            child: new ScopedModel<StoryRearrangementScrimModel>(
              model: new StoryRearrangementScrimModel(),
              child: new ScopedModel<StoryDragTransitionModel>(
                model: new StoryDragTransitionModel(),
                child: child,
              ),
            ),
          ),
        ),
      ),
    );
