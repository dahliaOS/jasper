library graphlib.layout.order.init_order;

import "../../graph.dart" show Graph;
import "../util.dart" show min, max, range;

/// Assigns an initial order value for each node by performing a DFS search
/// starting from nodes in the first rank. Nodes are assigned an order in their
/// rank as they are first visited.
///
/// This approach comes from Gansner, et al., "A Technique for Drawing Directed
/// Graphs."
///
/// Returns a layering matrix with an array per layer and each layer sorted by
/// the order of its nodes.
List<List> initOrder(Graph g) {
  var visited = {},
      simpleNodes = g.nodes.where((v) {
        return g.children(v).length == 0;
      }).toList();
  var maxRank = max(simpleNodes.map((v) {
    var rank = g.node(v)["rank"];
    return rank;
  }));
  var layers = range(maxRank + 1).map((_) => []).toList();

  dfs(v) {
    if (visited.containsKey(v)) return;
    visited[v] = true;
    var node = g.node(v);
    layers[node["rank"]].add(v);
    g.successors(v).forEach(dfs);
  }

  var orderedVs = simpleNodes..sort((a, b) {
    return g.node(a)["rank"].compareTo(g.node(b)["rank"]);
  });
  orderedVs.forEach(dfs);

  return layers;
}
