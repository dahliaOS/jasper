// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library observe.src.observable_box;

import 'package:observable/observable.dart';
import 'package:observe/observe.dart';

// TODO(jmesserly): should the property name be configurable?
// That would be more convenient.
/// An observable box that holds a value. Use this if you want to store a single
/// value. For other cases, it is better to use [AutoObservableList],
/// [AutoObservableMap], or a custom [AutoObservable] implementation based on
/// [AutoObservable]. The property name for changes is "value".
class ObservableBox<T> extends PropertyChangeNotifier {
  T _value;

  ObservableBox([T initialValue]) : _value = initialValue;

  @reflectable
  T get value => _value;

  @reflectable
  void set value(T newValue) {
    _value = notifyPropertyChange(#value, _value, newValue);
  }

  String toString() => '#<$runtimeType value: $value>';
}
