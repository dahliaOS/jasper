// Copyright 2018 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:lib.widgets/model.dart';

import 'module_model.dart';

/// The home page of this mod.
class HomePage extends StatelessWidget {
  /// Creates a new instance of [HomePage] widget.
  const HomePage({Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return new Material(
      child: new ScopedModelDescendant<__ProjectName__ModuleModel>(
        // ScopedModelDescendant is a widget which refreshes upon model data
        // changes. The type parameter specifies a model class that is held in a
        // ScopedModel widget higher up in the widget tree. In this example, the
        // ModuleWidget internally creates the ScopedModel which holds the
        // ModuleModel instance. Whenever the model calls notifyListeners(),
        // this ScopedModelDescendant widget refreshes by invoking the builder
        // below.
        //
        // The builder provides the model instance as a parameter, so that you
        // can access any values from the model when building the UI.
        builder: (
          BuildContext context,
          Widget child,
          __ProjectName__ModuleModel model,
        ) {
          return new Scaffold(
            body: new Center(
              child: new Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  const Text(
                    'You have pushed the button this many times:',
                  ),
                  new Text(
                    // The model's data is being accessed here and displayed in
                    // the UI.
                    '${model.counter}',
                    style: Theme.of(context).textTheme.display1,
                  ),
                ],
              ),
            ),
            floatingActionButton: new FloatingActionButton(
              // This calls the incrementCounter() method on the model to update
              // the counter value.
              onPressed: model.incrementCounter,
              tooltip: 'Increment',
              child: new Icon(Icons.add),
            ),
          );
        },
      ),
    );
  }
}
