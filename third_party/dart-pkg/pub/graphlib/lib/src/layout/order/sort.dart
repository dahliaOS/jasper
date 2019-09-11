library graphlib.layout.order.sort;

import "../util.dart" as util;

Map sort(entries, [bool biasRight=false]) {
  Map parts = util.partition(entries, (entry) {
    return entry.containsKey("barycenter");
  });
  var sortable = parts["lhs"];
  var unsortable = parts["rhs"]..sort((entryA, entryB) {
    return -entryA["i"].compareTo(-entryB["i"]);
  });
  var vs = [],
      sum = 0,
      weight = 0,
      vsIndex = 0;

  sortable.sort(compareWithBias(biasRight));

  vsIndex = consumeUnsortable(vs, unsortable, vsIndex);

  sortable.forEach((Map entry) {
    vsIndex += entry["vs"].length;
    vs.add(entry["vs"]);
    sum += entry["barycenter"] * entry["weight"];
    weight += entry["weight"];
    vsIndex = consumeUnsortable(vs, unsortable, vsIndex);
  });

  var result = { "vs": util.flatten(vs) };
  if (weight != 0) {
    result["barycenter"] = sum / weight;
    result["weight"] = weight;
  }
  return result;
}

int consumeUnsortable(List vs, List unsortable, int index) {
  var last;
  while (unsortable.length != 0 && (last = unsortable.last)["i"] <= index) {
    unsortable.removeLast();
    vs.add(last["vs"]);
    index++;
  }
  return index;
}

compareWithBias(bool bias) {
  return (Map entryV, Map entryW) {
    if (entryV["barycenter"] < entryW["barycenter"]) {
      return -1;
    } else if (entryV["barycenter"] > entryW["barycenter"]) {
      return 1;
    }

    return !bias ? entryV["i"] - entryW["i"] : entryW["i"] - entryV["i"];
  };
}
