library graphlib.layout.order.sort_subgraph;

import "../../graph.dart" show Graph;
import "../util.dart" as util;
import "barycenter.dart" show barycenter;
import "resolve_conflicts.dart" show resolveConflicts;
import "sort.dart" show sort;

Map sortSubgraph(Graph g, v, Graph cg, [bool biasRight=false]) {
  var movable = g.children(v),
      node = g.node(v),
      bl = node != null ? node["borderLeft"] : null,
      br = node != null ? node["borderRight"]: null,
      subgraphs = {};

  if (bl != null) {
    movable = movable.where((w) {
      return w != bl && w != br;
    });
  }

  var barycenters = barycenter(g, movable);
  barycenters.forEach((Map entry) {
    if (g.children(entry["v"]).length != 0) {
      var subgraphResult = sortSubgraph(g, entry["v"], cg, biasRight);
      subgraphs[entry["v"]] = subgraphResult;
      if (subgraphResult.containsKey("barycenter")) {
        mergeBarycenters(entry, subgraphResult);
      }
    }
  });

  var entries = resolveConflicts(barycenters, cg);
  expandSubgraphs(entries, subgraphs);

  var result = sort(entries, biasRight);

  if (bl != null) {
    result["vs"] = util.flatten([bl, result["vs"], br]);
    if (g.predecessors(bl).length != 0) {
      Map blPred = g.node(g.predecessors(bl).first),
          brPred = g.node(g.predecessors(br).first);
      if (!result.containsKey("barycenter")) {
        result["barycenter"] = 0;
        result["weight"] = 0;
      }
      result["barycenter"] = (result["barycenter"] * result["weight"] +
                           blPred["order"] + brPred["order"]) / (result["weight"] + 2);
      result["weight"] += 2;
    }
  }

  return result;
}

expandSubgraphs(Iterable<Map> entries, subgraphs) {
  entries.forEach((entry) {
    entry["vs"] = util.flatten(entry["vs"].map((v) {
      if (subgraphs[v] != null) {
        return subgraphs[v]["vs"];
      }
      return v;
    }));
  });
}

mergeBarycenters(Map target, Map other) {
  if (target["barycenter"] != null) {
    target["barycenter"] = (target["barycenter"] * target["weight"] +
                         other["barycenter"] * other["weight"]) /
                        (target["weight"] + other["weight"]);
    target["weight"] += other["weight"];
  } else {
    target["barycenter"] = other["barycenter"];
    target["weight"] = other["weight"];
  }
}
