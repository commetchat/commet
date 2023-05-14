// Based on https://github.com/blackmann/overlapping_panels
// Copyright 2022 De-Great Yartey. All rights reserved.

import 'package:flutter/material.dart';
import 'dart:core';

const double bleedWidth = 20;

/// Display sections
enum RevealSide { left, right, main }

/// Widget to display three view panels with the [OverlappingPanels.main] being
/// in the center, [OverlappingPanels.left] and [OverlappingPanels.right] also
/// revealing from their respective sides. Just like you will see in the
/// Discord mobile app's navigation.
class OverlappingPanels extends StatefulWidget {
  /// The left panel
  final Widget? left;

  /// The main panel
  final Widget main;

  /// The right panel
  final Widget? right;

  /// The offset to use to keep the main panel visible when the left or right
  /// panel is revealed.
  final double restWidth;

  /// A callback to notify when a panel reveal has completed.
  final ValueChanged<RevealSide>? onSideChange;

  final Function? onDragStart;

  final double threshold = 0.2;

  const OverlappingPanels(
      {this.left,
      required this.main,
      this.right,
      this.restWidth = 40,
      this.onSideChange,
      this.onDragStart,
      Key? key})
      : super(key: key);

  static OverlappingPanelsState? of(BuildContext context) {
    return context.findAncestorStateOfType<OverlappingPanelsState>();
  }

  @override
  State<StatefulWidget> createState() {
    return OverlappingPanelsState();
  }
}

class OverlappingPanelsState extends State<OverlappingPanels>
    with TickerProviderStateMixin {
  AnimationController? controller;
  double translate = 0;
  RevealSide currentSide = RevealSide.main;

  double _calculateGoal(double width, int multiplier) {
    return (multiplier * width) + (-multiplier * widget.restWidth);
  }

  void _onApplyTranslation() {
    final mediaWidth = MediaQuery.of(context).size.width;
    final animationController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 300));

    animationController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        if (widget.onSideChange != null) {
          widget.onSideChange!(translate == 0
              ? RevealSide.main
              : (translate > 0 ? RevealSide.left : RevealSide.right));
        }
        animationController.dispose();
      }
    });

    var percent = -translate / mediaWidth;
    bool crossedThreshold = percent.abs() > widget.threshold &&
        percent.abs() < 1 - widget.threshold;

    if (crossedThreshold) {
      switch (currentSide) {
        case RevealSide.left:
        case RevealSide.right:
          revealMainPanel(animationController);
          break;
        case RevealSide.main:
          (percent < 0)
              ? revealLeftPanel(mediaWidth, animationController)
              : revealRightPanel(mediaWidth, animationController);
          break;
      }
    } else {
      switch (currentSide) {
        case RevealSide.left:
          revealLeftPanel(mediaWidth, animationController);
          break;
        case RevealSide.right:
          revealRightPanel(mediaWidth, animationController);
          break;
        case RevealSide.main:
          revealMainPanel(animationController);
          break;
      }
    }

    animationController.forward();
  }

  void revealLeftPanel(
      double mediaWidth, AnimationController animationController) {
    currentSide = RevealSide.left;
    _setTranslateMultiplier(mediaWidth, 1, animationController);
  }

  void revealRightPanel(
      double mediaWidth, AnimationController animationController) {
    currentSide = RevealSide.right;
    _setTranslateMultiplier(mediaWidth, -1, animationController);
  }

  void revealMainPanel(AnimationController animationController) {
    currentSide = RevealSide.main;
    final animation = Tween<double>(begin: translate, end: 0).animate(
        CurvedAnimation(
            parent: animationController, curve: Curves.easeOutExpo));

    animation.addListener(() {
      setState(() {
        translate = animation.value;
      });
    });
  }

  void _setTranslateMultiplier(double mediaWidth, int multiplier,
      AnimationController animationController) {
    final goal = _calculateGoal(mediaWidth, multiplier);

    final Tween<double> tween = Tween(begin: translate, end: goal);

    final animation = tween.animate(CurvedAnimation(
        parent: animationController, curve: Curves.easeOutExpo));

    animation.addListener(() {
      setState(() {
        translate = animation.value;
      });
    });
  }

  void reveal(RevealSide direction) {
    final mediaWidth = MediaQuery.of(context).size.width;
    final animationController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 300));

    switch (direction) {
      case RevealSide.left:
        revealLeftPanel(mediaWidth, animationController);
        break;
      case RevealSide.right:
        revealRightPanel(mediaWidth, animationController);
        break;
      case RevealSide.main:
        revealMainPanel(animationController);
        break;
    }

    animationController.forward();
  }

  void onTranslate(double delta) {
    setState(() {
      final translate = this.translate + delta;
      if (translate < 0 && widget.right != null ||
          translate > 0 && widget.left != null) {
        this.translate = translate;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Stack(children: [
      Offstage(
        offstage: translate < 0,
        child: widget.left,
      ),
      Offstage(
        offstage: translate > 0,
        child: widget.right,
      ),
      Transform.translate(
        offset: Offset(translate, 0),
        child: DecoratedBox(
            decoration: BoxDecoration(boxShadow: [
              BoxShadow(color: Colors.black.withAlpha(30), blurRadius: 20)
            ]),
            child: widget.main),
      ),
      GestureDetector(
        behavior: HitTestBehavior.translucent,
        onHorizontalDragStart: (details) {
          widget.onDragStart?.call();
        },
        onHorizontalDragUpdate: (details) {
          onTranslate(details.delta.dx);
        },
        onHorizontalDragEnd: (details) {
          _onApplyTranslation();
        },
      ),
    ]);
  }
}
