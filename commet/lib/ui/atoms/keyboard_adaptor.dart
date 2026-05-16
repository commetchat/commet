import 'dart:math';
import 'package:commet/main.dart';
import 'package:commet/utils/scaled_app.dart';
import 'package:flutter/material.dart';

class KeyboardAdaptorController {
  Function()? keepCurrentSize;
  Function()? clearOverride;

  bool Function()? hasOverride;
}

class KeyboardAdaptor extends StatefulWidget {
  const KeyboardAdaptor({
    super.key,
    required this.child,
    this.paddingContent,
    this.enabled = true,
    this.shouldPushContent,
    this.controller,
  });

  final Widget child;
  final bool enabled;
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
    widget.controller?.hasOverride = hasOverride;
  }

  @override
  Widget build(BuildContext context) {
    var scaledQuery = MediaQuery.of(context).scale();
    var offset = max(scaledQuery.viewInsets.bottom, scaledQuery.padding.bottom);

    var padding = scaledQuery.viewPadding;

    bool shouldPushContent = widget.shouldPushContent == null ||
        widget.shouldPushContent?.call() == true;

    if (sizeOverride != null && offset > sizeOverride!) {
      preferences.emojiPickerHeight.set(offset);
      sizeOverride = null;
    }

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
            height:
                (!widget.enabled && sizeOverride == null) ? 0 : contentHeight,
          ),
        ),
        Container(
          // color: Colors.blue.withAlpha(40),
          child: AnimatedContainer(
            duration: Durations.short1,
            height: widget.enabled ? pushHeight : 0,
          ),
        ),
        SizedBox(
          height: widget.enabled ? padding.bottom : 0,
        )
      ],
    );
  }

  keepCurrentSize({double min = 300}) {
    var scaledQuery = MediaQuery.of(context).scale();
    var offset = max(scaledQuery.viewInsets.bottom, scaledQuery.padding.bottom);

    if (offset < min) {
      offset = preferences.emojiPickerHeight.value;
    } else {
      preferences.emojiPickerHeight.set(offset);
    }

    sizeOverride = offset;
  }

  clearOverride() {
    setState(() {
      sizeOverride = null;
    });
  }

  bool hasOverride() {
    return sizeOverride != null;
  }
}
