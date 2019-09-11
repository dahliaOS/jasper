library graphlib.layout.parent_dummy_chains;

import "dart:math" as Math;
import "../graph.dart" show Graph, Edge;

parentDummyChains(Graph g) {
  var postorderNums = postorder(g);

  g.graph()["dummyChains"].forEach((v) {
    Map node = g.node(v);
    Edge edgeObj = node["edgeObj"];
    Map pathData = findPath(g, postorderNums, edgeObj.v, edgeObj.w);
    var path = pathData["path"],
        lca = pathData["lca"],
        pathIdx = 0,
        pathV = path[pathIdx],
        ascending = true;

    while (v != edgeObj.w) {
      node = g.node(v);

      if (ascending) {
        while ((pathV = path[pathIdx]) != lca &&
               g.node(pathV)["maxRank"] < node["rank"]) {
          pathIdx++;
        }

        if (pathV == lca) {
          ascending = false;
        }
      }

      if (!ascending) {
        while (pathIdx < path.length - 1 &&
               g.node(pathV = path[pathIdx + 1]).minRank <= node["rank"]) {
          pathIdx++;
        }
        pathV = path[pathIdx];
      }

      g.setParent(v, pathV);
      v = g.successors(v).first;
    }
  });
}

/// Find a path from v to w through the lowest common ancestor (LCA). Return the
/// full path and the LCA.
Map findPath(Graph g, postorderNums, v, w) {
  var vPath = [],
      wPath = [],
      low = Math.min(postorderNums[v]["low"], postorderNums[w]["low"]),
      lim = Math.max(postorderNums[v]["lim"], postorderNums[w]["lim"]),
      parent,
      lca;

  // Traverse up from v to find the LCA
  parent = v;
  do {
    parent = g.parent(parent);
    vPath.add(parent);
  } while (parent &&
           (postorderNums[parent]["low"] > low || lim > postorderNums[parent]["lim"]));
  lca = parent;

  // Traverse from w to LCA
  parent = w;
  while ((parent = g.parent(parent)) != lca) {
    wPath.add(parent);
  }

  return { "path": vPath.concat(wPath.reverse()), "lca": lca };
}

Map postorder(Graph g) {
  var result = {},
      lim = 0;

  dfs(v) {
    var low = lim;
    g.children(v).forEach(dfs);
    result[v] = { "low": low, "lim": lim++ };
  }
  g.children().forEach(dfs);

  return result;
}
