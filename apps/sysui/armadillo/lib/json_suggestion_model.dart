// Copyright 2016 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert' as convert;
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:keyboard/word_suggestion_service.dart';

import 'story.dart';
import 'story_cluster.dart';
import 'suggestion.dart';
import 'suggestion_model.dart';

const String _kJsonUrl = 'packages/armadillo/res/stories.json';

/// A simple suggestion model that reads suggestions from json maps them to
/// stories.
class JsonSuggestionModel extends SuggestionModel {
  var _storySuggestionsMap = <StoryId, List<Suggestion>>{};
  List<Suggestion> _currentSuggestions = [];
  StoryCluster _activeStoryCluster;
  String _askText;
  bool _asking = false;

  /// Loads suggestions from the JSON file [_kJsonUrl] contained in
  /// [assetBundle].
  void load(AssetBundle assetBundle) {
    assetBundle.loadString(_kJsonUrl).then((String json) {
      final Map<String, dynamic> decodedJson = convert.json.decode(json);

      // Load suggestions.
      Map<SuggestionId, Suggestion> suggestionMap =
          new Map<SuggestionId, Suggestion>.fromIterable(
        decodedJson['suggestions'].map(
          (suggestion) {
            final List<dynamic> icons = suggestion['icons'];
            return new Suggestion(
              id: new SuggestionId(suggestion['id']),
              title: suggestion['title'],
              themeColor: suggestion['color'] != null
                  ? new Color(int.parse(suggestion['color']))
                  : Colors.blueGrey[600],
              selectionType: _getSelectionType(suggestion['selection_type']),
              selectionStoryId: new StoryId(suggestion['story_id']),
              icons: icons != null
                  ? icons
                      .map(
                        (icon) => (BuildContext context) => new Image.asset(
                            icon,
                            fit: BoxFit.cover,
                            color: Colors.white),
                      )
                      .toList()
                  : const <WidgetBuilder>[],
              image: suggestion['image'] != null
                  ? (_) => new Image.asset(
                        suggestion['image'],
                        fit: BoxFit.cover,
                      )
                  : null,
              imageType: _getImageType(suggestion['image_type']),
            );
          },
        ),
        key: (suggestion) => suggestion.id,
        value: (suggestion) => suggestion,
      );

      // Load story suggestions map.
      _storySuggestionsMap = <StoryId, List<Suggestion>>{};

      decodedJson["story_suggestions_map"].forEach((storyId, suggestions) {
        _storySuggestionsMap[new StoryId(storyId)] = suggestions
            .map<Suggestion>(
                (suggestionId) => suggestionMap[new SuggestionId(suggestionId)])
            .toList();
      });

      // Start with no story focus suggestions.
      _currentSuggestions = _storySuggestionsMap[new StoryId('none')];

      notifyListeners();
    });
  }

  SelectionType _getSelectionType(String selectionType) {
    switch (selectionType) {
      case 'launch':
        return SelectionType.launchStory;
      case 'modify':
        return SelectionType.modifyStory;
      case 'nothing':
      default:
        return SelectionType.doNothing;
    }
  }

  ImageType _getImageType(String imageType) {
    switch (imageType) {
      case 'person':
        return ImageType.circular;
      case 'other':
      default:
        return ImageType.rectangular;
    }
  }

  @override
  List<Suggestion> get suggestions => _currentSuggestions;

  @override
  void onSuggestionSelected(Suggestion suggestion) {
    // Do nothing.
  }

  @override
  set askText(String text) {
    String newAskText = text?.toLowerCase();
    if (_askText != newAskText) {
      _askText = newAskText;
      _updateSuggestions();
    }
  }

  @override
  set asking(bool asking) {
    if (_asking != asking) {
      _asking = asking;
      _updateSuggestions();
    }
  }

  @override
  void storyClusterFocusChanged(StoryCluster storyCluster) {
    if (_activeStoryCluster != storyCluster) {
      _activeStoryCluster = storyCluster;
      _updateSuggestions();
    }
  }

  void _updateSuggestions() {
    if (_askText?.isEmpty ?? true) {
      if (_asking) {
        _currentSuggestions = <Suggestion>[];
      } else {
        List<Suggestion> suggestions = <Suggestion>[];
        if (_activeStoryCluster != null) {
          _activeStoryCluster.stories.forEach((Story story) {
            if (_storySuggestionsMap[story.id] != null) {
              _storySuggestionsMap[story.id].forEach((Suggestion suggestion) {
                if (!suggestions.contains(suggestion)) {
                  suggestions.add(suggestion);
                }
              });
            }
          });
        }
        _currentSuggestions = suggestions.isNotEmpty
            ? suggestions
            : _storySuggestionsMap[new StoryId('none')];
      }
    } else {
      List<Suggestion> suggestions = new List<Suggestion>.from(
          _storySuggestionsMap[new StoryId('ask')] ??
              _storySuggestionsMap[new StoryId('none')]);
      suggestions.sort((Suggestion a, Suggestion b) {
        int minADistance = math.min(
          a.title
              .toLowerCase()
              .split(' ')
              .map((String word) =>
                  WordSuggestionService.levenshteinDistance(word, _askText))
              .reduce((int a, int b) => math.min(a, b)),
          WordSuggestionService.levenshteinDistance(
              a.title.toLowerCase(), _askText),
        );

        int minBDistance = math.min(
          b.title
              .toLowerCase()
              .split(' ')
              .map((String word) =>
                  WordSuggestionService.levenshteinDistance(word, _askText))
              .reduce((int a, int b) => math.min(a, b)),
          WordSuggestionService.levenshteinDistance(
              b.title.toLowerCase(), _askText),
        );

        return minADistance - minBDistance;
      });
      _currentSuggestions = suggestions;
    }
    notifyListeners();
  }
}
