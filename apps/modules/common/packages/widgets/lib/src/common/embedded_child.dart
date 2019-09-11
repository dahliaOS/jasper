// Copyright 2016 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/widgets.dart';
import 'package:meta/meta.dart';

/// A widget build function that returns a child of the specific type.
typedef EmbeddedChild EmbeddedChildBuilder(dynamic args);

/// Dispose method for an embedded child view.
typedef void EmbeddedChildDisposer();

/// A function which accepts an EmbeddedChild. Passed as a callback to a
/// GeneralEmbeddedChildBuilder.
typedef void EmbeddedChildAdder(EmbeddedChild child);

/// A widget build function that creates an embedded child and passes it
/// to childAdder.
typedef void GeneralEmbeddedChildBuilder({
  String contract,
  dynamic initialData,
  EmbeddedChildAdder childAdder,
});

/// A class representing an embedded child view.
///
/// An instance of [EmbeddedChild] can be obtained by calling
/// `buildEmbeddedChild()` method of the global [EmbeddedChildProvider] object.
/// There are a couple of important things to note when using this class.
///
/// 1. Since it can be very expensive to embed a new child view, it is important
/// to create this object as few times as possible and reuse the same object
/// whenever possible.
///
/// 2. It is important to call the [dispose] method when the [EmbeddedChild]
/// object is no longer in use.
///
/// A good way to satisfy these two constraints is to embed this in a [State]
/// object of a [StatefulWidget]. The [EmbeddedChild] should be created in
/// `initState()` method and then the reference should be kept as a field in the
/// `State` class. The [EmbeddedChild]'s [dispose] method should be called in
/// the overriden `dispose()` method.
///
///     class FooState extends State<Foo> {
///         EmbeddedChild child;
///
///         @override
///         void initState() {
///             super.initState();
///             child = kEmbeddedChildProvider.buildEmbeddedChild(
///               'child-type',
///               'some-arguments',
///             );
///         }
///
///         @override
///         void dispose() {
///             child.dispose();
///             super.dispose();
///         }
///
///         @override
///         Widget build(BuildContext context) {
///             return new Container(
///               child: child.widgetBuilder(context),
///             );
///         }
///     }
///
class EmbeddedChild {
  /// Creates a new [EmbeddedChild] object.
  EmbeddedChild({
    @required WidgetBuilder widgetBuilder,
    EmbeddedChildDisposer disposer,
    this.additionalData,
  })
      : _widgetBuilder = widgetBuilder,
        _disposer = disposer {
    assert(widgetBuilder != null);
  }

  /// [WidgetBuilder] which the embedding module should use to create the actual
  /// widget.
  WidgetBuilder get widgetBuilder => _widgetBuilder;
  WidgetBuilder _widgetBuilder;

  /// Disposer to be used to clean up the created child widget.
  EmbeddedChildDisposer _disposer;

  /// Reserved for keeping more extra references.
  dynamic additionalData;

  /// Dispose the widget.
  void dispose() {
    _disposer?.call();

    // The disposed embedded child should never be reused.
    _disposer = null;
    _widgetBuilder = null;
  }
}

/// A utility class for providing a generic way of creating and embedding a
/// child view.
///
/// The specific embedded child builders should be added from application level.
/// If this is used in a flutter app, the builders should return regular flutter
/// widgets of the desired type. If used in modular framework, the builders
/// should instantiate a new sub-module and return a ChildView off of it.
class EmbeddedChildProvider {
  final Map<String, EmbeddedChildBuilder> _builders =
      <String, EmbeddedChildBuilder>{};

  GeneralEmbeddedChildBuilder _generalBuilder;

  /// Adds a new [EmbeddedChildBuilder].
  ///
  /// Each application should add necessary [EmbeddedChildBuilder]s somewhere
  /// near the application entry point, such as in the main function.
  void addEmbeddedChildBuilder(
    String type,
    EmbeddedChildBuilder builder,
  ) {
    assert(type != null);
    assert(builder != null);

    _builders[type] = builder;
  }

  /// Build a new instance of [EmbeddedChild].
  ///
  /// The `dispose()` method of the returned [EmbeddedChild] must be called when
  /// the child is no longer in use.
  EmbeddedChild buildEmbeddedChild(
    @required String type,
    dynamic args,
  ) {
    assert(type != null);

    EmbeddedChildBuilder builder = _builders[type];
    if (builder == null) {
      throw new Exception('EmbeddedChildBuilder of type "$type" not found!');
    }

    return builder(args);
  }

  /// Sets the [GeneralEmbeddedChildBuilder].
  ///
  /// [builder] will be called by [buildGeneralEmbeddedChild].
  void setGeneralEmbeddedChildBuilder(GeneralEmbeddedChildBuilder builder) {
    _generalBuilder = builder;
  }

  /// Buils a new instance of [EmbeddedChild].
  ///
  /// The `dispose()` method of the returned [EmbeddedChild] must be called when
  /// the child is no longer in use.
  void buildGeneralEmbeddedChild({
    String contract,
    dynamic initialData,
    EmbeddedChildAdder childAdder,
  }) {
    _generalBuilder(
      contract: contract,
      initialData: initialData,
      childAdder: childAdder,
    );
  }
}

/// Globally accessible [EmbeddedChildProvider].
///
/// Each application (or module) should register all the available
/// [EmbeddedChildBuilder]s within that application's scope to this object.
EmbeddedChildProvider kEmbeddedChildProvider = new EmbeddedChildProvider();
