library graphlib.layout.add_border_segments;

import "../graph.dart" show Graph;
import "util.dart" as util;

addBorderSegments(Graph g) {
  dfs(v) {
    final children = g.children(v);
    Map node = g.node(v);
    if (children.length != 0) {
      children.forEach(dfs);
    }

    if (node.containsKey("minRank")) {
      node["borderLeft"] = [];
      node["borderRight"] = [];
      for (var rank = node["minRank"], maxRank = node["maxRank"] + 1;
           rank < maxRank;
           ++rank) {
        _addBorderNode(g, "borderLeft", "_bl", v, node, rank);
        _addBorderNode(g, "borderRight", "_br", v, node, rank);
      }
    }
  }

  g.children().forEach(dfs);
}

_addBorderNode(Graph g, String prop, String prefix, sg, Map sgNode, rank) {
  var label = { "width": 0, "height": 0, "rank": rank },
      prev = sgNode[prop][rank - 1],
      curr = util.addDummyNode(g, "border", label, prefix);
  sgNode[prop][rank] = curr;
  g.setParent(curr, sg);
  if (prev) {
    g.setEdge(prev, curr, { "weight": 1 });
  }
}
