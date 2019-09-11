library graphlib.layout.charted.shapes;

import "dart:math" as Math;
import "intersect/intersect.dart";

rect(parent, bbox, node) {
  var shapeSvg = parent.insert("rect", ":first-child")
        .attr("rx", node.rx)
        .attr("ry", node.ry)
        .attr("x", -bbox.width / 2)
        .attr("y", -bbox.height / 2)
        .attr("width", bbox.width)
        .attr("height", bbox.height);

  node.intersect = (point) {
    return intersectRect(node, point);
  };

  return shapeSvg;
}

ellipse(parent, bbox, node) {
  var rx = bbox.width / 2,
      ry = bbox.height / 2,
      shapeSvg = parent.insert("ellipse", ":first-child")
        .attr("x", -bbox.width / 2)
        .attr("y", -bbox.height / 2)
        .attr("rx", rx)
        .attr("ry", ry);

  node.intersect = (point) {
    return intersectEllipse(node, rx, ry, point);
  };

  return shapeSvg;
}

circle(parent, bbox, node) {
  var r = Math.max(bbox.width, bbox.height) / 2,
      shapeSvg = parent.insert("circle", ":first-child")
        .attr("x", -bbox.width / 2)
        .attr("y", -bbox.height / 2)
        .attr("r", r);

  node.intersect = (point) {
    return intersectCircle(node, r, point);
  };

  return shapeSvg;
}
