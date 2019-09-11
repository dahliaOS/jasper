library graphlib.layout.charted.create_edge_labels;

import 'label/add_label.dart';
import 'util.dart' as util;

createEdgeLabels(selection, g) {
  var svgEdgeLabels = selection.selectAll("g.edgeLabel")
    .data(g.edges(), (e) { return util.edgeToId(e); })
    .classed("update", true);

  svgEdgeLabels.selectAll("*").remove();
  svgEdgeLabels.enter()
    .append("g")
      .classed("edgeLabel", true)
      .style("opacity", 0);
  svgEdgeLabels.each((e) {
    var edge = g.edge(e),
        label = addLabel(d3.select(self), g.edge(e), 0, 0).classed("label", true),
        bbox = label.node().getBBox();

    if (edge.labelId) { label.attr("id", edge.labelId); }
    if (!edge.containsKey("width")) { edge.width = bbox.width; }
    if (!edge.containsKey("height")) { edge.height = bbox.height; }
  });

  util.applyTransition(svgEdgeLabels.exit(), g)
    .style("opacity", 0)
    .remove();

  return svgEdgeLabels;
}
