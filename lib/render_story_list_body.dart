// Copyright 2016 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:math' as math;
import 'dart:ui' show lerpDouble, ImageFilter;

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

import 'story_cluster_widget.dart' show InlineStoryTitle;
import 'story_list_layout.dart';
import 'story_list_body_parent_data.dart';

/// Set to true to slide the unfocused children of [RenderStoryListBody] as the
/// focused child grows.
const bool _kSlideUnfocusedAway = true;

/// The distance in the Y direction to slide the unfocused children of
/// [RenderStoryListBody] as the focused child grows.
const double _kSlideUnfocusedAwayOffsetY = -200.0;

/// The unfocused children of [RenderStoryListBody] should be fully transparent
/// when the focused child's focus progress reaches this value and beyond.
const double _kFocusProgressWhenUnfocusedFullyTransparent = 0.7;

/// The ratio to use when converting the alpha of the scrim color to the
/// gaussian blur sigma values.
const double _kAlphaToBlurRatio = 1 / 25;

/// If true, children behind the scrim will be blurred.
const bool _kBlurScrimmedChildren = true;

/// Overrides [RenderListBody]'s layout, paint, and hit-test behaviour to allow
/// the following:
///   1) Stories are laid out as specified by [StoryListLayout].
///   2) A story expands as it comes into focus and shrinks when it leaves
///      focus.
///   3) Focused stories are above and overlap non-focused stories.
class RenderStoryListBody extends RenderListBody {
  bool _blurScrimmedChildren;
  Color _scrimColor;
  Size _parentSize;
  double _scrollOffset;
  double _bottomPadding;
  double _listHeight;
  double _liftScale;

  /// Constructor.
  RenderStoryListBody({
    List<RenderBox> children,
    Size parentSize,
    double scrollOffset,
    double bottomPadding,
    double listHeight,
    Color scrimColor,
    double liftScale,
    bool blurScrimmedChildren,
  })  : _parentSize = parentSize,
        _scrollOffset = scrollOffset,
        _bottomPadding = bottomPadding ?? 0.0,
        _listHeight = listHeight ?? 0.0,
        _scrimColor = scrimColor ?? new Color(0x00000000),
        _liftScale = liftScale ?? 1.0,
        _blurScrimmedChildren = blurScrimmedChildren ?? _kBlurScrimmedChildren,
        super(children: children, axisDirection: AxisDirection.down);

  /// Sets whether the children should be blurred when they are scrimmed.
  set blurScrimmedChildren(bool value) {
    if (_blurScrimmedChildren != (value ?? _kBlurScrimmedChildren)) {
      _blurScrimmedChildren = (value ?? _kBlurScrimmedChildren);
      markNeedsPaint();
    }
  }

  /// Sets the color of the scrim placed in front of unfocused children.
  set scrimColor(Color value) {
    if (_scrimColor != value) {
      _scrimColor = value;
      markNeedsPaint();
    }
  }

  /// Sets the size of the parent.  Used to position/size the children.
  set parentSize(Size value) {
    if (_parentSize != value) {
      _parentSize = value;
      markNeedsLayout();
    }
  }

  /// Sets the scroll offset.  Used to position the children.
  set scrollOffset(double value) {
    if (_scrollOffset != value) {
      _scrollOffset = value;
      markNeedsLayout();
    }
  }

  /// Sets the bottom padding.  Used to position the children.
  set bottomPadding(double value) {
    if (_bottomPadding != value) {
      _bottomPadding = value;
      markNeedsLayout();
    }
  }

  /// Sets the expected list height of this [RenderObject].  Used to position
  /// the children.
  set listHeight(double value) {
    if (_listHeight != value) {
      _listHeight = value;
      markNeedsLayout();
    }
  }

  /// Sets how much the children should be scaled due to a drag occurring.
  set liftScale(double value) {
    if (_liftScale != value) {
      _liftScale = value;
      markNeedsLayout();
    }
  }

  @override
  void setupParentData(RenderBox child) {
    if (child.parentData is! StoryListBodyParentData) {
      child.parentData = new StoryListBodyParentData(this);
    }
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    List<RenderBox> childrenSortedByFocusProgress =
        _childrenSortedByFocusProgress;
    if (childrenSortedByFocusProgress.isEmpty) {
      return;
    }
    final RenderBox lastChild = childrenSortedByFocusProgress.last;
    childrenSortedByFocusProgress.remove(lastChild);
    final StoryListBodyParentData mostFocusedChildParentData =
        lastChild.parentData;
    int unfocusedAlpha = (lerpDouble(
                1.0,
                0.0,
                mostFocusedChildParentData.focusProgress.clamp(
                        0.0, _kFocusProgressWhenUnfocusedFullyTransparent) /
                    _kFocusProgressWhenUnfocusedFullyTransparent) *
            255)
        .round();

    childrenSortedByFocusProgress.forEach((RenderBox child) {
      _paintChild(context, offset, child, unfocusedAlpha);
    });

    if (_scrimColor.alpha != 0) {
      if (_blurScrimmedChildren) {
        context.pushLayer(
          new BackdropFilterLayer(
            filter: new ImageFilter.blur(
              sigmaX: _scrimColor.alpha * _kAlphaToBlurRatio,
              sigmaY: _scrimColor.alpha * _kAlphaToBlurRatio,
            ),
          ),
          _paintScrim,
          offset,
        );
      } else {
        _paintScrim(context, offset);
      }
    }
    _paintChild(context, offset, lastChild, unfocusedAlpha);
  }

  void _paintScrim(
    PaintingContext context,
    Offset offset,
  ) {
    context.canvas.drawRect(
      new Rect.fromLTWH(offset.dx, offset.dy, size.width, size.height),
      new Paint()..color = _scrimColor,
    );
  }

  void _paintChild(
    PaintingContext context,
    Offset offset,
    RenderBox child,
    int unfocusedAlpha,
  ) {
    final StoryListBodyParentData childParentData = child.parentData;
    if (unfocusedAlpha != 255 && childParentData.focusProgress == 0.0) {
      // Apply transparency.
      assert(needsCompositing);
      context.pushOpacity(
        childParentData.offset + offset,
        unfocusedAlpha,
        (PaintingContext context, Offset offset) =>
            context.paintChild(child, offset),
      );
    } else {
      context.paintChild(child, childParentData.offset + offset);
    }
  }

  @override
  bool hitTestChildren(HitTestResult result, {Offset position}) {
    final List<RenderBox> children =
        _childrenSortedByFocusProgress.reversed.toList();
    if (children.isNotEmpty) {
      final RenderBox mostFocusedChild = children.first;
      final StoryListBodyParentData mostFocusedChildParentData =
          mostFocusedChild.parentData;
      double mostFocusedProgress = mostFocusedChildParentData.focusProgress;

      // Only hit the most focused child if it has some progress focusing.
      // This effectively prevents all of the most focused child's siblings
      // from being tapped, dragged over, or otherwise interacted with.
      if (mostFocusedProgress > 0.0) {
        Offset transformed = position - mostFocusedChildParentData.offset;
        if (mostFocusedChild.hitTest(result, position: transformed)) {
          return true;
        }
      } else {
        // Return the first child that passes the hit test.  Note, this doesn't
        // mean that's the only child that was hit (it's possible to hit
        // multiple children (for example a translucent child will add itself to
        // the HitTestResult but will return false for its hitTest)).
        for (int i = 0; i < children.length; i++) {
          final RenderBox child = children[i];
          final StoryListBodyParentData childParentData = child.parentData;
          Offset transformed = position - childParentData.offset;
          if (child.hitTest(result, position: transformed)) {
            return true;
          }
        }
      }
    }
    return false;
  }

  @override
  void performLayout() {
    assert(!constraints.hasBoundedHeight);
    assert(constraints.hasBoundedWidth);

    double scrollOffset = _scrollOffset;
    double maxFocusProgress = 0.0;
    double inlinePreviewScale =
        StoryListLayout.getInlinePreviewScale(_parentSize);
    double inlinePreviewTranslateToParentCenterRatio = math.min(
      1.0,
      inlinePreviewScale * 1.5 - 0.3,
    );
    double parentCenterOffsetY = _listHeight +
        (_bottomPadding - scrollOffset - (_parentSize.height / 2.0));
    Offset parentCenter =
        new Offset(_parentSize.width / 2.0, parentCenterOffsetY);

    {
      RenderBox child = firstChild;
      while (child != null) {
        final StoryListBodyParentData childParentData = child.parentData;

        double layoutHeight = childParentData.storyLayout.size.height;
        double layoutWidth = childParentData.storyLayout.size.width;
        double layoutOffsetX = childParentData.storyLayout.offset.dx;
        double layoutOffsetY = childParentData.storyLayout.offset.dy;
        double hintScale = lerpDouble(
          1.0,
          1.25,
          childParentData.inlinePreviewHintScaleProgress,
        );
        double liftScaleMultiplier = lerpDouble(
          _liftScale * hintScale,
          1.0,
          childParentData.inlinePreviewScaleProgress,
        );
        double scaledLayoutHeight = lerpDouble(
              layoutHeight,
              _parentSize.height * inlinePreviewScale,
              childParentData.inlinePreviewScaleProgress,
            ) *
            liftScaleMultiplier;
        double scaledLayoutWidth = lerpDouble(
              layoutWidth,
              _parentSize.width * inlinePreviewScale,
              childParentData.inlinePreviewScaleProgress,
            ) *
            liftScaleMultiplier;
        double scaleOffsetDeltaX = (layoutWidth - scaledLayoutWidth) / 2.0;
        double scaleOffsetDeltaY = (layoutHeight - scaledLayoutHeight) / 2.0;

        // Layout the child.
        double childHeight = lerpDouble(
          scaledLayoutHeight +
              InlineStoryTitle.getHeight(childParentData.focusProgress),
          _parentSize.height,
          childParentData.focusProgress,
        );
        double childWidth = lerpDouble(
          scaledLayoutWidth,
          _parentSize.width,
          childParentData.focusProgress,
        );
        child.layout(
          new BoxConstraints.tightFor(
            width: childWidth,
            height: childHeight,
          ),
          parentUsesSize: false,
        );
        // Position the child.
        childParentData.offset = new Offset(
          lerpDouble(
            layoutOffsetX + scaleOffsetDeltaX + constraints.maxWidth / 2.0,
            0.0,
            childParentData.focusProgress,
          ),
          lerpDouble(
            layoutOffsetY + scaleOffsetDeltaY + _listHeight,
            _listHeight - _parentSize.height - scrollOffset + _bottomPadding,
            childParentData.focusProgress,
          ),
        );

        // Reposition toward center if inline previewing.
        Offset currentCenter = new Offset(
          childParentData.offset.dx + childWidth / 2.0,
          childParentData.offset.dy + childHeight / 2.0,
        );
        Offset centeringOffset = parentCenter - currentCenter;
        childParentData.offset += centeringOffset.scale(
          lerpDouble(
            0.0,
            inlinePreviewTranslateToParentCenterRatio,
            childParentData.inlinePreviewScaleProgress,
          ),
          lerpDouble(
            0.0,
            inlinePreviewTranslateToParentCenterRatio,
            childParentData.inlinePreviewScaleProgress,
          ),
        );
        maxFocusProgress = math.max(
          maxFocusProgress,
          childParentData.focusProgress,
        );

        child = childParentData.nextSibling;
      }
    }

    // If any of the children are focused or focusing, shift all
    // non-focused/non-focusing children off screen.
    if (_kSlideUnfocusedAway && maxFocusProgress > 0.0) {
      RenderBox child = firstChild;
      while (child != null) {
        final StoryListBodyParentData childParentData = child.parentData;
        if (childParentData.focusProgress == 0.0) {
          childParentData.offset = childParentData.offset +
              new Offset(0.0, _kSlideUnfocusedAwayOffsetY * maxFocusProgress);
        }
        child = childParentData.nextSibling;
      }
    }

    // When we focus on a child there's a chance that the focused child will be
    // taller than the unfocused list.  In that case, increase the height of the
    // story list to be that of the focusing child and shift all the children
    // down to compensate.
    double unfocusedHeight = _listHeight + _bottomPadding;
    double deltaTooSmall =
        (_parentSize.height * maxFocusProgress) - unfocusedHeight;
    double finalHeight = unfocusedHeight;
    if (deltaTooSmall > 0.0) {
      // shift all children down by deltaTooSmall.
      RenderBox child = firstChild;
      while (child != null) {
        final StoryListBodyParentData childParentData = child.parentData;
        childParentData.offset = new Offset(
          childParentData.offset.dx,
          childParentData.offset.dy + deltaTooSmall,
        );
        child = childParentData.nextSibling;
      }

      finalHeight = (_parentSize.height * maxFocusProgress);
    }

    size = constraints.constrain(
      new Size(
        constraints.maxWidth,
        finalHeight,
      ),
    );

    assert(!size.isInfinite);
  }

  List<RenderBox> get _childrenSortedByFocusProgress {
    final List<RenderBox> children = <RenderBox>[];
    RenderBox child = firstChild;
    while (child != null) {
      final StoryListBodyParentData childParentData = child.parentData;
      children.add(child);
      child = childParentData.nextSibling;
    }

    children.sort((RenderBox child1, RenderBox child2) {
      final StoryListBodyParentData child1ParentData = child1.parentData;
      final StoryListBodyParentData child2ParentData = child2.parentData;
      return child1ParentData.focusProgress > child2ParentData.focusProgress
          ? 1
          : child1ParentData.focusProgress < child2ParentData.focusProgress
              ? -1
              : child1ParentData.inlinePreviewScaleProgress >
                      child2ParentData.inlinePreviewScaleProgress
                  ? 1
                  : child1ParentData.inlinePreviewScaleProgress <
                          child2ParentData.inlinePreviewScaleProgress
                      ? -1
                      : 0;
    });
    return children;
  }
}
