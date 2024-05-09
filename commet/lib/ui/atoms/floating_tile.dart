import 'package:commet/debug/log.dart';
import 'package:commet/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

class FloatingTile extends StatefulWidget {
  const FloatingTile(
      {super.key,
      required this.child,
      this.initialPosition = Alignment.topRight});
  final Alignment initialPosition;
  final Widget child;

  @override
  State<FloatingTile> createState() => _FloatingTileState();
}

class _FloatingTileState extends State<FloatingTile> {
  late OverlayEntry entry;

  @override
  void initState() {
    WidgetsBinding.instance.addPostFrameCallback((_) => addOverlay());
    super.initState();
  }

  @override
  void dispose() {
    Log.i("Floating tile is being diposed!");

    entry.remove();
    super.dispose();
  }

  void addOverlay() {
    Log.i("added floating tile overlay");

    entry = OverlayEntry(builder: buildOverlay);
    Overlay.of(context).insert(entry);
  }

  Widget buildOverlay(BuildContext context) {
    var size = MediaQuery.of(context).size;
    var padding = MediaQuery.of(context).padding;
    return TileOverlay(
      initialLayoutSize: Rect.fromLTWH(0, 0, size.width, size.height),
      safeAreaPadding: padding,
      child: widget.child,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container();
  }
}

class TileOverlay extends StatefulWidget {
  const TileOverlay(
      {super.key,
      required this.child,
      this.initialPosition = Alignment.topRight,
      this.initialLayoutSize = Rect.zero,
      this.safeAreaPadding = EdgeInsets.zero});
  final Rect initialLayoutSize;
  final EdgeInsets safeAreaPadding;
  final Alignment initialPosition;
  final Widget child;
  @override
  State<TileOverlay> createState() => _TileOverlayState();
}

class _TileOverlayState extends State<TileOverlay> {
  Offset offset = const Offset(0, 0);
  Offset startPosition = const Offset(0, 0);

  GlobalKey childKey = GlobalKey();

  @override
  void initState() {
    super.initState();

    switch (widget.initialPosition) {
      case Alignment.topRight:
        offset = Offset(widget.initialLayoutSize.width, 0);
        break;
      case Alignment.bottomLeft:
        offset = Offset(0, widget.initialLayoutSize.height);
        break;
      case Alignment.bottomRight:
        offset = Offset(
            widget.initialLayoutSize.width, widget.initialLayoutSize.height);
        break;
      case Alignment.topLeft:
        offset = Offset.zero;
        break;
    }

    offset = getNearestPoint(
        offset, Offset.zero, widget.initialLayoutSize, widget.safeAreaPadding);

    SchedulerBinding.instance.addPostFrameCallback(postFrameCallback);
  }

  void postFrameCallback(_) {
    updatePoint(offset);
  }

  Offset getNearestPoint(
      Offset currentPos, Offset size, Rect bounds, EdgeInsets safeAreaPadding) {
    var p = 10.0;

    var b = Rect.fromLTRB(
        bounds.left / preferences.appScale,
        bounds.top / preferences.appScale,
        bounds.right / preferences.appScale,
        bounds.bottom / preferences.appScale);

    var rect = Rect.fromLTRB(
        b.left + p + safeAreaPadding.left,
        b.top + p + safeAreaPadding.top,
        b.right - p - size.dx - safeAreaPadding.right,
        b.bottom - p - size.dy - safeAreaPadding.bottom);

    var points = [
      Offset(rect.left, rect.top),
      Offset(rect.right, rect.top),
      Offset(rect.left, rect.bottom),
      Offset(rect.right, rect.bottom)
    ];

    var minDistance = 9999999999.0;
    var pos = currentPos;
    for (var point in points) {
      var dist = (point - currentPos).distance;
      if (dist < minDistance) {
        minDistance = dist;
        pos = point;
      }
    }

    return pos;
  }

  void updatePoint(Offset currentPoint) {
    var size = MediaQuery.of(context).size;

    var childSize = childKey.currentContext?.size;

    if (childSize == null) {
      return;
    }

    var point = getNearestPoint(
        currentPoint,
        Offset(childSize.width, childSize.height),
        Rect.fromLTWH(0, 0, size.width, size.height),
        widget.safeAreaPadding);

    if ((point - offset).distance > 1) {
      setState(() {
        offset = point;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    SchedulerBinding.instance.addPostFrameCallback(postFrameCallback);
    return NotificationListener(
      onNotification: (SizeChangedLayoutNotification notification) {
        return false;
      },
      child: AnimatedPositioned(
          left: offset.dx,
          top: offset.dy,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutCubic,
          child: GestureDetector(
              onPanUpdate: (details) {
                setState(() {
                  offset = details.globalPosition - startPosition;
                });
              },
              onPanStart: (details) {
                startPosition = details.localPosition;
              },
              onPanEnd: (details) {
                var pos = offset + details.velocity.pixelsPerSecond;
                updatePoint(pos);
              },
              child: Container(key: childKey, child: widget.child))),
    );
  }
}
