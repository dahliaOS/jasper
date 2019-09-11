library graphlib.layout.position;

import "../util.dart" as util;
import "../../graph.dart" show Graph;
import "bk.dart" show positionX;

position(Graph g) {
  g = util.asNonCompoundGraph(g);

  _positionY(g);
  positionX(g).forEach((x, v) {
    g.node(v)["x"] = x;
  });
}

_positionY(Graph g) {
  var layering = util.buildLayerMatrix(g),
      rankSep = g.graph()["ranksep"],
      prevY = 0;
  layering.forEach((layer) {
    var maxHeight = util.max(layer.map((v) => g.node(v)["height"]));
    layer.forEach((v) {
      g.node(v)["y"] = prevY + maxHeight / 2;
    });
    prevY += maxHeight + rankSep;
  });
}
