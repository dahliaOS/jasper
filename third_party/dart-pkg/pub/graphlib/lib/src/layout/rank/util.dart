library graphlib.layout.rank.util;

import "../../graph.dart" show Graph, Edge;
import "../util.dart" show min;

/// Initializes ranks for the input graph using the longest path algorithm. This
/// algorithm scales well and is fast in practice, it yields rather poor
/// solutions. Nodes are pushed to the lowest layer possible, leaving the bottom
/// ranks wide and leaving edges longer than necessary. However, due to its
/// speed, this algorithm is good for getting an initial ranking that can be fed
/// into other algorithms.
///
/// This algorithm does not normalize layers because it will be used by other
/// algorithms in most cases. If using this algorithm directly, be sure to
/// run normalize at the end.
///
/// Pre-conditions:
///
///    1. Input graph is a DAG.
///    2. Input graph node labels can be assigned properties.
///
/// Post-conditions:
///
///    1. Each node will be assign an (unnormalized) "rank" property.
longestPath(Graph g) {
  var visited = {};

  dfs(v) {
    Map label = g.node(v);
    if (visited.containsKey(v)) {
      return label["rank"];
    }
    visited[v] = true;

    var rank = min(g.outEdges(v).map((e) {
      return dfs(e.w) - g.edgeObj(e)["minlen"];
    }));

    if (rank == double.infinity) {
      rank = 0;
    }

    return (label["rank"] = rank);
  }

  g.sources.forEach(dfs);
}

/// Returns the amount of slack for the given edge. The slack is defined as the
/// difference between the length of the edge and its minimum length.
num slack(Graph g, Edge e) {
  return g.node(e.w)["rank"] - g.node(e.v)["rank"] - g.edgeObj(e)["minlen"];
}
