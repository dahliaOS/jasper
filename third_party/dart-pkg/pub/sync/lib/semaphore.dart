library sync.semaphore;

import "dart:async";
import "dart:collection";

/// A Semaphore class.
class Semaphore {
  final int maxCount;

  int _counter = 0;
  Queue<Completer> _waitQueue = new Queue<Completer>();

  Semaphore([this.maxCount = 1]) {
    if (maxCount == null) {
      throw new ArgumentError.notNull("maxCount");
    }
    if (maxCount < 1) {
      throw new RangeError.value(maxCount, "maxCount");
    }
  }

  /// Acquires a permit from this semaphore, asynchronously blocking until one
  /// is available.
  Future acquire() {
    var completer = new Completer();
    if (_counter + 1 <= maxCount) {
      _counter++;
      completer.complete();
    } else {
      _waitQueue.add(completer);
    }
    return completer.future;
  }

  /// Releases a permit, returning it to the semaphore.
  void release() {
    if (_counter == 0) {
      throw new StateError("Unable to release semaphore.");
    }
    _counter--;
    if (_waitQueue.length > 0) {
      _counter++;
      var completer = _waitQueue.removeFirst();
      completer.complete();
    }
  }
}
