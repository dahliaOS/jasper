library graphlib.alg.topsort;

import "../graph.dart" show Graph;

List topsort(Graph g) {
  final visited = {},
      stack = {},
      results = [];

  visit(node) {
    if (stack.containsKey(node)) {
      throw new CycleException();
    }

    if (!visited.containsKey(node)) {
      stack[node] = true;
      visited[node] = true;
      g.predecessors(node).forEach(visit);
      stack.remove(node);
      results.add(node);
    }
  }

  g.sinks.forEach(visit);

  if (visited.length != g.nodeCount) {
    throw new CycleException();
  }

  return results;
}

bool isAcyclic(Graph g) {
  try {
    topsort(g);
  } on CycleException catch (e) {
    return false;
  }
  return true;
}

class CycleException implements Exception {
  final String message;
  CycleException([this.message = ""]);
  String toString() => message;
}
