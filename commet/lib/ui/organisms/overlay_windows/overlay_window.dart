import 'dart:ui';

import 'package:commet/debug/log.dart';
import 'package:commet/ui/atoms/scaled_safe_area.dart';
import 'package:commet/ui/molecules/show_on_hover.dart';
import 'package:commet/ui/organisms/overlay_windows/overlay_window_manager.dart';
import 'package:commet/utils/scaled_app.dart';
import 'package:flutter/material.dart';
import 'package:tiamat/tiamat.dart' as tiamat;

class OverlayWindowWidget extends StatefulWidget {
  const OverlayWindowWidget({required this.window, this.onClose, super.key});
  final OverlayWindow window;
  final Function()? onClose;

  @override
  State<OverlayWindowWidget> createState() => _OverlayWindowState();
}

class _OverlayWindowState extends State<OverlayWindowWidget>
    with SingleTickerProviderStateMixin {
  double borderSize = 10.0;

  Rect rect = Rect.fromLTWH(50, 50, 300, 200);

  Offset _positionedOffset = Offset(0, 0);

  Offset offset = Offset(0, 0);

  Offset get targetOffset {
    if (fullScreen) {
      return Offset(0, 0);
    }

    final padding = MediaQuery.of(context).padding;
    var size = MediaQuery.of(context).scale().size;

    var margin = 50.0;
    var max = Offset(size.width - padding.right - margin,
        size.height - padding.bottom - margin);

    _positionedOffset = Offset(
        _positionedOffset.dx.clamp(-targetSize.width + margin, max.dx),
        _positionedOffset.dy.clamp(-targetSize.height + margin, max.dy));

    return _positionedOffset;
  }

  Size get targetSize {
    if (fullScreen) {
      final padding = MediaQuery.of(context).padding;
      var size = MediaQuery.of(context).scale().size;

      return Size(size.width - padding.left - padding.right,
          size.height - padding.top - padding.bottom);
    }

    return Size(300, 200);
  }

  late Size _currentSize;
  bool fullScreen = true;

  @override
  void initState() {
    var ticker = createTicker(onTick);
    ticker.start();

    FlutterView view = WidgetsBinding.instance.platformDispatcher.views.first;
    Size size = view.physicalSize;
    _currentSize = size;

    super.initState();
  }

  void onTick(Duration elapsed) {
    double delta = (elapsed.inMilliseconds.toDouble() / 1000.0).clamp(0, 1);

    var moveSpeed = delta * 0.5;
    var sizeSpeed = delta * 0.5;
    var x = lerpDouble(offset.dx, targetOffset.dx, moveSpeed)!;
    var y = lerpDouble(offset.dy, targetOffset.dy, moveSpeed)!;

    var sizeX = lerpDouble(_currentSize.width, targetSize.width, sizeSpeed);
    var sizeY = lerpDouble(_currentSize.height, targetSize.height, sizeSpeed);

    var newOffset = Offset(x, y);
    var newSize = Size(sizeX!, sizeY!);

    if (newSize != _currentSize || newOffset != offset) {
      var offsetDiff = (newOffset - targetOffset).distance;
      Log.i("Offset difference: $offsetDiff");

      if (offsetDiff < 1) {
        newOffset = targetOffset;
      }

      var sizeDiff = (newSize.width - targetSize.width).abs() +
          (newSize.height - targetSize.height).abs();

      if (sizeDiff < 1) {
        newSize = targetSize;
      }

      Log.i("Size Diff: ${sizeDiff}");

      setState(() {
        offset = newOffset;
        _currentSize = newSize;

        Log.i("On Tick: ${offset}, ${_currentSize}");
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: offset.dx,
      top: offset.dy,
      child: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withAlpha(120),
                    offset: Offset(3, 3),
                    blurRadius: 10)
              ],
              borderRadius: BorderRadius.circular(8),
              color: ColorScheme.of(context).surfaceContainer,
            ),
            child: buildWithWindowSize(
              Column(
                children: [
                  Padding(
                    padding: EdgeInsetsGeometry.fromLTRB(3, 3, 3, 3),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        tiamat.Text.labelLow(widget.window.title),
                        Row(
                          children: [
                            if (fullScreen ||
                                ShowOnHover.useTouchControls == false)
                              SizedBox(
                                  height: 30,
                                  width: 30,
                                  child: tiamat.IconButton(
                                    icon: fullScreen
                                        ? Icons.minimize
                                        : Icons.fullscreen,
                                    onPressed: () {
                                      setState(() {
                                        fullScreen = !fullScreen;
                                      });
                                    },
                                  )),
                            SizedBox(
                                height: 30,
                                width: 30,
                                child: tiamat.IconButton(
                                  icon: Icons.close,
                                  onPressed: widget.onClose,
                                )),
                          ],
                        )
                      ],
                    ),
                  ),
                  Expanded(
                    child: Padding(
                      padding: EdgeInsetsGeometry.fromLTRB(8, 0, 8, 8),
                      child: ClipRRect(
                        borderRadius: BorderRadiusGeometry.circular(8),
                        child: Stack(
                          children: [
                            Container(
                                color: ColorScheme.of(context)
                                    .surfaceContainerLowest,
                                child: widget.window.widget),
                            if (!fullScreen)
                              ShowOnHover(
                                  background: Container(
                                    color: Colors.transparent,
                                    child: SizedBox(
                                      width: double.infinity,
                                      height: double.infinity,
                                    ),
                                  ),
                                  child: Container(
                                    color: ColorScheme.of(context)
                                        .surfaceContainerLow
                                        .withAlpha(150),
                                    child: Stack(
                                      children: [
                                        Center(
                                            child: SizedBox(
                                                width: 50,
                                                height: 50,
                                                child: tiamat.IconButton(
                                                  icon: Icons.fullscreen,
                                                  size: 25,
                                                  onPressed: () {
                                                    setState(() {
                                                      fullScreen = true;
                                                    });
                                                  },
                                                  iconColor:
                                                      ColorScheme.of(context)
                                                          .onSurface,
                                                ))),
                                      ],
                                    ),
                                  )),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (!fullScreen)
            GestureDetector(
              behavior: HitTestBehavior.translucent,
              onPanUpdate: (details) {
                if (fullScreen) return;

                Log.i("Pan update: $details");

                setState(() {
                  _positionedOffset = _positionedOffset + details.delta;
                });
              },
              child: buildWithWindowSize(
                  Opacity(opacity: 0, child: Placeholder())),
            )
        ],
      ),
    );
  }

  Widget buildWithWindowSize(Widget child) {
    return ScaledSafeArea(
        top: fullScreen,
        bottom: fullScreen,
        left: fullScreen,
        right: fullScreen,
        child: SizedBox(
            width: _currentSize.width,
            height: _currentSize.height,
            child: child));
  }
}
