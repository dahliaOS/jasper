library graphlib.layout.util;

import "dart:math" as Math;
import "dart:collection" show SplayTreeMap;
import "../graph.dart" show Graph;

import "lodash.dart";
export "lodash.dart";

//module.exports = {
//  addDummyNode: addDummyNode,
//  simplify: simplify,
//  asNonCompoundGraph: asNonCompoundGraph,
//  successorWeights: successorWeights,
//  predecessorWeights: predecessorWeights,
//  intersectRect: intersectRect,
//  buildLayerMatrix: buildLayerMatrix,
//  normalizeRanks: normalizeRanks,
//  removeEmptyRanks: removeEmptyRanks,
//  addBorderNode: addBorderNode,
//  maxRank: maxRank,
//  partition: partition,
//  time: time,
//  notime: notime
//};

/// Adds a dummy node to the graph and return v.
addDummyNode(Graph g, type, Map attrs, name) {
  var v;
  do {
    v = uniqueId(name);
  } while (g.hasNode(v));

  attrs["dummy"] = type;
  g.setNode(v, attrs);
  return v;
}

/// Returns a new graph with only simple edges. Handles aggregation of data
/// associated with multi-edges.
Graph simplify(Graph g) {
  var simplified = new Graph()..setGraph(g.graph());
  g.nodes.forEach((v) { simplified.setNode(v, g.node(v)); });
  g.edges.forEach((e) {
    Map simpleLabel = simplified.edge(e.v, e.w),
        label = g.edgeObj(e);
    if (simpleLabel == null) {
      simpleLabel = { "weight": 0, "minlen": 1 };
    }
    simplified.setEdge(e.v, e.w, {
      "weight": simpleLabel["weight"] + label["weight"],
      "minlen": Math.max(simpleLabel["minlen"], label["minlen"])
    });
  });
  return simplified;
}

Graph asNonCompoundGraph(Graph g) {
  var simplified = new Graph(multigraph: g.isMultigraph)..setGraph(g.graph());
  g.nodes.forEach((v) {
    if (g.children(v).length == 0) {
      simplified.setNode(v, g.node(v));
    }
  });
  g.edges.forEach((e) {
    simplified.setEdge(e, g.edgeObj(e));
  });
  return simplified;
}

Map successorWeights(Graph g) {
  var weightMap = g.nodes.map((v) {
    var sucs = {};
    g.outEdges(v).forEach((e) {
      if (!sucs.containsKey(e.w)) sucs[e.w] = 0;
      sucs[e.w] = sucs[e.w] + g.edgeObj(e)["weight"];
    });
    return sucs;
  });
  return new Map.fromIterables(g.nodes, weightMap);
}

Map predecessorWeights(Graph g) {
  var weightMap = g.nodes.map((v) {
    var preds = {};
    g.inEdges(v).forEach((e) {
      if (!preds.containsKey(e.v)) preds[e.v] = 0;
      preds[e.v] = preds[e.v] + g.edgeObj(e).weight;
    });
    return preds;
  });
  return new Map.fromIterables(g.nodes, weightMap);
}

/// Finds where a line starting at point ({x, y}) would intersect a rectangle
/// ({x, y, width, height}) if it were pointing at the rectangle's center.
Map intersectRect(Map rect, Map point) {
  var x = rect["x"];
  var y = rect["y"];

  // Rectangle intersection algorithm from:
  // http://math.stackexchange.com/questions/108113/find-edge-between-two-boxes
  var dx = point["x"] - x;
  var dy = point["y"] - y;
  var w = rect["width"] / 2;
  var h = rect["height"] / 2;

  if (dx == 0 && dy == 0) {
    throw new LayoutException("Not possible to find intersection inside of the rectangle");
  }

  var sx, sy;
  if (dy.abs() * w > dx.abs() * h) {
    // Intersection is top or bottom of rect.
    if (dy < 0) {
      h = -h;
    }
    sx = h * dx / dy;
    sy = h;
  } else {
    // Intersection is left or right of rect.
    if (dx < 0) {
      w = -w;
    }
    sx = w;
    sy = w * dy / dx;
  }

  return { "x": x + sx, "y": y + sy };
}

/// Given a DAG with each node assigned "rank" and "order" properties, this
/// function will produce a matrix with the ids of each node.
List buildLayerMatrix(Graph g) {
  var layering = range(maxRank(g) + 1).map((_) => new SplayTreeMap()).toList();
  g.nodes.forEach((v) {
    Map node = g.node(v);
    var rank = node["rank"];
    if (rank != null) {
      layering[rank][node["order"]] = v;
    }
  });
  return layering.map((SplayTreeMap m) => m.values.toList()).toList();
}

/// Adjusts the ranks for all nodes in the graph such that all nodes v have
/// rank(v) >= 0 and at least one node w has rank(w) = 0.
normalizeRanks(Graph g) {
  var minimum = min(g.nodes.map((v) => g.node(v)["rank"]));
  g.nodes.forEach((v) {
    Map node = g.node(v);
    if (node.containsKey("rank")) {
      node["rank"] -= minimum;
    }
  });
}

removeEmptyRanks(Graph g) {
  // Ranks may not start at 0, so we need to offset them
  var offset = min(g.nodes.map((v) => g.node(v).rank));

  var layers = new SplayTreeMap();
  g.nodes.forEach((v) {
    var rank = g.node(v)["rank"] - offset;
    if (!layers.containsKey(rank)) {
      layers[rank] = [];
    }
    layers[rank].add(v);
  });

  var delta = 0,
      nodeRankFactor = g.graph()["nodeRankFactor"],
      i = 0;
  layers.values.forEach((vs) {
    if (vs == null && i % nodeRankFactor != 0) {
      --delta;
    } else if (delta != 0) {
      vs.forEach((v) { g.node(v)["rank"] += delta; });
    }
    i++;
  });
}

addBorderNode(g, prefix, [rank, order]) {
  var node = {
    "width": 0,
    "height": 0
  };
  if (rank != null) {
    node["rank"] = rank;
  }
  if (order != null) {
    node["order"] = order;
  }
  return addDummyNode(g, "border", node, prefix);
}

maxRank(g) {
  return max(g.nodes.map((v) {
    var rank = g.node(v)["rank"];
    if (rank != null) {
      return rank;
    }
  }));
}

/// Partition a collection into two groups: `lhs` and `rhs`. If the supplied
/// function returns true for an entry it goes into `lhs`. Otherwise it goes
/// into `rhs.
Map partition(Iterable collection, Function fn) {
  var result = { "lhs": [], "rhs": [] };
  collection.forEach((value) {
    if (fn(value)) {
      result["lhs"].add(value);
    } else {
      result["rhs"].add(value);
    }
  });
  return result;
}

/// Returns a new function that wraps `fn` with a timer. The wrapper logs the
/// time it takes to execute the function.
time(String name, Function fn, [log(String s) = print]) {
  var start = new DateTime.now().millisecondsSinceEpoch;
  try {
    return fn();
  } finally {
    log("$name time: ${new DateTime.now().millisecondsSinceEpoch - start}ms");
  }
}

notime(String name, Function fn) {
  return fn();
}

class LayoutException implements Exception {
  final String message;
  LayoutException(this.message);
  String toString() => message;
}
