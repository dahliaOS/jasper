// Copyright (c) 2016, Hoylen Sue.
// All rights reserved.
// Subject to BSD 3-clause license. See file LICENSE_HOYLEN.
library sync.mutex;

import "dart:async";

import "read_write_mutex.dart";

/// Mutual exclusion.
///
/// Usage:
///
///     m = new Mutex();
///
///     await m.acquire();
///     try {
///       // critical section
///     }
///     finally {
///       m.release();
///     }
///
class Mutex {
  /// Implemented as a ReadWriteMutex that is used only with write locks.
  final ReadWriteMutex _rwMutex = new ReadWriteMutex();

  /// Indicates if a lock has currently been acquired.
  bool get isLocked => (_rwMutex.isLocked);

  /// Acquire a lock
  ///
  /// Returns a future that will be completed when the lock has been acquired.
  ///
  Future acquire() => _rwMutex.acquireWrite();

  /// Release a lock.
  ///
  /// Release a lock that has been acquired.
  ///
  void release() => _rwMutex.release();
}
