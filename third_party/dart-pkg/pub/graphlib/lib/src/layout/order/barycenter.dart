library graphlib.layout.order.barycenter;

import "../../graph.dart" show Graph;

List<Map> barycenter(Graph g, Iterable movable) {
  return movable.map((v) {
    var inV = g.inEdges(v);
    if (inV.length == 0) {
      return { "v": v };
    } else {
      var result = { "sum": 0, "weight": 0 };
      inV.forEach((e) {
        Map edge = g.edgeObj(e),
            nodeU = g.node(e.v);
        var order = nodeU.containsKey("order") ? nodeU["order"] : 1;
        result["sum"] += (edge["weight"] * order);
        result["weight"] += edge["weight"];
      });

      return {
        "v": v,
        "barycenter": result["sum"] / result["weight"],
        "weight": result["weight"]
      };
    }
  }).toList();
}
