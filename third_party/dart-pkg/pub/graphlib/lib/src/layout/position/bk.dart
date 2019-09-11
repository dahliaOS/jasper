library graphlib.layout.position.bk;

import "dart:math" as Math;
import "../../graph.dart" show Graph;
import "../util.dart" as util;

// This module provides coordinate assignment based on Brandes and Köpf, "Fast
// and Simple Horizontal Coordinate Assignment."

/// Marks all edges in the graph with a type-1 conflict with the "type1Conflict"
/// property. A type-1 conflict is one where a non-inner segment crosses an
/// inner segment. An inner segment is an edge with both incident nodes marked
/// with the "dummy" property.
///
/// This algorithm scans layer by layer, starting with the second, for type-1
/// conflicts between the current layer and the previous layer. For each layer
/// it scans the nodes from left to right until it reaches one that is incident
/// on an inner segment. It then scans predecessors to determine if they have
/// edges that cross that inner segment. At the end a final scan is done for all
/// nodes on the current rank to see if they cross the last visited inner
/// segment.
///
/// This algorithm (safely) assumes that a dummy node will only be incident on a
/// single node in the layers being scanned.
Map findType1Conflicts(Graph g, Iterable layering) {
  var conflicts = {};

  visitLayer(Map prevLayer, List layer) {
    var
        // last visited node in the previous layer that is incident on an inner
        // segment.
        k0 = 0,
        // Tracks the last node in this layer scanned for crossings with a type-1
        // segment.
        scanPos = 0,
        prevLayerLength = prevLayer.length,
        lastNode = layer.last;

    int i = 0;
    layer.forEach((v) {
      var w = findOtherInnerSegmentNode(g, v),
          k1 = w ? g.node(w).order : prevLayerLength;

      if (w || v == lastNode) {
        layer.getRange(scanPos, i + 1).forEach((scanNode) {
          g.predecessors(scanNode).forEach((u) {
            var uLabel = g.node(u), uPos = uLabel.order;
            if ((uPos < k0 || k1 < uPos) &&
                !(uLabel["dummy"] && g.node(scanNode)["dummy"])) {
              addConflict(conflicts, u, scanNode);
            }
          });
        });
        scanPos = i + 1;
        k0 = k1;
      }
      i++;
    });

    return layer;
  }

  layering.reduce(visitLayer);
  return conflicts;
}

Map findType2Conflicts(Graph g, Iterable layering) {
  var conflicts = {};

  scan(south, southPos, southEnd, prevNorthBorder, nextNorthBorder) {
    var v;
    util.range(southPos, southEnd).forEach((i) {
      v = south[i];
      if (g.node(v)["dummy"]) {
        g.predecessors(v).forEach((u) {
          Map uNode = g.node(u);
          if (uNode["dummy"] &&
              (uNode["order"] < prevNorthBorder ||
                  uNode["order"] > nextNorthBorder)) {
            addConflict(conflicts, u, v);
          }
        });
      }
    });
  }

  visitLayer(north, south) {
    var prevNorthPos = -1, nextNorthPos, southPos = 0;

    south.forEach((v, southLookahead) {
      if (g.node(v).dummy == "border") {
        var predecessors = g.predecessors(v);
        if (predecessors.length != 0) {
          nextNorthPos = g.node(predecessors[0])["order"];
          scan(south, southPos, southLookahead, prevNorthPos, nextNorthPos);
          southPos = southLookahead;
          prevNorthPos = nextNorthPos;
        }
      }
      scan(south, southPos, south.length, nextNorthPos, north.length);
    });

    return south;
  }

  layering.reduce(visitLayer);
  return conflicts;
}

findOtherInnerSegmentNode(Graph g, v) {
  if (g.node(v)["dummy"]) {
    return g.predecessors(v).firstWhere((u) {
      return g.node(u)["dummy"];
    });
  }
}

addConflict(Map conflicts, v, w) {
  if (v > w) {
    var tmp = v;
    v = w;
    w = tmp;
  }

  var conflictsV = conflicts[v];
  if (!conflictsV) {
    conflicts[v] = conflictsV = {};
  }
  conflictsV[w] = true;
}

bool hasConflict(Map conflicts, v, w) {
  if (v > w) {
    var tmp = v;
    v = w;
    w = tmp;
  }
  return conflicts[v].containsKey(w);
}

/// Try to align nodes into vertical "blocks" where possible. This algorithm
/// attempts to align a node with one of its median neighbors. If the edge
/// connecting a neighbor is a type-1 conflict then we ignore that possibility.
/// If a previous node has already formed a block with a node after the node
/// we're trying to form a block with, we also ignore that possibility - our
/// blocks would be split in that scenario.
Map verticalAlignment(
    Graph g, Iterable layering, Map conflicts, Iterable neighborFn(v)) {
  var root = {}, align = {}, pos = {};

  // We cache the position here based on the layering because the graph and
  // layering may be out of sync. The layering matrix is manipulated to
  // generate different extreme alignments.
  layering.forEach((layer) {
    layer.forEach((v, order) {
      root[v] = v;
      align[v] = v;
      pos[v] = order;
    });
  });

  layering.forEach((layer) {
    var prevIdx = -1;
    layer.forEach((v) {
      var ws = neighborFn(v);
      if (ws.length != 0) {
        ws = ws.sort((w) => pos[w]);
        var mp = (ws.length - 1) / 2;
        for (var i = mp.floor(), il = mp.ceil(); i <= il; ++i) {
          var w = ws[i];
          if (align[v] == v &&
              prevIdx < pos[w] &&
              !hasConflict(conflicts, v, w)) {
            align[w] = v;
            align[v] = root[v] = root[w];
            prevIdx = pos[w];
          }
        }
      }
    });
  });

  return {"root": root, "align": align};
}

Map horizontalCompaction(Graph g, Iterable layering, root, align,
    [bool reverseSep = false]) {
  // We use local variables for these parameters instead of manipulating the
  // graph because it becomes more verbose to access them in a chained manner.
  var shift = {},
      shiftNeighbor = {},
      sink = {},
      xs = {},
      pred = {},
      graphLabel = g.graph(),
      sepFn = sep(graphLabel.nodesep, graphLabel.edgesep, reverseSep);

  layering.forEach((layer) {
    layer.forEach((v, order) {
      sink[v] = v;
      shift[v] = double.infinity;
      pred[v] = layer[order - 1];
    });
  });

  g.nodes.forEach((v) {
    if (root[v] == v) {
      placeBlock(g, layering, sepFn, root, align, shift, shiftNeighbor, sink,
          pred, xs, v);
    }
  });

  layering.forEach((layer) {
    layer.forEach((v) {
      xs[v] = xs[root[v]];
      // This line differs from the source paper. See
      // http://www.inf.uni-konstanz.de/~brandes/publications/ for details.
      if (v == root[v] && shift[sink[root[v]]] < double.infinity) {
        xs[v] += shift[sink[root[v]]];

        // Cascade shifts as necessary
        var w = shiftNeighbor[sink[root[v]]];
        if (w && shift[w] != double.infinity) {
          xs[v] += shift[w];
        }
      }
    });
  });

  return xs;
}

placeBlock(Graph g, layering, Function sepFn, root, align, shift, shiftNeighbor,
    sink, pred, xs, v) {
  if (xs.containsKey(v)) return;
  xs[v] = 0;

  var w = v, u;
  do {
    if (pred[w]) {
      u = root[pred[w]];
      placeBlock(g, layering, sepFn, root, align, shift, shiftNeighbor, sink,
          pred, xs, u);
      if (sink[v] == v) {
        sink[v] = sink[u];
      }

      var delta = sepFn(g, w, pred[w]);
      if (sink[v] != sink[u]) {
        shift[sink[u]] = Math.min(shift[sink[u]], xs[v] - xs[u] - delta);
        shiftNeighbor[sink[u]] = sink[v];
      } else {
        xs[v] = Math.max(xs[v], xs[u] + delta);
      }
    }
    w = align[w];
  } while (w != v);
}

/// Returns the alignment that has the smallest width of the given alignments.
Map findSmallestWidthAlignment(Graph g, Map<String, Map> xss) {
  return util.min(xss.values, (Map xs) {
    var min = util.min(xs.keys, (v) => xs[v] - width(g, v) / 2),
        max = util.max(xs.keys, (v) => xs[v] + width(g, v) / 2);
    return max - min;
  });
}

/// Align the coordinates of each of the layout alignments such that
/// left-biased alignments have their minimum coordinate at the same point as
/// the minimum coordinate of the smallest width alignment and right-biased
/// alignments have their maximum coordinate at the same point as the maximum
/// coordinate of the smallest width alignment.
alignCoordinates(Map<String, Map> xss, Map alignTo) {
  var alignToMin = util.min(alignTo.values),
      alignToMax = util.max(alignTo.values);

  ["u", "d"].forEach((vert) {
    ["l", "r"].forEach((horiz) {
      var alignment = vert + horiz, delta;
      Map xs = xss[alignment];
      if (xs == alignTo) return;

      delta = horiz == "l"
          ? alignToMin - util.min(xs.values)
          : alignToMax - util.max(xs.values);

      if (delta) {
        xss[alignment] = util.mapValues(xs, (x, _) => x + delta);
      }
    });
  });
}

balance(Map<String, Map> xss, [align]) {
  return util.mapValues(xss["ul"], (_, v) {
    if (align != null) {
      return xss[align.toLowerCase()][v];
    } else {
      var xs = util.pluck(xss.values, v)..sort();
      return (xs[1] + xs[2]) / 2;
    }
  });
}

positionX(Graph g) {
  var layering = util.buildLayerMatrix(g);
  var conflicts = util.merge(
      {}, [findType1Conflicts(g, layering), findType2Conflicts(g, layering)]);

  Map<String, Map> xss = {};
  var adjustedLayering;
  ["u", "d"].forEach((vert) {
    adjustedLayering = vert == "u" ? layering : layering.reversed.toList();
    ["l", "r"].forEach((horiz) {
      if (horiz == "r") {
        adjustedLayering = adjustedLayering.map((inner) {
          return inner.values.reverse();
        });
      }

      var neighborFn =
          (v) => (vert == "u" ? g.predecessors(v) : g.successors(v));
      var align = verticalAlignment(g, adjustedLayering, conflicts, neighborFn);
      Map xs = horizontalCompaction(
          g, adjustedLayering, align["root"], align["align"], horiz == "r");
      if (horiz == "r") {
        xs = util.mapValues(xs, (_, x) => -x);
      }
      xss[vert + horiz] = xs;
    });
  });

  var smallestWidth = findSmallestWidthAlignment(g, xss);
  alignCoordinates(xss, smallestWidth);
  return balance(xss, g.graph()["align"]);
}

sep(nodeSep, edgeSep, bool reverseSep) {
  return (Graph g, v, w) {
    Map vLabel = g.node(v), wLabel = g.node(w);
    var sum = 0, delta;

    sum += vLabel["width"] / 2;
    if (vLabel.containsKey("labelpos")) {
      switch (vLabel["labelpos"].toLowerCase()) {
        case "l":
          delta = -vLabel["width"] / 2;
          break;
        case "r":
          delta = vLabel["width"] / 2;
          break;
      }
    }
    if (delta != 0) {
      sum += reverseSep ? delta : -delta;
    }
    delta = 0;

    sum += (vLabel["dummy"] ? edgeSep : nodeSep) / 2;
    sum += (wLabel["dummy"] ? edgeSep : nodeSep) / 2;

    sum += wLabel["width"] / 2;
    if (wLabel.containsKey("labelpos")) {
      switch (wLabel["labelpos"].toLowerCase()) {
        case "l":
          delta = wLabel["width"] / 2;
          break;
        case "r":
          delta = -wLabel["width"] / 2;
          break;
      }
    }
    if (delta != 0) {
      sum += reverseSep ? delta : -delta;
    }
    delta = 0;

    return sum;
  };
}

width(Graph g, v) => g.node(v)["width"];
