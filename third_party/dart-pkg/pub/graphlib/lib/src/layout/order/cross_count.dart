library graphlib.layout.order.cross_count;

import "../../graph.dart" show Graph;
import "../util.dart" show flatten, range;

/// A function that takes a layering (an array of layers, each with an array of
/// ordererd nodes) and a graph and returns a weighted crossing count.
///
/// Pre-conditions:
///
///    1. Input graph must be simple (not a multigraph), directed, and include
///       only simple edges.
///    2. Edges in the input graph must have assigned weights.
///
/// Post-conditions:
///
///    1. The graph and layering matrix are left unchanged.
///
/// This algorithm is derived from Barth, et al., "Bilayer Cross Counting."
int crossCount(Graph g, List layering) {
  var cc = 0;
  for (var i = 1; i < layering.length; ++i) {
    cc += twoLayerCrossCount(g, layering[i-1], layering[i]);
  }
  return cc;
}

int twoLayerCrossCount(Graph g, Iterable northLayer, Iterable southLayer) {
  // Sort all of the edges between the north and south layers by their position
  // in the north layer and then the south. Map these edges to the position of
  // their head in the south layer.
  var southPos = new Map.fromIterables(southLayer, range(southLayer.length));
  var southEntries = flatten(northLayer.map((v) {
    return g.outEdges(v).map((e) {
      return { "pos": southPos[e.w], "weight": g.edgeObj(e)["weight"] };
    }).toList()..sort((Map a, Map b) {
      return a["pos"].compareTo(b["pos"]);
    });
  }));

  // Build the accumulator tree
  var firstIndex = 1;
  while (firstIndex < southLayer.length) firstIndex <<= 1;
  var treeSize = 2 * firstIndex - 1;
  firstIndex -= 1;
  var tree = new List.generate(treeSize, (_) => 0);

  // Calculate the weighted crossings
  var cc = 0;
  /*_.each(*/southEntries.forEach((Map entry) {
    var index = entry["pos"] + firstIndex;
    tree[index] += entry["weight"];
    var weightSum = 0;
    while (index > 0) {
      if (index % 2 != 0) {
        weightSum += tree[index + 1];
      }
      index = (index - 1) >> 1;
      tree[index] += entry["weight"];
    }
    cc += entry["weight"] * weightSum;
  })/*)*/;

  return cc;
}
