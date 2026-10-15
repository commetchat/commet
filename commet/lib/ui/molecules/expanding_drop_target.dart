import 'dart:math';

import 'package:flutter/material.dart';

class ExpandingDropTarget<T extends Object> extends StatefulWidget {
  const ExpandingDropTarget(
      {this.position,
      this.min = 70,
      this.max = 200,
      this.height = 30,
      super.key,
      this.onAcceptWithDetails,
      this.distanceBasedHeight = true,
      required this.onWillAcceptWithDetails});
  final Offset? position;
  final double min;
  final double max;
  final double height;
  final bool distanceBasedHeight;
  final void Function(Object)? onAcceptWithDetails;
  final bool Function(Object) onWillAcceptWithDetails;
  @override
  State<ExpandingDropTarget> createState() => _ExpandingDropTargetState();
}

class _ExpandingDropTargetState<T extends Object>
    extends State<ExpandingDropTarget<T>> {
  Offset? dragPosition;
  GlobalKey key = GlobalKey();

  double? distance = 0;

  @override
  void initState() {
    dragPosition = widget.position;
    super.initState();
  }

  double remapRange(
      double value, double low1, double high1, double low2, double high2,
      {bool clamp = true}) {
    if (clamp) {
      value = value.clamp(low1, high1);
    }

    var result = low2 + (value - low1) * (high2 - low2) / (high1 - low1);
    return result;
  }

  @override
  void didUpdateWidget(covariant ExpandingDropTarget<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    updatePosition();
  }

  void updatePosition() {
    RenderBox? box = key.currentContext?.findRenderObject() as RenderBox?;

    var position = box?.localToGlobal(Offset.zero);

    if (position == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => updatePosition());
      return;
    }

    setState(() {
      dragPosition = widget.position;

      if (dragPosition != null) {
        var dist = min((position.dy - dragPosition!.dy).abs(),
            ((position.dy + box!.size.height) - dragPosition!.dy).abs());

        distance = remapRange(dist, widget.min, widget.max, 1, 0);
      } else {
        distance = null;
      }
    });
  }

  bool isInside = false;

  @override
  Widget build(BuildContext context) {
    return DragTarget<T>(
      onWillAcceptWithDetails: (details) {
        print("on will accept:");

        setState(() {
          isInside = true;
        });
        return widget.onWillAcceptWithDetails.call(details.data) == true;
      },
      onLeave: (data) {
        setState(() {
          isInside = false;
        });
      },
      hitTestBehavior: HitTestBehavior.opaque,
      onAcceptWithDetails: (details) {
        print("Accepted!");
        widget.onAcceptWithDetails?.call(details);
      },
      builder: (context, candidateData, rejectedData) => Container(
        key: key,
        height: widget.distanceBasedHeight
            ? distance == null
                ? 0
                : (distance! * widget.height)
            : widget.height,
        width: 50,
        child: Container(
          decoration: BoxDecoration(
              border: BoxBorder.all(
                  color: isInside
                      ? ColorScheme.of(context).secondary
                      : Colors.transparent,
                  width: 3),
              borderRadius: BorderRadius.circular(8)),
        ),
      ),
    );
  }
}
