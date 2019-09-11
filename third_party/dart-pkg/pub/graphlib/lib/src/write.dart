library graphlib.write;

import 'graph.dart';

final UNESCAPED_ID_PATTERN = new RegExp(r"^[a-zA-Z\200-\377_][a-zA-Z\200-\377_0-9]*$");

String writeDot(Graph g) {
  var ec = g.isDirected ? "->" : "--";
  var writer = new _Writer();

  if (!g.isMultigraph) {
    writer.write("strict ");
  }

  writer.writeLine((g.isDirected ? "digraph" : "graph") + " {");
  writer.indent();

  var graphAttrs = g.graph();
  if (graphAttrs is Map) {
    graphAttrs.forEach((v, k) {
      writer.writeLine("${id(k)}=${id(v)};");
    });
  }

  _writeSubgraph(g, null, writer);

  g.edges.forEach((edge) {
    _writeEdge(g, edge, ec, writer);
  });

  writer.unindent();
  writer.writeLine("}");

  return writer.toString();
}

void _writeSubgraph(Graph g, v, _Writer writer) {
  var children = g.isCompound ? g.children(v) : g.nodes;
  children.forEach((w) {
    if (!g.isCompound || g.children(w).isEmpty) {
      _writeNode(g, w, writer);
    } else {
      writer.writeLine("subgraph " + id(w) + " {");
      writer.indent();

      if (g.node(w) is Map) {
        g.node(w).forEach((val, key) {
          writer.writeLine("${id(key)}=${id(val)};");
        });
      }

      _writeSubgraph(g, w, writer);
      writer.unindent();
      writer.writeLine("}");
    }
  });
}

_writeNode(Graph g, v, _Writer writer) {
  writer.write(id(v));
  _writeAttrs(g.node(v), writer);
  writer.writeLine();
}

void _writeEdge(Graph g, edge, String ec, _Writer writer) {
  var v = edge.v,
      w = edge.w,
      attrs = g.edgeObj(edge);

  writer.write("${id(v)} $ec ${id(w)}");
  _writeAttrs(attrs, writer);
  writer.writeLine();
}

void _writeAttrs(attrs, _Writer writer) {
  if (attrs is Map) {
    var attrStrs = attrs.keys.map((key) {
      return "${id(key)}=${id(attrs[key])}";
    });
    if (attrStrs.isNotEmpty) {
      writer.write(" [" + attrStrs.join(",") + "]");
    }
  }
}

id(obj) {
  if (obj is num || UNESCAPED_ID_PATTERN.hasMatch(obj.toString())) {
    return obj;
  }

  return "\"" + obj.toString().replaceAll("\"", "\\\"") + "\"";
}

// Helper object for making a pretty printer.
class _Writer {
  String _indent, _content;
  bool _shouldIndent;

  _Writer() {
    _indent = "";
    _content = "";
    _shouldIndent = true;
  }

  static final INDENT = "  ";

  void indent() {
    _indent += INDENT;
  }

  void unindent() {
    _indent = _indent.substring(INDENT.length);
  }

  void writeLine([String line = '']) {
    write(line + "\n");
    _shouldIndent = true;
  }

  void write(String str) {
    if (_shouldIndent) {
      _shouldIndent = false;
      _content += _indent;
    }
    _content += str;
  }

  String toString() => _content;
}
