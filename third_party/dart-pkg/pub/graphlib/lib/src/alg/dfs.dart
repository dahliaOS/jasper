library graphlib.alg.dfs;

import "../graph.dart";
import "common.dart";

/// A helper that preforms a pre- or post-order traversal on the input graph
/// and returns the nodes in the order they were visited. This algorithm treats
/// the input as undirected.
///
/// Order must be one of "pre" or "post".
List dfs(Graph g, List vs, String order) {
  final acc = [],
      visited = {};
  vs.forEach((v) {
    if (!g.hasNode(v)) {
      throw new AlgorithmException("Graph does not have node: $v");
    }

    _doDfs(g, v, order == "post", visited, acc);
  });
  return acc;
}

_doDfs(Graph g, v, bool postorder, Map visited, List acc) {
  if (!visited.containsKey(v)) {
    visited[v] = true;

    if (!postorder) { acc.add(v); }
    g.neighbors(v).forEach((w) {
      _doDfs(g, w, postorder, visited, acc);
    });
    if (postorder) { acc.add(v); }
  }
}

List preorder(Graph g, List vs) {
  return dfs(g, vs, "pre");
}

List postorder(Graph g, List vs) {
  return dfs(g, vs, "post");
}
