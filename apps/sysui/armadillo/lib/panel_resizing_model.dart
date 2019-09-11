// Copyright 2017 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/widgets.dart';
import 'package:lib.widgets/model.dart';
import 'package:sysui_widgets/rk4_spring_simulation.dart';

import 'panel.dart';
import 'ticking_model.dart';

export 'package:lib.widgets/model.dart'
    show ScopedModel, Model, ScopedModelDescendant;

const RK4SpringDescription _kSimulationDesc =
    const RK4SpringDescription(tension: 750.0, friction: 50.0);

/// The side of the panel that's being resized.
enum Side {
  /// The left side of the panel.
  left,

  /// The right side of the panel.
  right,

  /// The top of the panel.
  top,

  /// The bottom of the panel.
  bottom,
}

/// The state of a panel resize that's ongoing due to a user initiated drag.
class ResizingState {
  /// The simulation used to increase the margin between panels adjacent to the
  /// seam being dragged.
  final RK4SpringSimulation simulation = new RK4SpringSimulation(
    initValue: 0.0,
    desc: _kSimulationDesc,
  );

  /// This map defines what [Side]s of what [Panel]s will have their margins be
  /// resized based on the value of [simulation].
  final Map<Side, List<Panel>> sideToPanelsMap;

  /// The current drag delta of the panel being resized.
  double dragDelta = 0.0;

  /// The X or Y value of the seam being dragged when dragging began.
  double valueOnDrag = 0.0;

  /// Constructor.
  ResizingState(this.sideToPanelsMap);
}

/// Tracks panel resizing state, notifying listeners when it changes.
/// Using an [PanelResizingModel] allows the panel resizing state it tracks to
/// be passed down the widget tree using a [ScopedModel].
class PanelResizingModel extends TickingModel {
  final Set<ResizingState> _states = new Set<ResizingState>();

  /// Wraps [ModelFinder.of] for this [Model]. See [ModelFinder.of] for more
  /// details.
  static PanelResizingModel of(BuildContext context) =>
      new ModelFinder<PanelResizingModel>().of(context);

  /// Adds a new resizing [state] to be tracked by this model.
  void resizeBegin(ResizingState state) {
    _states.add(state);
    state.simulation.target = 1.0;
    startTicking();
  }

  /// Indicates the existing resizing [state] has ended.
  void resizeEnd(ResizingState state) {
    state.simulation.target = 0.0;
    startTicking();
  }

  /// Gets progress of the margin increase due to resizing on [panel]'s left
  /// side.
  double getLeftProgress(Panel panel) => _getProgress(panel, Side.left);

  /// Gets progress of the margin increase due to resizing on [panel]'s right
  /// side.
  double getRightProgress(Panel panel) => _getProgress(panel, Side.right);

  /// Gets progress of the margin increase due to resizing on [panel]'s top
  /// side.
  double getTopProgress(Panel panel) => _getProgress(panel, Side.top);

  /// Gets progress of the margin increase due to resizing on [panel]'s bottom
  /// side.
  double getBottomProgress(Panel panel) => _getProgress(panel, Side.bottom);

  /// Retrieves any existing resizing state for [sideToPanelsMap].
  ResizingState getState(Map<Side, List<Panel>> sideToPanelsMap) {
    List<ResizingState> statesForMap = _states
        .where(
          (ResizingState state) => _areEqual(
                sideToPanelsMap,
                state.sideToPanelsMap,
              ),
        )
        .toList();
    assert(statesForMap.length <= 1);
    return statesForMap.isEmpty ? null : statesForMap.first;
  }

  bool _areEqual(Map<Side, List<Panel>> a, Map<Side, List<Panel>> b) =>
      (a.keys.length != b.keys.length)
          ? false
          : a.keys.every((Side side) {
              List<Panel> aPanels = a[side];
              List<Panel> bPanels = b[side];
              if (bPanels == null) {
                return false;
              }
              if (bPanels.length != aPanels.length) {
                return false;
              }
              for (int i = 0; i < aPanels.length; i++) {
                if (aPanels[i] != bPanels[i]) {
                  return false;
                }
              }
              return true;
            });

  double _getProgress(Panel panel, Side side) {
    List<ResizingState> panelStates = _states
        .where((ResizingState state) =>
            state.sideToPanelsMap[side]?.contains(panel) ?? false)
        .toList();
    assert(panelStates.length <= 1);
    return panelStates.isEmpty ? 0.0 : panelStates.first.simulation.value;
  }

  @override
  bool handleTick(double elapsedSeconds) {
    bool done = true;
    _states.toList().forEach((ResizingState state) {
      if (!state.simulation.isDone) {
        state.simulation.elapseTime(elapsedSeconds);
      }
      if (!state.simulation.isDone) {
        done = false;
      } else if (state.simulation.target == 0.0) {
        _states.remove(state);
      }
    });
    return !done;
  }
}
