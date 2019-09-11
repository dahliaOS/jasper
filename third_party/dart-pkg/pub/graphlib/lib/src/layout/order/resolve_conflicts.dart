library graphlib.layout.order.resolve_conflicts;

import "dart:math" as Math;
import "../../graph.dart" show Graph;
import "../util.dart" as util;

/// Given a list of entries of the form {v, barycenter, weight} and a
/// constraint graph this function will resolve any conflicts between the
/// constraint graph and the barycenters for the entries. If the barycenters for
/// an entry would violate a constraint in the constraint graph then we coalesce
/// the nodes in the conflict into a new node that respects the contraint and
/// aggregates barycenter and weight information.
///
/// This implementation is based on the description in Forster, "A Fast and
/// Simple Hueristic for Constrained Two-Level Crossing Reduction," thought it
/// differs in some specific details.
///
/// Pre-conditions:
///
///    1. Each entry has the form {v, barycenter, weight}, or if the node has
///       no barycenter, then {v}.
///
/// Returns:
///
///    A new list of entries of the form {vs, i, barycenter, weight}. The list
///    `vs` may either be a singleton or it may be an aggregation of nodes
///    ordered such that they do not violate constraints from the constraint
///    graph. The property `i` is the lowest original index of any of the
///    elements in `vs`.
List<Map> resolveConflicts(Iterable<Map> entries, Graph cg) {
  var mappedEntries = {};
  int i = 0;
  entries.forEach((entry) {
    var tmp = mappedEntries[entry["v"]] = {
      "indegree": 0,
      "in": [],
      "out": [],
      "vs": [entry["v"]],
      "i": i
    };
    if (entry["barycenter"] != null) {
      tmp["barycenter"] = entry["barycenter"];
      tmp["weight"] = entry["weight"];
    }
    i++;
  });

  cg.edges.forEach((e) {
    Map entryV = mappedEntries[e.v],
        entryW = mappedEntries[e.w];
    if (entryV != null && entryW != null) {
      entryW["indegree"]++;
      entryV["out"].add(mappedEntries[e.w]);
    }
  });

  var sourceSet = mappedEntries.values.where((entry) {
    return entry["indegree"] == null || entry["indegree"] == 0;
  }).toList();

  return doResolveConflicts(sourceSet);
}

List<Map> doResolveConflicts(List<Map> sourceSet) {
  var entries = [];

  handleIn(Map vEntry) {
    return (Map uEntry) {
      if (uEntry.containsKey("merged") && uEntry["merged"]) {
        return;
      }
      if (uEntry["barycenter"] == null ||
          vEntry["barycenter"] == null ||
          uEntry["barycenter"] >= vEntry["barycenter"]) {
        mergeEntries(vEntry, uEntry);
      }
    };
  }

  handleOut(Map vEntry) {
    return (Map wEntry) {
      wEntry["in"].add(vEntry);
      if (--wEntry["indegree"] == 0) {
        sourceSet.add(wEntry);
      }
    };
  }

  while (sourceSet.length != 0) {
    Map entry = sourceSet.removeLast();
    entries.add(entry);
    entry["in"].reversed.forEach(handleIn(entry));
    entry["out"].forEach(handleOut(entry));
  }

  return entries.where((entry) => !entry.containsKey("merged") || entry["merged"] == false).map((Map entry) {
    return util.pick(entry, ["vs", "i", "barycenter", "weight"]);
  }).toList();
}

mergeEntries(Map target, Map source) {
  var sum = 0,
      weight = 0;

  if (target.containsKey("weight")) {
    sum += target["barycenter"] * target["weight"];
    weight += target["weight"];
  }

  if (source.containsKey("weight")) {
    sum += source["barycenter"] * source["weight"];
    weight += source["weight"];
  }

  target["vs"] = source["vs"].toList()..addAll(target["vs"]);
  target["barycenter"] = sum / weight;
  target["weight"] = weight;
  target["i"] = Math.min(source["i"], target["i"]);
  source["merged"] = true;
}
