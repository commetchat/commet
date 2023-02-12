import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';

// Based on: https://github.com/mayurnile/web_smooth_scroll

/// Extra scroll offset to be added while the scroll is happened
/// Default value is 10
const int defaultScrollOffset = 10;

/// Duration/length for how long the animation should go
/// after the scroll has happened
/// Default value is 600ms
const int defaultAnimationDuration = 600;

class WebSmoothScroll extends StatefulWidget {
  /// Scroll Controller for controlling the scroll behaviour manually
  /// so we can animate to next scrolled position and avoid the jerky movement
  /// of default scroll
  final ScrollController controller;

  /// Child scrollable widget.
  final Widget child;

  /// Extra scroll offset to be added while the scroll is happened
  /// Default value is 100
  /// You can try it for a range of 10 - 300 or keep it 0
  final int scrollOffset;

  /// Duration/length for how long the animation should go
  /// after the scroll has happened
  /// Default value is 600ms
  final int animationDuration;

  /// Curve of the animation.
  final Curve curve;

  const WebSmoothScroll({
    Key? key,
    required this.controller,
    required this.child,
    this.scrollOffset = defaultScrollOffset,
    this.animationDuration = defaultAnimationDuration,
    this.curve = Curves.easeOut,
  }) : super(key: key);

  @override
  State<WebSmoothScroll> createState() => _WebSmoothScrollState();
}

class _WebSmoothScrollState extends State<WebSmoothScroll> {
  // data variables
  double _scroll = 0;
  double _oldScrollState = 0;

  @override
  void initState() {
    super.initState();

    // Adding listener so if value of listener is changed outside our class
    // it gets updated here to avoid unwanted scrolling behavior
    widget.controller.addListener(scrollListener);
  }

  @override
  void didUpdateWidget(covariant WebSmoothScroll oldWidget) {
    // In case if window is resized the widget gets initialized again without listener
    // adding it back again to resolve unwanted issues
    widget.controller.removeListener(scrollListener);
    widget.controller.addListener(scrollListener);

    super.didUpdateWidget(oldWidget);
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerSignal: onPointerSignal,
      child: widget.child,
    );
  }

  /// Member Functions
  ///
  ///
  void scrollListener() {
    _oldScrollState = _scroll;
    _scroll = widget.controller.offset;
  }

  void onPointerSignal(PointerSignalEvent event) {
    // Initializing default animation duration length in MS
    int millis = widget.animationDuration;

    if (event is PointerScrollEvent) {
      _scroll -= event.scrollDelta.dy;
      print(widget.controller.offset);
      double scrollDelta = _scroll - widget.controller.offset;

      print(scrollDelta);
      if (scrollDelta < 0) scrollDelta *= -1;

      _scroll = min(_scroll, widget.controller.position.maxScrollExtent);
      _scroll = max(_scroll, widget.controller.position.minScrollExtent);

      var time = millis;
      print(time);

      widget.controller.animateTo(
        _scroll,
        duration: Duration(milliseconds: time),
        curve: widget.curve,
      );
    }
  }
}
