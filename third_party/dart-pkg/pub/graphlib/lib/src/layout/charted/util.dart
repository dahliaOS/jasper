library graphlib.layout.charted.util;

/// Returns true if the specified node in the graph is a subgraph node. A
/// subgraph node is one that contains other nodes.
isSubgraph(g, v) {
  return !!g.children(v).length;
}

edgeToId(e) {
  return escapeId(e.v) + ":" + escapeId(e.w) + ":" + escapeId(e.name);
}

final ID_DELIM = ":";

escapeId(str) {
  return str ? str.toString().replaceAll(ID_DELIM, "\\:") : "";
}

applyStyle(dom, styleFn) {
  if (styleFn) {
    dom.attr("style", styleFn);
  }
}

applyClass(dom, classFn, otherClasses) {
  if (classFn) {
    dom
      .attr("class", classFn)
      .attr("class", otherClasses + " " + dom.attr("class"));
  }
}

applyTransition(selection, g) {
  var graph = g.graph();

  if (graph is Map) {
    var transition = graph["transition"];
    if (transition is Function) {
      return transition(selection);
    }
  }

  return selection;
}
