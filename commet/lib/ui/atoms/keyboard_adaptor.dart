import 'dart:math';
import 'package:commet/utils/scaled_app.dart';
import 'package:flutter/material.dart';

class KeyboardAdaptorController {
  Function()? keepCurrentSize;
  Function()? clearOverride;
}

class KeyboardAdaptor extends StatefulWidget {
  const KeyboardAdaptor({
    super.key,
    required this.child,
    this.paddingContent,
    this.shouldPushContent,
    this.controller,
  });

  final Widget child;
  final Widget? paddingContent;
  final bool Function()? shouldPushContent;
  final KeyboardAdaptorController? controller;
  @override
  State<KeyboardAdaptor> createState() => _KeyboardAdaptorState();
}

class _KeyboardAdaptorState extends State<KeyboardAdaptor> {
  double? sizeOverride;

  @override
  initState() {
    super.initState();

    widget.controller?.keepCurrentSize = keepCurrentSize;
    widget.controller?.clearOverride = clearOverride;
  }

  @override
  Widget build(BuildContext context) {
    var scaledQuery = MediaQuery.of(context).scale();
    var offset = max(scaledQuery.viewInsets.bottom, scaledQuery.padding.bottom);

    var padding = scaledQuery.viewPadding;

    bool shouldPushContent = widget.shouldPushContent == null ||
        widget.shouldPushContent?.call() == true;

    if (sizeOverride != null && offset > sizeOverride!) {
      sizeOverride = null;
    }

    print("Padding: ${padding.bottom}");

    var contentHeight = (sizeOverride ?? offset) - padding.bottom;
    var pushHeight = (shouldPushContent ? (offset - padding.bottom) : 0.0);
    pushHeight = max(pushHeight, 0);
    contentHeight = max(contentHeight, 0);

    return Column(
      children: [
        widget.child,
        Container(
          //color: Colors.green.withAlpha(40),
          child: AnimatedContainer(
            duration: Durations.short1,
            child: widget.paddingContent,
            height: contentHeight,
          ),
        ),
        Container(
          // color: Colors.blue.withAlpha(40),
          child: AnimatedContainer(
            duration: Durations.short1,
            height: pushHeight,
          ),
        ),
        SizedBox(
          height: padding.bottom,
        )
      ],
    );
  }

  keepCurrentSize({double min = 300}) {
    var scaledQuery = MediaQuery.of(context).scale();
    var offset = max(scaledQuery.viewInsets.bottom, scaledQuery.padding.bottom);

    if (offset < min) {
      offset = min;
    }

    sizeOverride = offset;
  }

  clearOverride() {
    setState(() {
      sizeOverride = null;
    });
  }
}
