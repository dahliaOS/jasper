library graphlib.layout.coordinate_system;

import "../graph.dart" show Graph, Edge;

adjust(Graph g) {
  var rankDir = g.graph()["rankdir"].toLowerCase();
  if (rankDir == "lr" || rankDir == "rl") {
    _swapWidthHeight(g);
  }
}

undo(Graph g) {
  var rankDir = g.graph()["rankdir"].toLowerCase();
  if (rankDir == "bt" || rankDir == "rl") {
    _reverseY(g);
  }

  if (rankDir == "lr" || rankDir == "rl") {
    _swapXY(g);
    _swapWidthHeight(g);
  }
}

_swapWidthHeight(Graph g) {
  g.nodes.forEach((v) { _swapWidthHeightOne(g.node(v)); });
  g.edges.forEach((e) { _swapWidthHeightOne(g.edgeObj(e)); });
}

_swapWidthHeightOne(Map attrs) {
  var w = attrs["width"];
  attrs["width"] = attrs["height"];
  attrs["height"] = w;
}

_reverseY(Graph g) {
  g.nodes.forEach((v) { _reverseYOne(g.node(v)); });

  g.edges.forEach((Edge e) {
    var edge = g.edgeObj(e);
    edge["points"].forEach(_reverseYOne);
    if (edge.containsKey("y")) {
      _reverseYOne(edge);
    }
  });
}

_reverseYOne(Map attrs) {
  attrs["y"] = -attrs["y"];
}

_swapXY(Graph g) {
  g.nodes.forEach((v) { _swapXYOne(g.node(v)); });

  g.edges.forEach((Edge e) {
    var edge = g.edgeObj(e);
    edge["points"].forEach(_swapXYOne);
    if (edge.containsKey("x")) {
      _swapXYOne(edge);
    }
  });
}

_swapXYOne(Map attrs) {
  var x = attrs["x"];
  attrs["x"] = attrs["y"];
  attrs["y"] = x;
}
