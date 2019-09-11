library graphlib.alg.dijkstra;

import "../graph.dart";
import "../data/priority_queue.dart";
import "common.dart";

Map<dynamic, Path> dijkstra(Graph g, source,
    [weightFunc weightFn, edgeFunc edgeFn]) {
  return _runDijkstra(
      g,
      source.toString(),
      weightFn == null ? DEFAULT_WEIGHT_FUNC : weightFn,
      edgeFn == null ? (v) => g.outEdges(v) : edgeFn);
}

Map<dynamic, Path> _runDijkstra(
    Graph g, source, weightFunc weightFn, edgeFunc edgeFn) {
  Map<dynamic, Path> results = {};
  final pq = new PriorityQueue();
  var v, vEntry;

  updateNeighbors(Edge edge) {
    final w = edge.v != v ? edge.v : edge.w,
        wEntry = results[w],
        weight = weightFn(edge);
    final distance = (vEntry.distance != null ? vEntry.distance : 0.0) +
        (weight != null ? weight : 0.0);

    if (weight < 0) {
      throw new AlgorithmException(
          "dijkstra does not allow negative edge weights. "
          "Bad edge: $edge Weight: $weight");
    }

    if (wEntry.distance != null && distance < wEntry.distance) {
      wEntry.distance = distance;
      wEntry.predecessor = v;
      pq.decrease(w, distance);
    }
  }

  ;

  g.nodes.forEach((v) {
    var distance = v == source ? 0 : double.infinity;
    results[v] = new Path(distance: distance);
    pq.add(v, distance);
  });

  while (pq.length > 0) {
    v = pq.removeMin();
    vEntry = results[v];
    if (vEntry.distance == double.infinity) {
      break;
    }

    List<Edge> edges = edgeFn(v);
    edges.forEach(updateNeighbors);
  }

  return results;
}

Map<dynamic, Map<dynamic, Path>> dijkstraAll(Graph g,
    [weightFunc weightFn, edgeFunc edgeFn]) {
  var results = {};
  g.nodes.forEach((v) {
    results[v] = dijkstra(g, v, weightFn, edgeFn);
  });
  return results;
}
