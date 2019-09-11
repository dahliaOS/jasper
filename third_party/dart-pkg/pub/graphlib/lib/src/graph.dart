library graphlib.graph;

import 'dart:math' show PI, E;
const undefined = PI * E;

const DEFAULT_EDGE_NAME = "\x00",
    GRAPH_NODE = "\x00",
    EDGE_KEY_DELIM = "\x01";

typedef nodeLabelFn(v);
typedef edgeLabelFn(v, w, name);

// Implementation notes:
//
//  * Node id query functions should return string ids for the nodes
//  * Edge id query functions should return an "edgeObj", edge object, that is
//    composed of enough information to uniquely identify an edge: {v, w, name}.
//  * Internally we use an "edgeId", a stringified form of the edgeObj, to
//    reference edges. This is because we need a performant way to look these
//    edges up and, object properties, which have string keys, are the closest
//    we're going to get to a performant hashtable in JavaScript.

class Graph {
  final bool _isDirected, _isMultigraph, _isCompound;

  // Label for the graph itself
  var _label;

  // Defaults to be set when creating a new node
  nodeLabelFn _defaultNodeLabelFn = (v) => null;

  // Defaults to be set when creating a new edge
  edgeLabelFn _defaultEdgeLabelFn = (v, w, name) => null;

  // v -> label
  final Map _nodes = {};

  // v -> parent
  Map _parent;

  // v -> children
  Map _children;

  // v -> edgeObj
  final Map<dynamic, Map<dynamic, Edge>> _in = {};

  // u -> v -> Number
  final Map _preds = {};

  // v -> edgeObj
  final Map<dynamic, Map<dynamic, Edge>> _out = {};

  // v -> w -> Number
  final Map _sucs = {};

  // e -> edgeObj
  final Map _edgeObjs = {};

  // e -> label
  final Map _edgeLabels = {};

  Graph({bool directed: true, bool multigraph: false, bool compound: false}) :
    _isDirected = directed, _isMultigraph = multigraph, _isCompound = compound {
    if (_isCompound) {
      // v -> parent
      _parent = {};

      // v -> children
      _children = {};
      _children[GRAPH_NODE] = {};
    }
  }

  /* Number of nodes in the graph. Should only be changed by the implementation. */
  int _nodeCount = 0;

  /* Number of edges in the graph. Should only be changed by the implementation. */
  int _edgeCount = 0;


  /* === Graph functions ========= */

  bool get isDirected => _isDirected;

  bool get isMultigraph => _isMultigraph;

  bool get isCompound => _isCompound;

  setGraph(label) {
    _label = label;
  }

  graph() => _label;


  /* === Node functions ========== */

  setDefaultNodeLabel(newDefault) {
    defaultNodeLabelFn = (v) => newDefault;
  }

  void set defaultNodeLabelFn(nodeLabelFn newDefault) {
    _defaultNodeLabelFn = newDefault;
  }

  int get nodeCount => _nodeCount;

  Iterable get nodes => _nodes.keys;

  Iterable get sources {
    return nodes.where((v) {
      return _in[v].isEmpty;
    });
  }

  Iterable get sinks {
    return nodes.where((v) {
      return _out[v].isEmpty;
    });
  }

  setNodes(List vs, [value=undefined]) {
    vs.forEach((v) {
      setNode(v, value);
    });
  }

  setNode(v, [value=undefined]) {
    if (_nodes.containsKey(v)) {
      if (value != undefined) {
        _nodes[v] = value;
      }
      return;
    }

    _nodes[v] = value != undefined ? value : _defaultNodeLabelFn(v);
    if (_isCompound) {
      _parent[v] = GRAPH_NODE;
      _children[v] = {};
      _children[GRAPH_NODE][v] = true;
    }
    _in[v] = {};
    _preds[v] = {};
    _out[v] = {};
    _sucs[v] = {};
    ++_nodeCount;
  }

  node(v) => _nodes[v];

  hasNode(v) => _nodes.containsKey(v);

  removeNode(v) {
    if (_nodes.containsKey(v)) {
      var removeEdge = (e) {
        this.removeEdgeObj(_edgeObjs[e]);
      };
      _nodes.remove(v);
      if (_isCompound) {
        _removeFromParentsChildList(v);
        _parent.remove(v);
        children(v).toList().forEach((child) {
          setParent(child);
        });
        _children.remove(v);
      }
      _in[v].keys.toList().forEach(removeEdge);
      _in.remove(v);
      _preds.remove(v);
      _out[v].keys.toList().forEach(removeEdge);
      _out.remove(v);
      _sucs.remove(v);
      --_nodeCount;
    }
  }

  setParent(v, [parent=null]) {
    if (!_isCompound) {
      throw new GraphException("Cannot set parent in a non-compound graph");
    }

    if (parent == null) {
      parent = GRAPH_NODE;
    } else {
      for (var ancestor = parent; ancestor != null; ancestor = this.parent(ancestor)) {
        if (ancestor == v) {
          throw new GraphException("Setting $parent as parent of $v would create create a cycle");
        }
      }

      setNode(parent);
    }

    setNode(v);
    _removeFromParentsChildList(v);
    _parent[v] = parent;
    _children[parent][v] = true;
  }

  _removeFromParentsChildList(v) => _children[this._parent[v]].remove(v);

  parent(v) {
    if (_isCompound) {
      var parent = _parent[v];
      if (parent != GRAPH_NODE) {
        return parent;
      }
    }
  }

  Iterable children([vv = null]) {
    var v = vv == null ? GRAPH_NODE : vv;
    if (_isCompound) {
      if (_children.containsKey(v)) {
        return _children[v].keys;
      }
    } else if (vv == null) {
      return nodes;
    } else if (hasNode(v)) {
      return [];
    }
    return null;
  }

  Iterable predecessors(v) {
    if (_preds.containsKey(v)) {
      return _preds[v].keys;
    }
    return null;
  }

  Iterable successors(v) {
    if (_sucs.containsKey(v)) {
      return _sucs[v].keys;
    }
    return null;
  }

  neighbors(v) {
    var preds = predecessors(v);
    if (preds != null) {
      return union([preds, successors(v)]);
    }
  }

  /* === Edge functions ========== */

  setDefaultEdgeLabel(newDefault) {
    defaultEdgeLabelFn = (v, w, name) => newDefault;
  }

  void set defaultEdgeLabelFn(edgeLabelFn newDefault) {
    _defaultEdgeLabelFn = newDefault;
  }

  int get edgeCount => _edgeCount;

  Iterable<Edge> get edges => _edgeObjs.values;

  setPath(List vs, [value=undefined]) {
    vs.reduce((v, w) {
      if (value != undefined) {
        setEdge(v, w, value);
      } else {
        setEdge(v, w);
      }
      return w;
    });
  }

  setEdgeObj(Edge edge, [value=undefined]) => setEdge(edge.v, edge.w, value, edge.name);

  setEdge(v, w, [value=undefined, name=null]) {
  //setEdge({ v, w, [name] }, [value])
  //setEdge() {
    var /*v, w, name, value,*/
        valueSpecified = value != undefined;

    v = v.toString();
    w = w.toString();
    if (name != null) {
      name = name.toString();
    }

    var e = edgeArgsToId(_isDirected, v, w, name);
    if (_edgeLabels.containsKey(e)) {
      if (valueSpecified) {
        _edgeLabels[e] = value;
      }
      return;
    }

    if (name != null && !_isMultigraph) {
      throw new GraphException("Cannot set a named edge when isMultigraph = false");
    }

    // It didn't exist, so we need to create it.
    // First ensure the nodes exist.
    setNode(v);
    setNode(w);

    _edgeLabels[e] = valueSpecified ? value : _defaultEdgeLabelFn(v, w, name);

    var edgeObj = edgeArgsToObj(_isDirected, v, w, name);
    // Ensure we add undirected edges in a consistent way.
    v = edgeObj.v;
    w = edgeObj.w;

    //Object.freeze(edgeObj);
    _edgeObjs[e] = edgeObj;
    incrementOrInitEntry(_preds[w], v);
    incrementOrInitEntry(_sucs[v], w);
    _in[w][e] = edgeObj;
    _out[v][e] = edgeObj;
    _edgeCount++;
  }

  edgeObj(Edge edge) {
    return _edgeLabels[edgeObjToId(_isDirected, edge)];
  }

  edge(v, w, [name=null]) {
    return _edgeLabels[edgeArgsToId(_isDirected, v, w, name)];
  }

  bool hasEdgeObj(Edge edge) {
    return _edgeLabels.containsKey(edgeObjToId(_isDirected, edge));
  }

  bool hasEdge(v, w, [name=null]) {
    return _edgeLabels.containsKey(edgeArgsToId(_isDirected, v, w, name));
  }

  removeEdgeObj(Edge edge) {
    _removeEdge(edgeObjToId(_isDirected, edge));
  }

  removeEdge(v, w, [name=null]) {
    _removeEdge(edgeArgsToId(_isDirected, v, w, name));
  }

  _removeEdge(e) {
    if (_edgeObjs.containsKey(e)) {
      var edge = _edgeObjs[e];
      var v = edge.v;
      var w = edge.w;
      _edgeLabels.remove(e);
      _edgeObjs.remove(e);
      decrementOrRemoveEntry(_preds[w], v);
      decrementOrRemoveEntry(_sucs[v], w);
      _in[w].remove(e);
      _out[v].remove(e);
      _edgeCount--;
    }
  }

  Iterable<Edge> inEdges(v, [u=null]) {
    if (_in.containsKey(v)) {
      Map<dynamic, Edge> inV = _in[v];
      Iterable<Edge> edges = inV.values;
      if (u == null) {
        return edges.toList();
      }
      return edges.where((edge) => edge.v == u).toList();
    }
    return null;
  }

  Iterable<Edge> outEdges(v, [w=null]) {
    if (_out.containsKey(v)) {
      Map<dynamic, Edge> outV = _out[v];
      List<Edge> edges = outV.values.toList();
      if (w == null) {
        return new List<Edge>.from(edges);
      }
      return edges.where((Edge edge) => edge.w == w).toList();
    }
    return null;
  }

  Iterable<Edge> nodeEdges(v, [w=null]) {
    var inEdges = this.inEdges(v, w);
    if (inEdges != null) {
      return inEdges.toList()..addAll(outEdges(v, w));
    }
    return null;
  }
}

incrementOrInitEntry(Map map, k) {
  if (map.containsKey(k)) {
    map[k]++;
  } else {
    map[k] = 1;
  }
}

decrementOrRemoveEntry(Map map, k) {
  if (--map[k] == 0) { map.remove(k); }
}

edgeArgsToId(bool isDirected, v, w, [name=null]) {
  if (!isDirected && v.compareTo(w) > 0) {
    var tmp = v;
    v = w;
    w = tmp;
  }
  return v.toString() + EDGE_KEY_DELIM + w.toString() + EDGE_KEY_DELIM +
             (name == null ? DEFAULT_EDGE_NAME : name.toString());
}

Edge edgeArgsToObj(bool isDirected, v, w, [name=null]) {
  if (!isDirected && v.compareTo(w) > 0) {
    var tmp = v;
    v = w;
    w = tmp;
  }
  //var edgeObj =  { v: v, w: w };
  var edgeObj =  new Edge(v, w, name);
  /*if (name != undefined) {
    edgeObj.name = name;
  }*/
  return edgeObj;
}

edgeObjToId(bool isDirected, Edge edgeObj) {
  return edgeArgsToId(isDirected, edgeObj.v, edgeObj.w, edgeObj.name);
}

class Edge {
  final dynamic v, w, name;
  Edge(this.v, this.w, [this.name]);
  bool operator ==(other) {
    if (other == null) {
      return false;
    }
    if (other is! Edge) {
      return false;
    }
    if (other.v != v) {
      return false;
    }
    if (other.w != w) {
      return false;
    }
    if (other.name != name) {
      return false;
    }
    return true;
  }
}

class GraphException implements Exception {
  final String message;
  GraphException(this.message);
  String toString() => message;
}

Iterable union(Iterable<Iterable> sets) {
  var s = new Set();
  for (var ss in sets) {
    s = s.union(ss.toSet());
  }
  return s;
}
