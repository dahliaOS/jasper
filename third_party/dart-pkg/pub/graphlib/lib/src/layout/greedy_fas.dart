library graphlib.layout.greedy_fas;

import "dart:math" as Math;
import "dart:collection" show Queue;
import "../graph.dart" show Graph;
import "../alg/common.dart" show weightFunc;
import "util.dart" show flatten, range;

/// A greedy heuristic for finding a feedback arc set for a graph. A feedback
/// arc set is a set of edges that can be removed to make a graph acyclic.
/// The algorithm comes from: P. Eades, X. Lin, and W. F. Smyth, "A fast and
/// effective heuristic for the feedback arc set problem." This implementation
/// adjusts that from the paper to allow for weighted edges.

var DEFAULT_WEIGHT_FN = () => 1;

List greedyFAS(Graph g, [weightFunc weightFn]) {
  if (g.nodeCount <= 1) {
    return [];
  }
  var state = buildState(g, weightFn == null ? DEFAULT_WEIGHT_FN : weightFn);
  var results = _doGreedyFAS(state["graph"], state["buckets"], state["zeroIdx"]);

  // Expand multi-edges
  return results.map((e) => flatten(g.outEdges(e.v, e.w)));
}

_doGreedyFAS(Graph g, List<Queue> buckets, int zeroIdx) {
  var results = [],
      sources = buckets[buckets.length - 1],
      sinks = buckets[0];

  var entry;
  while (g.nodeCount != 0) {
    while ((entry = sinks.removeLast()))   { removeNode(g, buckets, zeroIdx, entry); }
    while ((entry = sources.removeLast())) { removeNode(g, buckets, zeroIdx, entry); }
    if (g.nodeCount != 0) {
      for (var i = buckets.length - 2; i > 0; --i) {
        entry = buckets[i].removeLast();
        if (entry) {
          results.addAll(removeNode(g, buckets, zeroIdx, entry, true));
          break;
        }
      }
    }
  }

  return results;
}

List removeNode(Graph g, List<Queue> buckets, int zeroIdx, entry, [collectPredecessors=false]) {
  var results = collectPredecessors ? [] : null;

  g.inEdges(entry.v).forEach((edge) {
    var weight = g.edgeObj(edge),
        uEntry = g.node(edge.v);

    if (collectPredecessors) {
      results.add({ "v": edge.v, "w": edge.w });
    }

    uEntry.out -= weight;
    assignBucket(buckets, zeroIdx, uEntry);
  });

  g.outEdges(entry.v).forEach((edge) {
    var weight = g.edgeObj(edge),
        w = edge.w,
        wEntry = g.node(w);
    wEntry["in"] -= weight;
    assignBucket(buckets, zeroIdx, wEntry);
  });

  g.removeNode(entry.v);

  return results;
}

Map buildState(Graph g, weightFn) {
  var fasGraph = new Graph(),
      maxIn = 0,
      maxOut = 0;

  g.nodes.forEach((v) {
    fasGraph.setNode(v, { "v": v, "in": 0, "out": 0 });
  });

  // Aggregate weights on nodes, but also sum the weights across multi-edges
  // into a single edge for the fasGraph.
  g.edges.forEach((e) {
    var prevWeight = fasGraph.edge(e.v, e.w);
    if (prevWeight == null) {
      prevWeight = 0;
    }
    var weight = weightFn(e),
        edgeWeight = prevWeight + weight;
    fasGraph.setEdge(e.v, e.w, edgeWeight);
    maxOut = Math.max(maxOut, fasGraph.node(e.v)["out"] += weight);
    maxIn  = Math.max(maxIn,  fasGraph.node(e.w)["in"]  += weight);
  });

  var buckets = range(maxOut + maxIn + 3).map((_) => new Queue());
  var zeroIdx = maxIn + 1;

  fasGraph.nodes.forEach((v) {
    assignBucket(buckets, zeroIdx, fasGraph.node(v));
  });

  return { "graph": fasGraph, "buckets": buckets, "zeroIdx": zeroIdx };
}

assignBucket(List<Queue> buckets, zeroIdx, entry) {
  if (!entry.out) {
    buckets[0].add(entry);
  } else if (!entry["in"]) {
    buckets[buckets.length - 1].add(entry);
  } else {
    buckets[entry.out - entry["in"] + zeroIdx].add(entry);
  }
}
