// Copyright (c) 2016, Hoylen Sue.
// All rights reserved.
// Subject to BSD 3-clause license. See file LICENSE_HOYLEN.
library sync.read_write_mutex;

import "dart:async";
import "dart:collection";

/// Represents a request for a lock.
///
/// This is instantiated for each acquire and, if necessary, it is added
/// to the waiting queue.
///
class _ReadWriteMutexRequest {
  final bool isRead; // true = read lock requested; false = write lock requested

  final Completer completer = new Completer();

  _ReadWriteMutexRequest(this.isRead);
}

/// Mutual exclusion that supports read and write locks.
///
/// Multiple read locks can be simultaneously acquired, but at most only
/// one write lock can be acquired at any one time.
///
/// Create the mutex:
///
///     m = new ReadWriteMutex();
///
/// Some code can acquire a write lock:
///
///     await m.acquireWrite();
///     try {
///       // critical write section
///       assert(m.isWriteLocked);
///     }
///     finally {
///       m.release();
///     }
///
/// Other code can acquire a read lock.
///
///     await m.acquireRead();
///     try {
///       // critical read section
///       assert(m.isReadLocked);
///     }
///     finally {
///       m.release();
///     }
///
/// The current implementation lets locks be acquired in first-in-first-out
/// order. This ensures there will not be any lock starvation, which can
/// happen if some locks are prioritised over others. Submit a feature
/// request issue, if there is a need for another scheduling algorithm.
///
class ReadWriteMutex {
  final Queue<_ReadWriteMutexRequest> _waiting =
      new Queue<_ReadWriteMutexRequest>();

  int _state = 0; // -1 = write lock, +ve = number of read locks; 0 = no lock

  /// Indicates if a lock (read or write) has currently been acquired.
  bool get isLocked => (_state != 0);

  /// Indicates if a write lock has currently been acquired.
  bool get isWriteLocked => (_state == -1);

  /// Indicates if a read lock has currently been acquired.
  bool get isReadLocked => (0 < _state);

  /// Acquire a read lock
  ///
  /// Returns a future that will be completed when the lock has been acquired.
  Future acquireRead() => _acquire(true);

  /// Acquire a write lock
  ///
  /// Returns a future that will be completed when the lock has been acquired.
  Future acquireWrite() => _acquire(false);

  /// Release a lock.
  ///
  /// Release a lock that has been acquired.
  void release() {
    if (_state == -1) {
      // Write lock released
      _state = 0;
    } else if (0 < _state) {
      // Read lock released
      _state--;
    } else if (_state == 0) {
      throw new StateError("no lock to release");
    } else {
      assert(false);
    }

    // Let all jobs that can now acquire a lock do so.

    while (_waiting.isNotEmpty) {
      var nextJob = _waiting.first;
      if (_jobAcquired(nextJob)) {
        _waiting.removeFirst();
      } else {
        break; // no more can be acquired
      }
    }
  }

  /// Internal acquire method.
  ///
  Future _acquire(bool isRead) {
    var newJob = new _ReadWriteMutexRequest(isRead);
    if (!_jobAcquired(newJob)) {
      _waiting.add(newJob);
    }
    return newJob.completer.future;
  }

  /// Determine if the [job] can now acquire the lock.
  ///
  /// If it can acquire the lock, the job's completer is completed, the
  /// state updated, and true is returned. If not, false is returned.
  ///
  bool _jobAcquired(_ReadWriteMutexRequest job) {
    assert(-1 <= _state);
    if (_state == 0 || (0 < _state && job.isRead)) {
      // Can acquire
      _state = (job.isRead) ? (_state + 1) : -1;
      job.completer.complete();
      return true;
    } else {
      return false;
    }
  }
}
