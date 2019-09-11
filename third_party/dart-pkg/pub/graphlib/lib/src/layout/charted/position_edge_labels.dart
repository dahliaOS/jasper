library graphlib.layout.charted.position_edge_labels;

import 'util.dart' as util;

positionEdgeLabels(selection, g) {
  var created = selection.filter(() { return !d3.select(self).classed("update"); });

  translate(e) {
    var edge = g.edge(e);
    return _.has(edge, "x") ? "translate(" + edge.x + "," + edge.y + ")" : "";
  }

  created.attr("transform", translate);

  util.applyTransition(selection, g)
    .style("opacity", 1)
    .attr("transform", translate);
}
