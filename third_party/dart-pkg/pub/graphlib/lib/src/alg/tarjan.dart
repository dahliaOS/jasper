library graphlib.alg.tarjan;

import "dart:math" as Math;
import "../graph.dart" show Graph;

List<List> tarjan(Graph g) {
  var index = 0;
  final stack = [],
      visited = {}, // node id -> { onStack, lowlink, index }
      results = [];

  dfs(v) {
    final entry = visited[v] = {
      "onStack": true,
      "lowlink": index,
      "index": index++
    };
    stack.add(v);

    g.successors(v).forEach((w) {
      if (!visited.containsKey(w)) {
        dfs(w);
        entry["lowlink"] = Math.min(entry["lowlink"], visited[w]["lowlink"]);
      } else if (visited[w]["onStack"]) {
        entry["lowlink"] = Math.min(entry["lowlink"], visited[w]["index"]);
      }
    });

    if (entry["lowlink"] == entry["index"]) {
      final cmpt = [];
      var w;
      do {
        w = stack.removeLast();
        visited[w]["onStack"] = false;
        cmpt.add(w);
      } while (v != w);
      results.add(cmpt);
    }
  }

  g.nodes.forEach((v) {
    if (!visited.containsKey(v)) {
      dfs(v);
    }
  });

  return results;
}

List<List> findCycles(Graph g) {
  return tarjan(g).where((cmpt) => cmpt.length > 1).toList();
}
