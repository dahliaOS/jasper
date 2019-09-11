// Copyright 2016 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:math';

import 'package:lorem/lorem.dart';
import 'package:meta/meta.dart';
import 'package:uuid/uuid.dart';

import 'name.dart';
import 'sequence.dart';

/// The operation was not allowed by the current state of the [Fixtures]
/// instance.
class FixturesError extends StateError {
  /// Create a [FixturesError].
  ///
  ///     FixturesError err = new FixturesError('Something bad happened');
  ///
  FixturesError(String msg) : super(msg);
}

/// Defines generators for objects to be used in UI mocks and tests.
///
/// Generators are, and should be defined as methods of [Fixtures] and return
/// instances of objects that attempt to be random and unique. Uniqueness is
/// only guaranteed up to the set uniqueness [nameThreshold].
///
/// The objects returned from [Fixtures] methods are not Stubs, or Mocks. They
/// are actual instances of their return types.
class Fixtures {
  final Set<String> _names = new Set<String>();
  final Map<String, Sequence> _sequences = new Map<String, Sequence>();

  /// Random number generator to be used by [Fixtures] and other subclasses.
  final Random rng = new Random();

  /// A Lorem Ipsum generator to be used by [Fixtures] and other subclasses.
  final Lorem lorem = new Lorem();

  /// Global [Uuid] generator.
  static final Uuid _uuid = new Uuid();

  /// Uniqueness [nameThreshold].
  ///
  /// Generators like [name] use the [nameThreshold] to limit the total unique
  /// values they produce. When the threshold is reached a [FixturesError]
  /// will be thrown.
  final int nameThreshold;

  /// Create an instance of [Fixtures].
  ///
  ///     Fixtures fixtures = new Fixtures();
  ///
  /// If you need a higher set of unique values from generators (like
  /// [name]) over the default [nameThreshold] it can be optionally set:
  ///
  ///     Fixtures fixtures = new Fixtures(threshold: 5000);
  ///
  Fixtures({this.nameThreshold: 1000});

  /// Gets the global [Uuid] generator.
  ///
  /// Should only be used by this class and sub-classes.
  @protected
  static Uuid get uuid => _uuid;

  /// Retrieve a namespaced [Sequence] value.
  ///
  /// The [int] [Sequence] value returned for the namespace key will be
  /// sequentially increased by one on every call.
  ///
  /// The first time a sequence is called it will return an `int` value of
  ///  `1`.
  ///
  ///     // The sequence value will equal `1`.
  ///     int sequence = fixtures._sequence('email');
  ///
  /// Subsequent calls will return a value that is incremented above the
  /// previously returned value.
  ///
  ///     // The sequence value will equal `2`.
  ///     int sequence = fixtures._sequence('email');
  ///
  @protected
  int sequence(String key) {
    _sequences[key] ??= new Sequence();
    return _sequences[key].value;
  }

  /// Generate a name.
  ///
  /// When called without the optional value, a new random [String] name will
  /// be returned with a [String] value like 'Brenda Wade'.
  ///
  ///     String name = fixtures.name();
  ///
  /// [Fixtures] instances track subsequent calls to [name] to guarantee
  /// unique random [Name] values, even against ones that have an explicitly
  /// set value. Additional calls for explicit names will not be counted
  /// against the [nameThreshold] after the first time.
  ///
  /// Track a [String] name with the value 'Jason Campbell'.
  ///
  ///     String jason = fixtures.name('Jason Campbell');
  ///
  /// Generate a random name. The random name will never have the value 'Jason
  /// Campbell'.
  ///
  ///     String name = fixtures.name();
  ///
  /// Throws [FixturesError] if the [nameThreshold] for unique names is met.
  String name([String value]) {
    if (_names.contains(value)) {
      return value;
    }

    if (_names.length == nameThreshold) {
      String message = 'Threshold for Names exceeded, $nameThreshold unique'
          'names have been generated.';
      throw new FixturesError(message);
    }

    if (value != null) {
      _names.add(value);
    } else {
      value = Name.generate();

      while (!_names.add(value)) {
        value = Name.generate();
      }
    }

    return value;
  }

  /// Genrate a random [int] no greater than [max].
  int number([int max]) {
    return rng.nextInt(max);
  }

  /// [DateTime] for now.
  DateTime now() {
    return new DateTime.now();
  }

  /// Miliseconds since the epoch.
  int timestamp() {
    return now().millisecondsSinceEpoch;
  }

  /// Generates sequenced String ids based on key.
  ///
  ///     // The id value will be 'foo-1'
  ///     String id = fixtures.id('foo');
  ///
  String id(String key) {
    int seq = sequence(key);
    return '$key-$seq';
  }
}
