// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library observe.src.bind_property;

import 'dart:async';
import 'package:observable/observable.dart' as obs;

/// Forwards an observable property from one object to another. For example:
///
///     class MyModel extends AutoObservable {
///       StreamSubscription _sub;
///       MyOtherModel _otherModel;
///
///       MyModel() {
///         ...
///         _sub = onPropertyChange(_otherModel, #value,
///             () => notifyPropertyChange(#prop, oldValue, newValue);
///       }
///
///       String get prop => _otherModel.value;
///       set prop(String value) { _otherModel.value = value; }
///     }
///
/// See also [notifyPropertyChange].
// TODO(jmesserly): make this an instance method?
StreamSubscription onPropertyChange(
    obs.Observable source, Symbol sourceName, void callback()) {
  return source.changes.listen((records) {
    for (var record in records) {
      if (record is obs.PropertyChangeRecord && record.name == sourceName) {
        callback();
        break;
      }
    }
  });
}
