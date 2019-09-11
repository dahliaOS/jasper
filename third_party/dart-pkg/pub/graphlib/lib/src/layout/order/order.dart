library graphlib.layout.order;

import "init_order.dart" show initOrder;
import "cross_count.dart" show crossCount;
import "sort_subgraph.dart" show sortSubgraph;
import "build_layer_graph.dart" show buildLayerGraph;
import "add_subgraph_constraints.dart" show addSubgraphConstraints;
import "../../graph.dart" show Graph;
import "../util.dart" as util;

/// Applies heuristics to minimize edge crossings in the graph and sets the best
/// order solution as an order attribute on each node.
///
/// Pre-conditions:
///
///    1. Graph must be DAG
///    2. Graph nodes must be objects with a "rank" attribute
///    3. Graph edges must have the "weight" attribute
///
/// Post-conditions:
///
///    1. Graph nodes will have an "order" attribute based on the results of the
///       algorithm.
order(Graph g) {
  var maxRank = util.maxRank(g),
      downLayerGraphs =
          _buildLayerGraphs(g, util.range(1, maxRank + 1), "inEdges"),
      upLayerGraphs =
          _buildLayerGraphs(g, util.range(maxRank - 1, -1, -1), "outEdges");

  var layering = initOrder(g);
  _assignOrder(g, layering);

  var bestCC = double.infinity;
  List<List> best;

  for (var i = 0, lastBest = 0; lastBest < 4; ++i, ++lastBest) {
    _sweepLayerGraphs(i % 2 != 0 ? downLayerGraphs : upLayerGraphs, i % 4 >= 2);

    layering = util.buildLayerMatrix(g);
    var cc = crossCount(g, layering);
    if (cc < bestCC) {
      lastBest = 0;
      //best = _.cloneDeep(layering);
      best =
          new List<List>.generate(layering.length, (i) => layering[i].toList());
      bestCC = cc;
    }
  }

  _assignOrder(g, best);
}

Iterable _buildLayerGraphs(Graph g, Iterable ranks, relationship) {
  return ranks.map((rank) {
    return buildLayerGraph(g, rank, relationship);
  });
}

_sweepLayerGraphs(Iterable layerGraphs, biasRight) {
  var cg = new Graph();
  layerGraphs.forEach((lg) {
    var root = lg.graph()["root"];
    var sorted = sortSubgraph(lg, root, cg, biasRight);
    int i = 0;
    sorted["vs"].forEach((v) {
      lg.node(v)["order"] = i;
      i++;
    });
    addSubgraphConstraints(lg, cg, sorted["vs"]);
  });
}

_assignOrder(Graph g, List<List> layering) {
  layering.forEach((layer) {
    int i = 0;
    layer.forEach((v) {
      g.node(v)["order"] = i++;
    });
  });
}
