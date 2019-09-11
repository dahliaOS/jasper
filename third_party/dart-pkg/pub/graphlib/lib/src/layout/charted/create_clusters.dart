library graphlib.layout.charted.create_clusters;

import 'util.dart' as util;

createClusters(selection, g) {
  var clusters = g.nodes().filter((v) { return util.isSubgraph(g, v); }),
      svgClusters = selection.selectAll("g.cluster")
        .data(clusters, (v) { return v; });

  svgClusters.enter()
    .append("g")
      .attr("class", "cluster")
      .style("opacity", 0)
      .append("rect");
  util.applyTransition(svgClusters.exit(), g)
    .style("opacity", 0)
    .remove();

  util.applyTransition(svgClusters, g)
    .style("opacity", 1);

  util.applyTransition(svgClusters.selectAll("rect"), g)
    .attr("width", (v) { return g.node(v).width; })
    .attr("height", (v) { return g.node(v).height; })
    .attr("x", (v) {
      var node = g.node(v);
      return node.x - node.width / 2;
    })
    .attr("y", (v) {
      var node = g.node(v);
      return node.y - node.height / 2;
    });
}
