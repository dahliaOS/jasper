// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Some common utilities used by other libraries in this package.
library smoke.src.common;

import 'package:smoke/smoke.dart' as smoke show isSubclassOf;

/// Returns [input] adjusted to be within [min] and [max] length. Truncating it
/// if it's longer, or padding it with nulls if it's shorter. The returned list
/// is a new copy if any modification is needed, otherwise [input] is returned.
List adjustList(List input, int min, int max) {
  if (input.length < min) {
    return new List(min)..setRange(0, input.length, input);
  }

  if (input.length > max) {
    return new List(max)..setRange(0, max, input);
  }
  return input;
}

/// Returns whether [metadata] contains any annotation that is either equal to
/// an annotation in [queryAnnotations] or whose type is listed in
/// [queryAnnotations].
bool matchesAnnotation(Iterable metadata, Iterable queryAnnotations) {
  for (var meta in metadata) {
    for (var queryMeta in queryAnnotations) {
      if (meta == queryMeta) return true;
      if (queryMeta is Type && smoke.isSubclassOf(meta.runtimeType, queryMeta))
        return true;
    }
  }
  return false;
}

/// Number of arguments supported by [minArgs] and [maxArgs].
const SUPPORTED_ARGS = 15;

typedef _Func0();
typedef _Func1(a);
typedef _Func2(a, b);
typedef _Func3(a, b, c);
typedef _Func4(a, b, c, d);
typedef _Func5(a, b, c, d, e);
typedef _Func6(a, b, c, d, e, f);
typedef _Func7(a, b, c, d, e, f, g);
typedef _Func8(a, b, c, d, e, f, g, h);
typedef _Func9(a, b, c, d, e, f, g, h, i);
typedef _Func10(a, b, c, d, e, f, g, h, i, j);
typedef _Func11(a, b, c, d, e, f, g, h, i, j, k);
typedef _Func12(a, b, c, d, e, f, g, h, i, j, k, l);
typedef _Func13(a, b, c, d, e, f, g, h, i, j, k, l, m);
typedef _Func14(a, b, c, d, e, f, g, h, i, j, k, l, m, n);
typedef _Func15(a, b, c, d, e, f, g, h, i, j, k, l, m, n, o);

/// Returns the minimum number of arguments that [f] takes as input, in other
/// words, the total number of required arguments of [f]. If [f] expects more
/// than [SUPPORTED_ARGS], this function returns `SUPPORTED_ARGS + 1`.
///
/// For instance, the current implementation only supports calculating the
/// number of arguments between `0` and `3`. If the function takes `4` or more,
/// this function automatically returns `4`.
int minArgs(Function f) {
  if (f is _Func0) return 0;
  if (f is _Func1) return 1;
  if (f is _Func2) return 2;
  if (f is _Func3) return 3;
  if (f is _Func4) return 4;
  if (f is _Func5) return 5;
  if (f is _Func6) return 6;
  if (f is _Func7) return 7;
  if (f is _Func8) return 8;
  if (f is _Func9) return 9;
  if (f is _Func10) return 10;
  if (f is _Func11) return 11;
  if (f is _Func12) return 12;
  if (f is _Func13) return 13;
  if (f is _Func14) return 14;
  if (f is _Func15) return 15;
  return SUPPORTED_ARGS + 1;
}

/// Returns the maximum number of arguments that [f] takes as input, which is
/// the total number of required and optional arguments of [f]. If
/// [f] may take more than [SUPPORTED_ARGS] required arguments, this function
/// returns `-1`. However, if it takes less required arguments, but more than
/// [SUPPORTED_ARGS] arguments including optional arguments, the result will be
/// [SUPPORTED_ARGS].
///
/// For instance, the current implementation only supports calculating the
/// number of arguments between `0` and [SUPPORTED_ARGS].  If the function
/// takes more than [SUPPORTED_ARGS] mandatory arguments, this function
/// returns `-1`, but if the funtion takes
/// `8` mandatory arguments and `10` optional arguments, this function returns
/// [SUPPORTED_ARGS].
int maxArgs(Function f) {
  // We could perform a full modified binary search but we really only care
  // about performance for functions with fewer than 4 arguments.
  if (f is! _Func2) {
    if (f is _Func1) return 1;
    if (f is _Func0) return 0;
    if (f is! _Func4 && f is _Func3) return 3;
    // Fall through to the slow case as the function has has maxArgs > 3.
  } else if (f is! _Func4) {
    return f is _Func3 ? 3 : 2;
  }

  if (f is _Func15) return 15;
  if (f is _Func14) return 14;
  if (f is _Func13) return 13;
  if (f is _Func12) return 12;
  if (f is _Func11) return 11;
  if (f is _Func10) return 10;
  if (f is _Func9) return 9;
  if (f is _Func8) return 8;
  if (f is _Func7) return 7;
  if (f is _Func6) return 6;
  if (f is _Func5) return 5;
  if (f is _Func4) return 4;
  if (f is _Func3) return 3;
  if (f is _Func2) return 2;
  if (f is _Func1) return 1;
  if (f is _Func0) return 0;
  return -1;
}

/// Returns whether [f] can accept [n] arguments.
/// This is equivalent to
/// `n >= minArgs(f) && n <= maxArgs(f)`
/// when [f] accepts at most [SUPPORTED_ARGS].
bool canAcceptNArgs(Function f, int n) {
  switch (n) {
    case 0:
      return f is _Func0;
    case 1:
      return f is _Func1;
    case 2:
      return f is _Func2;
    case 3:
      return f is _Func3;
    case 4:
      return f is _Func4;
    case 5:
      return f is _Func5;
    case 6:
      return f is _Func6;
    case 7:
      return f is _Func7;
    case 8:
      return f is _Func8;
    case 9:
      return f is _Func9;
    case 10:
      return f is _Func10;
    case 11:
      return f is _Func11;
    case 12:
      return f is _Func12;
    case 13:
      return f is _Func13;
    case 14:
      return f is _Func14;
    case 15:
      return f is _Func15;
  }
  return false;
}

/// Shallow comparison of two lists.
bool compareLists(List a, List b, {bool unordered: false}) {
  if (a == null && b != null) return false;
  if (a != null && b == null) return false;
  if (a.length != b.length) return false;
  if (unordered) {
    var countMap = {};
    for (var x in b) {
      var count = countMap[x];
      if (count == null) count = 0;
      countMap[x] = count + 1;
    }
    for (var x in a) {
      var count = countMap[x];
      if (count == null) return false;
      if (count == 1) {
        countMap.remove(x);
      } else {
        countMap[x] = count - 1;
      }
    }
    return countMap.isEmpty;
  } else {
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
  }
  return true;
}

/// Shallow comparison of two maps.
bool compareMaps(Map a, Map b) {
  if (a == null && b != null) return false;
  if (a != null && b == null) return false;
  if (a.length != b.length) return false;
  for (var k in a.keys) {
    if (!b.containsKey(k) || a[k] != b[k]) return false;
  }
  return true;
}
