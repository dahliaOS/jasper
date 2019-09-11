library graphlib.layout.charted.render;

import '../../graph.dart' show Graph;

import "create_nodes.dart";
import "create_clusters.dart";
import "create_edge_labels.dart";
import "create_edge_paths.dart";
import "position_nodes.dart";
import "position_edge_labels.dart";
import "shapes.dart";
import "arrows.dart";

render(svg, g) {
  preProcessGraph(g);

  var outputGroup = createOrSelectGroup(svg, "output"),
      clustersGroup = createOrSelectGroup(outputGroup, "clusters"),
      edgePathsGroup = createOrSelectGroup(outputGroup, "edgePaths"),
      edgeLabels = createEdgeLabels(createOrSelectGroup(outputGroup, "edgeLabels"), g),
      nodes = createNodes(createOrSelectGroup(outputGroup, "nodes"), g, shapes);

  layout(g);

  positionNodes(nodes, g);
  positionEdgeLabels(edgeLabels, g);
  createEdgePaths(edgePathsGroup, g, arrows);
  createClusters(clustersGroup, g);

  postProcessGraph(g);
}

const NODE_DEFAULT_ATTRS = const {
  "paddingLeft": 10,
  "paddingRight": 10,
  "paddingTop": 10,
  "paddingBottom": 10,
  "rx": 0,
  "ry": 0,
  "shape": "rect"
};

const EDGE_DEFAULT_ATTRS = const {
  "arrowhead": "normal",
  "lineInterpolate": "linear"
};

preProcessGraph(Graph g) {
  g.nodes.forEach((v) {
    var node = g.node(v);
    if (!node.containsKey("label")) { node.label = v; }

    if (node.containsKey("paddingX")) {
      _.defaults(node, {
        "paddingLeft": node.paddingX,
        "paddingRight": node.paddingX
      });
    }

    if (node.containsKey("paddingY")) {
      _.defaults(node, {
        "paddingTop": node.paddingY,
        "paddingBottom": node.paddingY
      });
    }

    if (node.containsKey("padding")) {
      _.defaults(node, {
        "paddingLeft": node.padding,
        "paddingRight": node.padding,
        "paddingTop": node.padding,
        "paddingBottom": node.padding
      });
    }

    _.defaults(node, NODE_DEFAULT_ATTRS);

    ["paddingLeft", "paddingRight", "paddingTop", "paddingBottom"].forEach((k) {
      node[k] = Number(node[k]);
    });

    // Save dimensions for restore during post-processing
    if (node.containsKey("width")) { node._prevWidth = node.width; }
    if (node.containsKey("height")) { node._prevHeight = node.height; }
  });

  g.edges.forEach((e) {
    var edge = g.edge(e);
    if (!edge.containsKey("label")) { edge.label = ""; }
    _.defaults(edge, EDGE_DEFAULT_ATTRS);
  });
}

postProcessGraph(g) {
  g.nodes.forEach((v) {
    var node = g.node(v);

    // Restore original dimensions
    if (node.containsKey("_prevWidth")) {
      node.width = node._prevWidth;
    } else {
      node.remove("width");
    }

    if (node.containsKey("_prevHeight")) {
      node.height = node._prevHeight;
    } else {
      node.remove("height");
    }

    node.remove("_prevWidth");
    node.remove("_prevHeight");
  });
}

createOrSelectGroup(root, name) {
  var selection = root.select("g." + name);
  if (selection.empty()) {
    selection = root.append("g").attr("class", name);
  }
  return selection;
}
