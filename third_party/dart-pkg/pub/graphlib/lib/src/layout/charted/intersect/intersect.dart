library graphlib.layout.charted.intersect;

export "line.dart";
export "polygon.dart";
export "rect.dart";

intersectCircle(node, rx, point) {
  return intersectEllipse(node, rx, rx, point);
}

intersectEllipse(node, rx, ry, point) {
  // Formulae from: http://mathworld.wolfram.com/Ellipse-LineIntersection.html

  var cx = node.x;
  var cy = node.y;

  var px = cx - point.x;
  var py = cy - point.y;

  var det = Math.sqrt(rx * rx * py * py + ry * ry * px * px);

  var dx = Math.abs(rx * ry * px / det);
  if (point.x < cx) {
    dx = -dx;
  }
  var dy = Math.abs(rx * ry * py / det);
  if (point.y < cy) {
    dy = -dy;
  }

  return {x: cx + dx, y: cy + dy};
}

intersectNode(node, point) {
  return node.intersect(point);
}
