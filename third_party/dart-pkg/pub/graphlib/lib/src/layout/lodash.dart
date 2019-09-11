library graphlib.layout.util.lodash;

import "dart:math" as Math;

min(Iterable<num> l, [Comparable<num> fn(v)]) {
  if (fn == null) {
    fn = (a) => a;
  }
  return l.reduce((value, elem) => fn(value).compareTo(fn(elem)) < 0 ? value : elem);
}

max(Iterable<num> l, [Comparable<num> fn(v)]) {
  if (fn == null) {
    fn = (a) => a;
  }
  return l.reduce((value, elem) => fn(value).compareTo(fn(elem)) > 0 ? value : elem);
}

List flatten(Iterable a) => a.expand((i) => i).toList();

Map pick(Map a, List keys) {
  var b = {};
  keys.forEach((key) {
    if (a.containsKey(key)) {
      b[key] = a[key];
    }
  });
  return b;
}

Map mapValues(Map a, Comparable fn(k, v)) {
  var b = {};
  a.forEach((k, v) {
    b[k] = fn(k, v);
  });
  return b;
}

Map defaults(Map a, Map defs) {
  defs.forEach((k, v) {
    if (!a.containsKey(k)) {
      a[k] = v;
    }
  });
  return defs;
}

//Map merge(Map dest, Map src, fn(a, b), self) {
Map merge(Map dest, Iterable<Map> sources) {
  sources.forEach((Map src) {
    src.forEach((k, v) {
      if (dest.containsKey(k)) {
        dest[k] = v;
      }
    });
  });
  return dest;
}

List pluck(Iterable<Map> arr, key) {
  var l = [];
  arr.forEach((m) {
    if (m.containsKey(key)) {
      l.add(m[key]);
    }
  });
  return l;
}

int nextId = 0;
uniqueId(prefix) => "$prefix${++nextId}";

List<int> range(int start, [int stop, int step=1]) {
  if (stop == null) {
    stop = start;
    start = 0;
  }
  var length = Math.max(0, ((stop - start) / step).ceil());
  return new List<int>.generate(length, (int i) {
    var xi = start;
    start += step;
    return xi;
  });
}
