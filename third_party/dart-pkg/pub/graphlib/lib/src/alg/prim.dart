library graphlib.alg.prim;

import "../data/priority_queue.dart" show PriorityQueue;
import "../graph.dart" show Graph, Edge;
import "common.dart";

Graph prim(Graph g, weightFunc weightFn) {
  final result = new Graph(), parents = {}, pq = new PriorityQueue();
  var v;

  updateNeighbors(Edge edge) {
    var w = edge.v == v ? edge.w : edge.v, pri = pq.priority(w);
    if (pri != null) {
      var edgeWeight = weightFn(edge);
      if (edgeWeight < pri) {
        parents[w] = v;
        pq.decrease(w, edgeWeight);
      }
    }
  }

  if (g.nodeCount == 0) {
    return result;
  }

  g.nodes.forEach((v) {
    pq.add(v, double.infinity);
    result.setNode(v);
  });

  // Start from an arbitrary node
  pq.decrease(g.nodes.first, 0);

  bool init = false;
  while (pq.length > 0) {
    v = pq.removeMin();
    if (parents.containsKey(v)) {
      result.setEdge(v, parents[v]);
    } else if (init) {
      throw new AlgorithmException("Input graph is not connected: $g");
    } else {
      init = true;
    }

    g.nodeEdges(v).forEach(updateNeighbors);
  }

  return result;
}
