library graphlib.layout.charted.label.add_html_label;

import "../util.dart" as util;

addHtmlLabel(root, node) {
  var fo = root
    .append("foreignObject")
      .attr("width", "100000");

  var div = fo
    .append("xhtml:div");

  var label = node.label;
  if (label is Function) {
    div.insert(label);
  } else if (label is Map) {
    // Currently we assume this is a DOM object.
    div.insert(() { return label; });
  } else {
    div.html(label);
  }

  util.applyStyle(div, node.labelStyle);
  div.style("display", "inline-block");
  // Fix for firefox
  div.style("white-space", "nowrap");

  // TODO find a better way to get dimensions for foreignObjects...
  var w, h;
  div
    .each(() {
      w = self.clientWidth;
      h = self.clientHeight;
    });

  fo
    .attr("width", w)
    .attr("height", h);

  return fo;
}
