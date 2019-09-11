library graphlib.layout.acyclic;

import "../graph.dart" show Graph, Edge;
import "greedy_fas.dart" show greedyFAS;
import "util.dart" show uniqueId;

run(Graph g) {
  weightFn(Graph g) {
    return (Edge e) => g.edgeObj(e)["weight"];
  }

  Iterable fas = (g.graph()["acyclicer"] == "greedy"
                ? greedyFAS(g, weightFn(g))
                : dfsFAS(g));
  fas.forEach((Edge e) {
    Map label = g.edgeObj(e);
    g.removeEdgeObj(e);
    label["forwardName"] = e.name;
    label["reversed"] = true;
    g.setEdge(e.w, e.v, label, uniqueId("rev"));
  });
}

List dfsFAS(Graph g) {
  final fas = [],
      stack = {},
      visited = {};

  dfs(v) {
    if (visited.containsKey(v)) {
      return;
    }
    visited[v] = true;
    stack[v] = true;
    g.outEdges(v).forEach((e) {
      if (stack.containsKey(e.w)) {
        fas.add(e);
      } else {
        dfs(e.w);
      }
    });
    stack.remove(v);
  }

  g.nodes.forEach(dfs);
  return fas;
}

undo(Graph g) {
  g.edges.forEach((Edge e) {
    Map label = g.edgeObj(e);
    if (label["reversed"]) {
      g.removeEdgeObj(e);

      var forwardName = label["forwardName"];
      label.remove("reversed");
      label.remove("forwardName");
      g.setEdge(e.w, e.v, label, forwardName);
    }
  });
}
