// Copyright 2016 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:math';

const List<String> _kWords = const <String>[
  'the',
  'be',
  'to',
  'of',
  'and',
  'a',
  'in',
  'that',
  'have',
  'I',
  'it',
  'for',
  'not',
  'on',
  'with',
  'he',
  'as',
  'you',
  'do',
  'at',
  'this',
  'but',
  'his',
  'by',
  'from',
  'they',
  'we',
  'say',
  'her',
  'she',
  'or',
  'an',
  'will',
  'my',
  'one',
  'all',
  'would',
  'there',
  'their',
  'what',
  'so',
  'up',
  'out',
  'if',
  'about',
  'who',
  'get',
  'which',
  'go',
  'me',
  'when',
  'make',
  'can',
  'like',
  'time',
  'no',
  'just',
  'him',
  'know',
  'take',
  'person',
  'into',
  'year',
  'your',
  'good',
  'some',
  'could',
  'them',
  'see',
  'other',
  'than',
  'then',
  'now',
  'look',
  'only',
  'come',
  'its',
  'over',
  'think',
  'also',
  'back',
  'after',
  'use',
  'two',
  'how',
  'our',
  'work',
  'first',
  'well',
  'way',
  'even',
  'new',
  'want',
  'because',
  'any',
  'these',
  'give',
  'day',
  'most',
  'us',
  'acceptable',
  'accidentally',
  'accommodate',
  'acquire',
  'allot',
  'amateur',
  'apparent',
  'argument',
  'atheist',
  'believe',
  'bellwether',
  'calendar',
  'cemetery',
  'changeable',
  'collectible',
  'column',
  'committed',
  'conscience',
  'conscientious',
  'conscious',
  'consensus',
  'daiquiri',
  'definite',
  'discipline',
  'drunkenness',
  'dumbbell',
  'embarrass',
  'equipment',
  'exhilarate',
  'exceed',
  'existence',
  'experience',
  'fiery',
  'foreign',
  'gauge',
  'grateful',
  'guarantee',
  'harass',
  'height',
  'hierarchy',
  'humorous',
  'ignorance',
  'immediate',
  'independent',
  'indispensable',
  'inoculate',
  'intelligence',
  'its',
  'jewelry',
  'judgment',
  'kernel',
  'leisure',
  'liaison',
  'library',
  'license',
  'lightning',
  'maintenance',
  'maneuver',
  'medieval',
  'memento',
  'millennium',
  'miniature',
  'minuscule',
  'mischievous',
  'misspell',
  'neighbor',
  'noticeable',
  'occasionally',
  'occurrence',
  'pastime',
  'perseverance',
  'personnel',
  'playwright',
  'possession',
  'precede',
  'principal',
  'principle',
  'privilege',
  'pronunciation',
  'publicly',
  'questionnaire',
  'receive',
  'recommend',
  'refer',
  'relevant',
  'restaurant',
  'rhyme',
  'rhythm',
  'schedule',
  'separate',
  'sergeant',
  'supersede',
  'their',
  'threshold',
  'twelfth',
  'tyranny',
  'until',
  'vacuum',
  'weather',
  'weird',
  'lasagna',
  'fuchsia',
  'magenta'
];

/// A service that suggests words for a given input.
class WordSuggestionService {
  /// Returns a list of words that are similar to [input].
  List<String> suggestWords(String input) {
    final List<String> suggestedWords = new List<String>.from(_kWords);
    suggestedWords.removeWhere((String a) => levenshteinDistance(input, a) > 3);
    suggestedWords.sort((String a, String b) =>
        levenshteinDistance(input, a) - levenshteinDistance(input, b));
    return suggestedWords;
  }

  /// From https://en.wikipedia.org/wiki/Levenshtein_distance.
  static int levenshteinDistance(String s, String t) {
    // Degenerate cases.
    if (s == t) {
      return 0;
    }
    if (s.length == 0) {
      return t.length;
    }
    if (t.length == 0) {
      return s.length;
    }

    // Create two work vectors of integer distances.
    final List<int> v0 = new List<int>.filled(t.length + 1, 0);
    final List<int> v1 = new List<int>.filled(t.length + 1, 0);

    // Initialize v0 (the previous row of distances).
    // This row is A[0][i]: edit distance for an empty s.
    // The distance is just the number of characters to delete from t.
    for (int i = 0; i < v0.length; i++) {
      v0[i] = i;
    }

    for (int i = 0; i < s.length; i++) {
      // Calculate v1 (current row distances) from the previous row v0.
      // First element of v1 is A[i+1][0].
      // Edit distance is delete (i+1) chars from s to match empty t.
      v1[0] = i + 1;

      // Use formula to fill in the rest of the row.
      for (int j = 0; j < t.length; j++) {
        int cost = (s[i] == t[j]) ? 0 : 1;
        v1[j + 1] = min(v1[j] + 1, min(v0[j + 1] + 1, v0[j] + cost));
      }

      // Copy v1 (current row) to v0 (previous row) for next iteration.
      for (int j = 0; j < v0.length; j++) {
        v0[j] = v1[j];
      }
    }

    return v1[t.length];
  }
}
