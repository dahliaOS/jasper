library graphlib.data.priority_queue;

/// A min-priority queue data structure. This algorithm is derived from Cormen,
/// et al., "Introduction to Algorithms". The basic idea of a min-priority
/// queue is that you can efficiently (in O(1) time) get the smallest key in
/// the queue. Adding and removing elements takes O(log n) time. A key can
/// have its priority decreased in O(log n) time.
class PriorityQueue<T> {
  List<Map<String, dynamic>> _arr = [];
  Map<T, int> _keyIndices = {};

  /// Returns the number of elements in the queue. Takes `O(1)` time.
  int get length => _arr.length;

  /// Returns the keys that are in the queue. Takes `O(n)` time.
  List<T> get keys => _arr.map((Map x) => x['key']).toList();

  /// Returns `true` if [key] is in the queue and `false` if not.
  bool has(T key) => _keyIndices.containsKey(key);

  /// Returns the priority for [key]. If [key] is not present in the queue
  /// then this function returns `null`. Takes `O(1)` time.
  num priority(T key) {
    if (_keyIndices.containsKey(key)) {
      var index = _keyIndices[key];
      return _arr[index]['priority'];
    }
    return null;
  }

  /// Returns the key for the minimum element in this queue. If the queue is
  /// empty this function throws a [PriorityQueueException]. Takes `O(1)` time.
  T min() {
    if (length == 0) {
      throw new PriorityQueueException("Queue underflow");
    }
    return this._arr[0]['key'];
  }

  /// Inserts a new key into the priority queue. If the key already exists in
  /// the queue this function returns `false`; otherwise it will return `true`.
  /// Takes `O(n)` time.
  bool add(T key, num priority) {
    if (!_keyIndices.containsKey(key)) {
      final index = _arr.length;
      _keyIndices[key] = index;
      _arr.add({'key': key, 'priority': priority});
      _decrease(index);
      return true;
    }
    return false;
  }

  /// Removes and returns the smallest key in the queue. Takes `O(log n)` time.
  T removeMin() {
    _swap(0, _arr.length - 1);
    final min = _arr.removeLast();
    _keyIndices.remove(min['key']);
    _heapify(0);
    return min['key'];
  }

  /// Decreases the priority for [key] to [priority]. If the new priority is
  /// greater than the previous priority, this function will throw a [PriorityQueueException].
  void decrease(T key, num priority) {
    final index = _keyIndices[key];
    if (priority > _arr[index]['priority']) {
      throw new PriorityQueueException("New priority is greater than current priority. " +
          "Key: $key Old: ${_arr[index]['priority']} New: $priority");
    }
    _arr[index]['priority'] = priority;
    _decrease(index);
  }

  void _heapify(int i) {
    int l = 2 * i,
        r = l + 1,
        largest = i;
    if (l < _arr.length) {
      largest = _arr[l]['priority'] < _arr[largest]['priority'] ? l : largest;
      if (r < _arr.length) {
        largest = _arr[r]['priority'] < _arr[largest]['priority'] ? r : largest;
      }
      if (largest != i) {
        _swap(i, largest);
        _heapify(largest);
      }
    }
  }

  void _decrease(int index) {
    num priority = _arr[index]['priority'];
    while (index != 0) {
      final parent = index >> 1;
      if (_arr[parent]['priority'] < priority) {
        break;
      }
      _swap(index, parent);
      index = parent;
    }
  }

  void _swap(int i, int j) {
    var origArrI = _arr[i];
    var origArrJ = _arr[j];
    _arr[i] = origArrJ;
    _arr[j] = origArrI;
    _keyIndices[origArrJ['key']] = i;
    _keyIndices[origArrI['key']] = j;
  }
}

class PriorityQueueException implements Exception {
  final String message;
  PriorityQueueException(this.message);
  String toString() => message;
}
