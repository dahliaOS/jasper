# Fuchsia System UI

This repository contains System UI bits for the Fuchsia operating system.

## Overview

<p>
  <img
    src="armadillo/lib/res/Armadillo.png"
    alt="Early Screen Shot of Armadillo" style="width: 400px;"
    />
  <br/>
  _Early Screen Shot of Armadillo_
</p>

[Armadillo](armadillo)  is currently the default system UI for Fuchsia.
[Armadillo](armadillo)  is written in Flutter and is split into two separate
apps: [Armadillo](armadillo) and [Armadillo User Shell](armadillo_user_shell).

[Armadillo](armadillo) is a Flutter app that can run on Android and iOS and any
other platforms Flutter supports.  It contains a majority of the code.

[Armadillo User Shell](armadillo_user_shell) is a thin wrapper around
[Armadillo](armadillo) that obtains its data from the Fuchsia system and
interacts with the Fuchsia system's services via FIDL interfaces.  Thus,
[Armadillo User Shell](armadillo_user_shell) only runs on Fuchsia while
[Armadillo](armadillo) runs anywhere Flutter runs.

## Important Armadillo Non-Widget Classes

Some important non-Widget classes are the following:

**_[Story](armadillo/lib/story.dart)_** instances are typically generated from
an external data source (JSON or the Fuchsia system - see
[StoryModel](armadillo/lib/story_model.dart) below). Conceptually a story is a
set of apps and/or modules that work together for the user to achieve a goal.
[Story](armadillo/lib/story.dart) contains enough information to create the
visual representation of that concept as well as tracks the size and position of
its window in the UI via a [Panel](armadillo/lib/panel.dart).

**_[StoryCluster](armadillo/lib/story_cluster.dart)_** displays one or more
[Story](armadillo/lib/story.dart) instances.  In [Armadillo](armadillo) a user
can combine stories into a 'cluster' such that the stories in the cluster are
always displayed together.

**_[Panel](armadillo/lib/panel.dart)_** tracks the size and position of a
[Story](armadillo/lib/story.dart)'s window in its
[StoryCluster](armadillo/lib/story_cluster.dart)'s
[StoryClusterWidget](armadillo/lib/story_cluster_widget.dart).

**_[Suggestion](armadillo/lib/suggestion.dart)_** instances are typically
generated from an external data source (JSON or the Fuchsia system - see
[SuggestionModel](armadillo/lib/suggestion_model.dart) below).
Conceptually a suggestion is a representation of an action the user can take to
augment an existing story or to start a new one.
[Suggestion](armadillo/lib/suggestion.dart) contains enough information to
create the visual representation of that concept.

**_[RK4SpringSimulation](widgets/lib/rk4_spring_simulation.dart)_** instances
are used throughout [Armadillo](armadillo) to perform animations.


## Armadillo Mega Widgets

Here is a sampling of the important Widgets used by Armadillo:

**_[Armadillo](armadillo/lib/armadillo.dart)_** is the main Widget.  Its purpose
is to set up [Models](#models) the rest of the Widgets
depend upon. It uses the [Conductor](armadillo/lib/conductor.dart) to display
the actual UI Widgets.

**_[Conductor](armadillo/lib/conductor.dart)_** is responsible for putting all
the major Widgets together and connecting their events to each other.  These
Widgets include: [Now](armadillo/lib/now.dart),
[StoryList](armadillo/lib/story_list.dart), and
[SuggestionList](armadillo/lib/suggestion_list.dart).  The
[Conductor](armadillo/lib/conductor.dart) also (temporarily) manages things like
the on screen [Keyboard](keyboard/lib/keyboard.dart) if applicable.

**_[StoryList](armadillo/lib/story_list.dart)_** is responsible for displaying
all of the user's stories in [StoryCluster](armadillo/lib/story_cluster.dart)s
specified by the [StoryModel](armadillo/lib/story_model.dart).
[StoryList](armadillo/lib/story_list.dart) creates
[StoryClusterWidget](armadillo/lib/story_cluster_widget.dart)s to display each
[StoryCluster](armadillo/lib/story_cluster.dart).  These
[StoryClusterWidget](armadillo/lib/story_cluster_widget.dart)s are laid out by
[StoryListRenderBlock](armadillo/lib/story_list_render_block.dart) using the
algorithm specified in [StoryListLayout](armadillo/lib/story_list_layout.dart).

**_[SuggestionList](armadillo/lib/suggestion_list.dart)_** is responsible for
displaying all of the suggestions the system has come up with for the user's
next actions specified by the
[SuggestionModel](armadillo/lib/suggestion_model.dart).

**_[Now](armadillo/lib/now.dart)_** is responsible for displaying UI related to
the user's current context as well as having an affordance for user and device
settings.
Since a lot of the Widgets used by [Now](armadillo/lib/now.dart) animate in
concert, the [NowModel](armadillo/lib/now_model.dart) creates them and provides
them to [Now](armadillo/lib/now.dart).

**_[StoryClusterWidget](armadillo/lib/story_cluster_widget.dart)_** is
responsible for displaying a [StoryCluster](armadillo/lib/story_cluster.dart).
This Widget uses [PanelDragTargets](armadillo/lib/panel_drag_targets.dart) to
manage what happens when another
[StoryCluster](armadillo/lib/story_cluster.dart) is dragged above this Widget
and [StoryPanels](armadillo/lib/story_panels.dart) to display each
[Story](armadillo/lib/story.dart) in the
[StoryCluster](armadillo/lib/story_cluster.dart).

 **_[ArmadilloDragTarget & ArmadilloLongPressDraggable
](armadillo/lib/armadillo_drag_target.dart)_**
 manage the ability of a user to long press to 'pick up' a Widget
 ([ArmadilloLongPressDraggable](armadillo/lib/armadillo_drag_target.dart)) and
 'drop it' onto another Widget
 ([ArmadilloDragTarget](armadillo/lib/armadillo_drag_target.dart)).

## Armadillo Models <a name="models"></a>

**_[Models](armadillo/lib/model.dart)_** are used to pass data down the Widget
tree.  This data can be simple, like a [size](armadillo/lib/size_model.dart) or
it can be complex like the
[list of the user's stories](armadillo/lib/story_model.dart).

Models within Armadillo serve several purposes:
1. **Performance**.  Using a model to store data improves performance when only
certain parts of a Widget tree depend on that data.  Instead of passing that
data to the constructors of all the Widgets between the source of the data and
the destination of the data which would cause all of those Widgets to rebuild,
the destination Widget can look up the data directly and, in so doing, register
to be rebuilt when that data changes.

1. **Simplicity**.  Often a Widget that depends on a piece of data for
displaying itself will be a StatefulWidget.  By using a Model for that data,
that Widget can now become a StatelessWidget which is much simpler to code and
to use.

1. **Coordination**.  Many of the Widgets in Armadillo depend on each other in
subtle ways.  By pulling the data for that dependency into a Model each Widget
can look to the Model for its dependent data instead of worrying about where
that data was generated.   Since all Widgets that use the data register with the
Model to be rebuilt when it changes, all Widgets will be rebuilt at the same
time and react together.

1. **Abstraction**. Models provide a simple and standard way of abstracting the
source of a Widget's dependent data and the Widget itself.  One example of this
is how [Armadillo](armadillo) and [Armadillo User Shell](armadillo_user_shell)
use different sources for their [StoryModel](armadillo/lib/story_model.dart) and
[SuggestionModel](armadillo/lib/suggestion_model.dart).
[Armadillo](armadillo) reads its data from JSON files (via
[JsonStoryGenerator](armadillo/lib/json_story_generator.dart) and
[JsonSuggestionModel](armadillo/lib/json_suggestion_model.dart)) while
[Armadillo User Shell](armadillo_user_shell) gets its data from the Fuchsia
framework (via
[StoryProviderStoryGenerator](
armadillo_user_shell/lib/story_provider_story_generator.dart) and
[SuggestionProviderSuggestionModel](
  armadillo/lib/suggestion_provider_suggestion_model.dart)).

**_[ConstraintsModel](armadillo/lib/constraints_model.dart)_** contains the
constraints used by the
[ChildConstraintsChanger](armadillo/lib/child_constraints_changer.dart) which
are essentially simulated screen sizes Armadillo can emulate.

**_[DebugModel](armadillo/lib/debug_model.dart)_** contains debug flags which
are used to enable and disable Widgets like
[TargetInfluenceOverlay](armadillo/lib/target_influence_overlay.dart) and
[TargetOverlay](armadillo/lib/target_overlay.dart).

**_[NowModel](armadillo/lib/now_model.dart)_** provides the Widgets for
[Now](armadillo/lib/now.dart) to display.

**_[OpacityModel](armadillo/lib/opacity_model.dart)_** provides an opacity
value.  This model is typically used for performance reasons when animating
opacity.

**_[PanelResizingModel](armadillo/lib/panel_resizing_model.dart)_** manages the
data around panel resizing for stories within a
[StoryCluster](armadillo/lib/story_cluster.dart).  This model is populated by
the [PanelResizingOverlay](armadillo/lib/panel_resizing_overlay.dart).

**_[SizeModel](armadillo/lib/size_model.dart)_** provides a size value.  This
model is typically used for performance reasons when a Widget needs the size of
a particular Widget.

**_[StoryClusterDragStateModel](
armadillo/lib/story_cluster_drag_state_model.dart)_** holds the data around any
ongoing drags of a [StoryCluster](armadillo/lib/story_cluster.dart).

**_[StoryClusterPanelsModel](armadillo/lib/story_cluster_panels_model.dart)_**
tracks changes to the [Panels](armadillo/lib/panel.dart) used by the
[Stories](armadillo/lib/story.dart) within a
[StoryCluster](armadillo/lib/story_cluster.dart).

**_[StoryClusterStoriesModel](
armadillo/lib/story_cluster_stories_model.dart)_** tracks changes to the
[Stories](armadillo/lib/story.dart) within a
[StoryCluster](armadillo/lib/story_cluster.dart).

**_[StoryDragTransitionModel](
armadillo/lib/story_drag_transition_model.dart)_** tracks the progress of the
story drag transition that occurs when a story cluster is first picked up.  All
story clusters shrink, Now fades, the SuggestionList unpeeks, etc.

**_[StoryModel](armadillo/lib/story_model.dart)_** provides the list of recent
stories the user has used in clusters.

**_[StoryRearrangementScrimModel](
armadillo/lib/story_rearrangement_scrim_model.dart)_** tracks the progress
transition that occurs when one cluster is dragged over another cluster.  The
background darkens and the background story clusters blur.

**_[SuggestionModel](armadillo/lib/suggestion_model.dart)_** provides the list
of suggested next actions for the user to perform.
