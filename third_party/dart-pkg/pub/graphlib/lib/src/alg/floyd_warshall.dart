library graphlib.alg.floyd_warshall;

import "../graph.dart";
import "common.dart";

Map<dynamic, Map<dynamic, Path>> floydWarshall(Graph g,
    [weightFunc weightFn, edgeFunc edgeFn]) {
  return _runFloydWarshall(g, weightFn == null ? DEFAULT_WEIGHT_FUNC : weightFn,
      edgeFn == null ? (v) => g.outEdges(v) : edgeFn);
}

Map _runFloydWarshall(Graph g, weightFunc weightFn, edgeFunc edgeFn) {
  Map<dynamic, Map<dynamic, Path>> results = {};
  final nodes = g.nodes;

  nodes.forEach((v) {
    results[v] = {};
    results[v][v] = new Path(distance: 0);
    nodes.forEach((w) {
      if (v != w) {
        results[v][w] = new Path(distance: double.infinity);
      }
    });
    edgeFn(v).forEach((Edge edge) {
      var w = edge.v == v ? edge.w : edge.v, d = weightFn(edge);
      results[v][w] = new Path(distance: d, predecessor: v);
    });
  });

  nodes.forEach((k) {
    var rowK = results[k];
    nodes.forEach((i) {
      var rowI = results[i];
      nodes.forEach((j) {
        var ik = rowI[k];
        var kj = rowK[j];
        var ij = rowI[j];
        var altDistance = ik.distance + kj.distance;
        if (altDistance < ij.distance) {
          ij.distance = altDistance;
          ij.predecessor = kj.predecessor;
        }
      });
    });
  });

  return results;
}
