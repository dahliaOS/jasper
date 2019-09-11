library graphlib.layout.charted.position_nodes;

import 'util.dart' as util;

positionNodes(selection, g) {
  var created = selection.filter(() { return !d3.select(self).classed("update"); });

  translate(v) {
    var node = g.node(v);
    return "translate(" + node.x + "," + node.y + ")";
  }

  created.attr("transform", translate);

  util.applyTransition(selection, g)
    .style("opacity", 1)
    .attr("transform", translate);
}
