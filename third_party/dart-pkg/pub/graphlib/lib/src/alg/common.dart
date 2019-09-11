library graphlib.alg.common;

import "../graph.dart" show Edge;

final weightFunc DEFAULT_WEIGHT_FUNC = (_) => 1;

typedef num weightFunc(Edge e);
typedef List<Edge> edgeFunc(v);

class AlgorithmException implements Exception {
  final String message;
  AlgorithmException(this.message);
  String toString() => message;
}

class Path<U> {
  num distance;
  U predecessor;
  Path({this.distance: 0.0, this.predecessor});
  bool operator ==(Path other) {
    if (other == null) {
      return false;
    }
    if (distance != other.distance) {
      return false;
    }
    if (predecessor != other.predecessor) {
      return false;
    }
    return true;
  }
}
