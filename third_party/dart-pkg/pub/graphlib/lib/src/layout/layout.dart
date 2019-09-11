library graphlib.layout;

import "dart:math" as Math;
import "acyclic.dart" as acyclic;
import "normalize.dart" as normalize;
import "rank/rank.dart";
import "parent_dummy_chains.dart";
import "util.dart" show removeEmptyRanks, normalizeRanks;
import "nesting_graph.dart" as nestingGraph;
import "add_border_segments.dart";
import "coordinate_system.dart" as coordinateSystem;
import "order/order.dart";
import "position/position.dart";
import "util.dart" as util;
import "../graph.dart" show Graph;

layout(Graph g, [bool debugTiming = false]) {
  var time = debugTiming ? util.time : util.notime;
  time("layout", () {
    var layoutGraph = time("  buildLayoutGraph", () {
      return buildLayoutGraph(g);
    });
    time("  runLayout", () {
      runLayout(layoutGraph, time);
    });
    time("  updateInputGraph", () {
      updateInputGraph(g, layoutGraph);
    });
  });
}

runLayout(Graph g, time) {
  time("    makeSpaceForEdgeLabels", () {
    makeSpaceForEdgeLabels(g);
  });
  time("    removeSelfEdges", () {
    removeSelfEdges(g);
  });
  time("    acyclic", () {
    acyclic.run(g);
  });
  time("    nestingGraph.run", () {
    nestingGraph.run(g);
  });
  time("    rank", () {
    rank(util.asNonCompoundGraph(g));
  });
  time("    injectEdgeLabelProxies", () {
    injectEdgeLabelProxies(g);
  });
  time("    removeEmptyRanks", () {
    removeEmptyRanks(g);
  });
  time("    nestingGraph.cleanup", () {
    nestingGraph.cleanup(g);
  });
  time("    normalizeRanks", () {
    normalizeRanks(g);
  });
  time("    assignRankMinMax", () {
    assignRankMinMax(g);
  });
  time("    removeEdgeLabelProxies", () {
    removeEdgeLabelProxies(g);
  });
  time("    normalize.run", () {
    normalize.run(g);
  });
  time("    parentDummyChains", () {
    parentDummyChains(g);
  });
  time("    addBorderSegments", () {
    addBorderSegments(g);
  });
  time("    order", () {
    order(g);
  });
  time("    insertSelfEdges", () {
    insertSelfEdges(g);
  });
  time("    adjustCoordinateSystem", () {
    coordinateSystem.adjust(g);
  });
  time("    position", () {
    position(g);
  });
  time("    positionSelfEdges", () {
    positionSelfEdges(g);
  });
  time("    removeBorderNodes", () {
    removeBorderNodes(g);
  });
  time("    normalize.undo", () {
    normalize.undo(g);
  });
  time("    fixupEdgeLabelCoords", () {
    fixupEdgeLabelCoords(g);
  });
  time("    undoCoordinateSystem", () {
    coordinateSystem.undo(g);
  });
  time("    translateGraph", () {
    translateGraph(g);
  });
  time("    assignNodeIntersects", () {
    assignNodeIntersects(g);
  });
  time("    reversePoints", () {
    reversePointsForReversedEdges(g);
  });
  time("    acyclic.undo", () {
    acyclic.undo(g);
  });
}

/*
 * Copies final layout information from the layout graph back to the input
 * graph. This process only copies whitelisted attributes from the layout graph
 * to the input graph, so it serves as a good place to determine what
 * attributes can influence layout.
 */
updateInputGraph(Graph inputGraph, Graph layoutGraph) {
  inputGraph.nodes.forEach((v) {
    Map inputLabel = inputGraph.node(v), layoutLabel = layoutGraph.node(v);

    if (inputLabel != null) {
      inputLabel["x"] = layoutLabel["x"];
      inputLabel["y"] = layoutLabel["y"];

      if (layoutGraph.children(v).length != 0) {
        inputLabel["width"] = layoutLabel["width"];
        inputLabel["height"] = layoutLabel["height"];
      }
    }
  });

  inputGraph.edges.forEach((e) {
    Map inputLabel = inputGraph.edgeObj(e),
        layoutLabel = layoutGraph.edgeObj(e);

    inputLabel["points"] = layoutLabel["points"];
    if (layoutLabel.containsKey("x")) {
      inputLabel["x"] = layoutLabel["x"];
      inputLabel["y"] = layoutLabel["y"];
    }
  });

  inputGraph.graph()["width"] = layoutGraph.graph()["width"];
  inputGraph.graph()["height"] = layoutGraph.graph()["height"];
}

const graphNumAttrs = const [
  "nodesep",
  "edgesep",
  "ranksep",
  "marginx",
  "marginy"
],
    graphDefaults = const {
  "ranksep": 50,
  "edgesep": 20,
  "nodesep": 50,
  "rankdir": "tb"
},
    graphAttrs = const ["acyclicer", "ranker", "rankdir", "align"],
    nodeNumAttrs = const ["width", "height"],
    nodeDefaults = const {"width": 0, "height": 0},
    edgeNumAttrs = const ["minlen", "weight", "width", "height", "labeloffset"],
    edgeDefaults = const {
  "minlen": 1,
  "weight": 1,
  "width": 0,
  "height": 0,
  "labeloffset": 10,
  "labelpos": "r"
},
    edgeAttrs = const ["labelpos"];

/// Constructs a new graph from the input graph, which can be used for layout.
/// This process copies only whitelisted attributes from the input graph to the
/// layout graph. Thus this function serves as a good place to determine what
/// attributes can influence layout.
buildLayoutGraph(Graph inputGraph) {
  var g = new Graph(multigraph: true, compound: true),
      graph = canonicalize(inputGraph.graph());

  g.setGraph(util.merge({}, [
    graphDefaults,
    selectNumberAttrs(graph, graphNumAttrs),
    util.pick(graph, graphAttrs)
  ]));

  inputGraph.nodes.forEach((v) {
    var node = canonicalize(inputGraph.node(v));
    g.setNode(
        v, util.defaults(selectNumberAttrs(node, nodeNumAttrs), nodeDefaults));
    g.setParent(v, inputGraph.parent(v));
  });

  inputGraph.edges.forEach((e) {
    var edge = canonicalize(inputGraph.edgeObj(e));
    g.setEdge(
        e,
        util.merge({}, [
          edgeDefaults,
          selectNumberAttrs(edge, edgeNumAttrs),
          util.pick(edge, edgeAttrs)
        ]));
  });

  return g;
}

/// This idea comes from the Gansner paper: to account for edge labels in our
/// layout we split each rank in half by doubling minlen and halving ranksep.
/// Then we can place labels at these mid-points between nodes.
///
/// We also add some minimal padding to the width to push the label for the edge
/// away from the edge itself a bit.
makeSpaceForEdgeLabels(Graph g) {
  var graph = g.graph();
  graph["ranksep"] /= 2;
  g.edges.forEach((e) {
    Map edge = g.edgeObj(e);
    edge["minlen"] *= 2;
    if (edge["labelpos"].toLowerCase() != "c") {
      if (graph["rankdir"] == "TB" || graph["rankdir"] == "BT") {
        edge["width"] += edge["labeloffset"];
      } else {
        edge["height"] += edge["labeloffset"];
      }
    }
  });
}

/// Creates temporary dummy nodes that capture the rank in which each edge's
/// label is going to, if it has one of non-zero width and height. We do this
/// so that we can safely remove empty ranks while preserving balance for the
/// label's position.
injectEdgeLabelProxies(Graph g) {
  g.edges.forEach((e) {
    Map edge = g.edgeObj(e);
    if (edge["width"] && edge["height"]) {
      Map v = g.node(e.v),
          w = g.node(e.w),
          label = {"rank": (w["rank"] - v["rank"]) / 2 + v["rank"], "e": e};
      util.addDummyNode(g, "edge-proxy", label, "_ep");
    }
  });
}

assignRankMinMax(Graph g) {
  var maxRank = 0;
  g.nodes.forEach((v) {
    Map node = g.node(v);
    if (node["borderTop"]) {
      node["minRank"] = g.node(node["borderTop"])["rank"];
      node["maxRank"] = g.node(node["borderBottom"])["rank"];
      maxRank = Math.max(maxRank, node["maxRank"]);
    }
  });
  g.graph()["maxRank"] = maxRank;
}

removeEdgeLabelProxies(Graph g) {
  g.nodes.forEach((v) {
    Map node = g.node(v);
    if (node["dummy"] == "edge-proxy") {
      g.edgeObj(node["e"])["labelRank"] = node["rank"];
      g.removeNode(v);
    }
  });
}

translateGraph(Graph g) {
  var minX = double.infinity,
      maxX = 0,
      minY = double.infinity,
      maxY = 0,
      graphLabel = g.graph(),
      marginX = graphLabel["marginx"],
      marginY = graphLabel["marginy"];
  if (marginX == null) {
    marginX = 0;
  }
  if (marginY == null) {
    marginY = 0;
  }

  getExtremes(Map attrs) {
    var x = attrs["x"], y = attrs["y"], w = attrs["width"], h = attrs["height"];
    minX = Math.min(minX, x - w / 2);
    maxX = Math.max(maxX, x + w / 2);
    minY = Math.min(minY, y - h / 2);
    maxY = Math.max(maxY, y + h / 2);
  }

  g.nodes.forEach((v) {
    getExtremes(g.node(v));
  });
  g.edges.forEach((e) {
    Map edge = g.edgeObj(e);
    if (edge.containsKey("x")) {
      getExtremes(edge);
    }
  });

  minX -= marginX;
  minY -= marginY;

  g.nodes.forEach((v) {
    Map node = g.node(v);
    node["x"] -= minX;
    node["y"] -= minY;
  });

  g.edges.forEach((e) {
    Map edge = g.edgeObj(e);
    edge["points"].forEach((p) {
      p.x -= minX;
      p.y -= minY;
    });
    if (edge.containsKey("x")) {
      edge["x"] -= minX;
    }
    if (edge.containsKey("y")) {
      edge["y"] -= minY;
    }
  });

  graphLabel["width"] = maxX - minX + marginX;
  graphLabel["height"] = maxY - minY + marginY;
}

assignNodeIntersects(Graph g) {
  g.edges.forEach((e) {
    Map edge = g.edgeObj(e), nodeV = g.node(e.v), nodeW = g.node(e.w), p1, p2;
    if (edge["points"] == null) {
      edge["points"] = [];
      p1 = nodeW;
      p2 = nodeV;
    } else {
      p1 = edge["points"][0];
      p2 = edge["points"][edge["points"].length - 1];
    }
    edge["points"].insert(0, util.intersectRect(nodeV, p1));
    edge["points"].add(util.intersectRect(nodeW, p2));
  });
}

fixupEdgeLabelCoords(Graph g) {
  g.edges.forEach((e) {
    Map edge = g.edgeObj(e);
    if (edge.containsKey("x")) {
      if (edge["labelpos"] == "l" || edge["labelpos"] == "r") {
        edge["width"] -= edge["labeloffset"];
      }
      switch (edge["labelpos"]) {
        case "l":
          edge["x"] -= edge["width"] / 2 + edge["labeloffset"];
          break;
        case "r":
          edge["x"] += edge["width"] / 2 + edge["labeloffset"];
          break;
      }
    }
  });
}

reversePointsForReversedEdges(Graph g) {
  g.edges.forEach((e) {
    Map edge = g.edgeObj(e);
    if (edge["reversed"]) {
      edge["points"].reverse();
    }
  });
}

removeBorderNodes(Graph g) {
  g.nodes.forEach((v) {
    if (g.children(v).length != 0) {
      Map node = g.node(v),
          t = g.node(node["borderTop"]),
          b = g.node(node["borderBottom"]),
          l = g.node(node["borderLeft"].last),
          r = g.node(node["borderRight"].last);

      node["width"] = (r["x"] - l["x"]).abs();
      node["height"] = (b["y"] - t["y"]).abs();
      node["x"] = l["x"] + node["width"] / 2;
      node["y"] = t["y"] + node["height"] / 2;
    }
  });

  g.nodes.forEach((v) {
    if (g.node(v)["dummy"] == "border") {
      g.removeNode(v);
    }
  });
}

removeSelfEdges(Graph g) {
  g.edges.forEach((e) {
    if (e.v == e.w) {
      Map node = g.node(e.v);
      if (!node["selfEdges"]) {
        node["selfEdges"] = [];
      }
      node["selfEdges"].add({"e": e, "label": g.edgeObj(e)});
      g.removeEdgeObj(e);
    }
  });
}

insertSelfEdges(Graph g) {
  var layers = util.buildLayerMatrix(g);
  layers.forEach((layer) {
    var orderShift = 0;
    layer.forEach((v, i) {
      Map node = g.node(v);
      node["order"] = i + orderShift;
      node["selfEdges"].forEach((Map selfEdge) {
        util.addDummyNode(
            g,
            "selfedge",
            {
              "width": selfEdge["label"].width,
              "height": selfEdge["label"].height,
              "rank": node["rank"],
              "order": i + (++orderShift),
              "e": selfEdge["e"],
              "label": selfEdge["label"]
            },
            "_se");
      });
      node.remove("selfEdges");
    });
  });
}

positionSelfEdges(Graph g) {
  g.nodes.forEach((v) {
    Map node = g.node(v);
    if (node["dummy"] == "selfedge") {
      Map selfNode = g.node(node["e"].v);
      var x = selfNode["x"] + selfNode["width"] / 2,
          y = selfNode["y"],
          dx = node["x"] - x,
          dy = selfNode["height"] / 2;
      g.setEdge(node["e"], node["label"]);
      g.removeNode(v);
      node["label"]["points"] = [
        {"x": x + 2 * dx / 3, "y": y - dy},
        {"x": x + 5 * dx / 6, "y": y - dy},
        {"x": x + dx, "y": y},
        {"x": x + 5 * dx / 6, "y": y + dy},
        {"x": x + 2 * dx / 3, "y": y + dy},
      ];
      node["label"]["x"] = node["x"];
      node["label"]["y"] = node["y"];
    }
  });
}

Map selectNumberAttrs(Map obj, Iterable attrs) {
  return util.mapValues(util.pick(obj, attrs), (k, v) => num.parse(k));
}

Map canonicalize(Map attrs) {
  var newAttrs = {};
  attrs.forEach((v, k) {
    newAttrs[k.toLowerCase()] = v;
  });
  return newAttrs;
}
