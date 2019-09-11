// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// *Warning*: this library is **internal**, and APIs are subject to change.
///
/// Tracks observable objects for dirty checking and testing purposes.
///
/// It can collect all observed objects, which can be used to trigger
/// predictable delivery of all pending changes in a test, including objects
/// allocated internally to another library, such as those in
/// `package:template_binding`.
library observe.src.dirty_check;

import 'dart:async';

import 'package:func/func.dart';
import 'package:logging/logging.dart';
import 'package:observable/observable.dart' as obs show Observable;

import 'auto_observable.dart' show AutoObservable;

/// The number of active observables in the system.
int get allObservablesCount => _allObservablesCount;

int _allObservablesCount = 0;

List<obs.Observable> _allObservables = null;

bool _delivering = false;

void registerObservable(obs.Observable obj) {
  if (_allObservables == null) _allObservables = <obs.Observable>[];
  _allObservables.add(obj);
  _allObservablesCount++;
}

/// Synchronously deliver all change records for known observables.
///
/// This will execute [AutoObservable.deliverChanges] on objects that inherit from
/// [AutoObservable].
// Note: this is called performMicrotaskCheckpoint in change_summary.js.
void dirtyCheckObservables() {
  if (_delivering) return;
  if (_allObservables == null) return;

  _delivering = true;

  int cycles = 0;
  bool anyChanged = false;
  List debugLoop = null;
  do {
    cycles++;
    if (cycles == MAX_DIRTY_CHECK_CYCLES) {
      debugLoop = [];
    }

    var toCheck = _allObservables;
    _allObservables = <obs.Observable>[];
    anyChanged = false;

    for (int i = 0; i < toCheck.length; i++) {
      final observer = toCheck[i];
      if (observer.hasObservers) {
        if (observer.deliverChanges()) {
          anyChanged = true;
          if (debugLoop != null) debugLoop.add([i, observer]);
        }
        _allObservables.add(observer);
      }
    }
  } while (cycles < MAX_DIRTY_CHECK_CYCLES && anyChanged);

  if (debugLoop != null && anyChanged) {
    _logger.warning('Possible loop in AutoObservable.dirtyCheck, stopped '
        'checking.');
    for (final info in debugLoop) {
      _logger.warning('In last iteration AutoObservable changed at index '
          '${info[0]}, object: ${info[1]}.');
    }
  }

  _allObservablesCount = _allObservables.length;
  _delivering = false;
}

const MAX_DIRTY_CHECK_CYCLES = 1000;

/// Log for messages produced at runtime by this library. Logging can be
/// configured by accessing Logger.root from the logging library.
final Logger _logger = new Logger('AutoObservable.dirtyCheck');

/// Creates a [ZoneSpecification] to set up automatic dirty checking after each
/// batch of async operations. This ensures that change notifications are always
/// delivered. Typically used via [dirtyCheckZone].
ZoneSpecification dirtyCheckZoneSpec() {
  bool pending = false;

  enqueueDirtyCheck(ZoneDelegate parent, Zone zone) {
    // Only schedule one dirty check per microtask.
    if (pending) return;

    pending = true;
    parent.scheduleMicrotask(zone, () {
      pending = false;
      AutoObservable.dirtyCheck();
    });
  }

  Func0 wrapCallback(Zone self, ZoneDelegate parent, Zone zone, f()) {
    // TODO(jmesserly): why does this happen?
    if (f == null) return f;
    return () {
      enqueueDirtyCheck(parent, zone);
      return f();
    };
  }

  Func1 wrapUnaryCallback(Zone self, ZoneDelegate parent, Zone zone, f(x)) {
    // TODO(jmesserly): why does this happen?
    if (f == null) return f;
    return (x) {
      enqueueDirtyCheck(parent, zone);
      return f(x);
    };
  }

  return new ZoneSpecification(
      registerCallback: wrapCallback, registerUnaryCallback: wrapUnaryCallback);
}

/// Forks a [Zone] off the current one that does dirty-checking automatically
/// after each batch of async operations. Equivalent to:
///
///     Zone.current.fork(specification: dirtyCheckZoneSpec());
Zone dirtyCheckZone() => Zone.current.fork(specification: dirtyCheckZoneSpec());
