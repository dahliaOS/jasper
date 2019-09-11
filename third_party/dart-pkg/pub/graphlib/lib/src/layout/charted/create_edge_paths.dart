library graphlib.layout.charted.create_edge_paths;

import 'intersect/intersect.dart';
import 'util.dart' as util;

createEdgePaths(selection, g, arrows) {
  var svgPaths = selection.selectAll("g.edgePath")
    .data(g.edges(), (e) { return util.edgeToId(e); })
    .classed("update", true);

  enter(svgPaths, g);
  exit(svgPaths, g);

  util.applyTransition(svgPaths, g)
    .style("opacity", 1);

  svgPaths.selectAll("path.path")
    .each((e) {
      var edge = g.edge(e);
      edge.arrowheadId = _.uniqueId("arrowhead");

      var domEdge = d3.select(self)
        .attr("marker-end", () {
          return "url(#" + edge.arrowheadId + ")";
        })
        .style("fill", "none");

      util.applyTransition(domEdge, g)
        .attr("d", (e) { return calcPoints(g, e); });

      if (edge.id) { domEdge.attr("id", edge.id); }
      util.applyStyle(domEdge, edge.style);
    });

  svgPaths.selectAll("defs *").remove();
  svgPaths.selectAll("defs")
    .each((e) {
      var edge = g.edge(e),
          arrowhead = arrows[edge.arrowhead];
      arrowhead(d3.select(self), edge.arrowheadId, edge, "arrowhead");
    });

  return svgPaths;
}

calcPoints(g, e) {
  var edge = g.edge(e),
      tail = g.node(e.v),
      head = g.node(e.w),
      points = edge.points.slice(1, edge.points.length - 1);
  points.unshift(intersectNode(tail, points[0]));
  points.push(intersectNode(head, points[points.length - 1]));

  return createLine(edge, points);
}

createLine(edge, points) {
  var line = d3.svg.line()
    .x((d) { return d.x; })
    .y((d) { return d.y; });

  if (_.has(edge, "lineInterpolate")) {
    line.interpolate(edge.lineInterpolate);
  }

  if (_.has(edge, "lineTension")) {
    line.tension(Number(edge.lineTension));
  }

  return line(points);
}

getCoords(elem) {
  var bbox = elem.getBBox(),
      matrix = elem.getTransformToElement(elem.ownerSVGElement)
        .translate(bbox.width / 2, bbox.height / 2);
  return { "x": matrix.e, "y": matrix.f };
}

enter(svgPaths, g) {
  var svgPathsEnter = svgPaths.enter()
    .append("g")
      .attr("class", "edgePath")
      .style("opacity", 0);
  svgPathsEnter.append("path")
    .attr("class", "path")
    .attr("d", (e) {
      var edge = g.edge(e),
          sourceElem = g.node(e.v).elem,
          points = _.range(edge.points.length).map(() { return getCoords(sourceElem); });
      return createLine(edge, points);
    });
  svgPathsEnter.append("defs");
}

exit(svgPaths, g) {
  var svgPathExit = svgPaths.exit();
  util.applyTransition(svgPathExit, g)
    .style("opacity", 0)
    .remove();

  util.applyTransition(svgPathExit.select("path.path"), g)
    .attr("d", (e) {
      var source = g.node(e.v);

      if (source) {
        var points = _.range(self.pathSegList.length).map(() { return source; });
        return createLine({}, points);
      } else {
        return d3.select(self).attr("d");
      }
    });
}
