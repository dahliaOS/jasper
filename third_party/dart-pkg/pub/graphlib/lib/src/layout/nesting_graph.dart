library graphlib.layout.nesting_graph;

import "../graph.dart" show Graph;
import "util.dart" as util;

/// A nesting graph creates dummy nodes for the tops and bottoms of subgraphs,
/// adds appropriate edges to ensure that all cluster nodes are placed between
/// these boundries, and ensures that the graph is connected.
///
/// In addition we ensure, through the use of the minlen property, that nodes
/// and subgraph border nodes to not end up on the same rank.
///
/// Preconditions:
///
///    1. Input graph is a DAG
///    2. Nodes in the input graph has a minlen attribute
///
/// Postconditions:
///
///    1. Input graph is connected.
///    2. Dummy nodes are added for the tops and bottoms of subgraphs.
///    3. The minlen attribute for nodes is adjusted to ensure nodes do not
///       get placed on the same rank as subgraph border nodes.
///
/// The nesting graph idea comes from Sander, "Layout of Compound Directed
/// Graphs."
run(Graph g) {
  var root = util.addDummyNode(g, "root", {}, "_root"),
      depths = treeDepths(g);
  var height = util.max(depths.values) - 1,
      nodeSep = 2 * height + 1;

  g.graph().nestingRoot = root;

  // Multiply minlen by nodeSep to align nodes on non-border ranks.
  g.edges.forEach((e) { g.edgeObj(e)["minlen"] *= nodeSep; });

  // Calculate a weight that is sufficient to keep subgraphs vertically compact
  var weight = sumWeights(g) + 1;

  // Create border nodes and link them up
  g.children().forEach((child) {
    dfs(g, root, nodeSep, weight, height, depths, child);
  });

  // Save the multiplier for node layers for later removal of empty border
  // layers.
  g.graph()["nodeRankFactor"] = nodeSep;
}

dfs(Graph g, root, num nodeSep, num weight, num height, Map depths, v) {
  var children = g.children(v);
  if (children.length == 0) {
    if (v != root) {
      g.setEdge(root, v, { "weight": 0, "minlen": nodeSep });
    }
    return;
  }

  var top = util.addBorderNode(g, "_bt"),
      bottom = util.addBorderNode(g, "_bb"),
      label = g.node(v);

  g.setParent(top, v);
  label.borderTop = top;
  g.setParent(bottom, v);
  label.borderBottom = bottom;

  children.forEach((child) {
    dfs(g, root, nodeSep, weight, height, depths, child);

    var childNode = g.node(child),
        childTop = childNode.borderTop ? childNode.borderTop : child,
        childBottom = childNode.borderBottom ? childNode.borderBottom : child,
        thisWeight = childNode.borderTop ? weight : 2 * weight,
        minlen = childTop != childBottom ? 1 : height - depths[v] + 1;

    g.setEdge(top, childTop, {
      "weight": thisWeight,
      "minlen": minlen,
      "nestingEdge": true
    });

    g.setEdge(childBottom, bottom, {
      "weight": thisWeight,
      "minlen": minlen,
      "nestingEdge": true
    });
  });

  if (g.parent(v) == null) {
    g.setEdge(root, top, { "weight": 0, "minlen": height + depths[v] });
  }
}

Map treeDepths(Graph g) {
  var depths = {};
  dfs(v, depth) {
    var children = g.children(v);
    if (children != null && children.length != 0) {
      children.forEach((child) {
        dfs(child, depth + 1);
      });
    }
    depths[v] = depth;
  }
  g.children().forEach((v) { dfs(v, 1); });
  return depths;
}

num sumWeights(Graph g) {
  num acc = 0;
  g.edges.forEach((e) {
    return acc + g.edgeObj(e)["weight"];
  });
  return acc;
}

cleanup(Graph g) {
  Map graphLabel = g.graph();
  g.removeNode(graphLabel["nestingRoot"]);
  graphLabel.remove("nestingRoot");
  g.edges.forEach((e) {
    Map edge = g.edgeObj(e);
    if (edge["nestingEdge"]) {
      g.removeEdgeObj(e);
    }
  });
}
