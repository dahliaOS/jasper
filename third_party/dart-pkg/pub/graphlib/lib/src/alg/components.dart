library graphlib.alg.components;

import "../graph.dart";

List<List> components(Graph g) {
  List<List> cmpts = [];
  final visited = {};
  List cmpt;

  dfs(v) {
    if (visited.containsKey(v)) return;
    visited[v] = true;
    cmpt.add(v);
    g.successors(v).forEach(dfs);
    g.predecessors(v).forEach(dfs);
  }

  g.nodes.forEach((v) {
    cmpt = [];
    dfs(v);
    if (cmpt.length != 0) {
      cmpts.add(cmpt);
    }
  });

  return cmpts;
}
