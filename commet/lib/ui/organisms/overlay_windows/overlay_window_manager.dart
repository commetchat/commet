import 'package:commet/debug/log.dart';
import 'package:commet/ui/organisms/overlay_windows/overlay_window.dart';
import 'package:flutter/material.dart';

class OverlayWindow {
  Widget widget;
  String title;
  Stream onClose;

  OverlayWindow(
      {required this.widget, required this.title, required this.onClose});
}

class OverlayWindowsData extends InheritedWidget {
  const OverlayWindowsData({
    Key? key,
    required this.windows,
    required Widget child,
  }) : super(key: key, child: child);

  final List<OverlayWindow> windows;

  static OverlayWindowsData of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<OverlayWindowsData>()!;
  }

  @override
  bool updateShouldNotify(covariant InheritedWidget oldWidget) {
    return true;
  }
}

class OverlayWindowsManager extends StatefulWidget {
  const OverlayWindowsManager({required this.child, super.key});
  final Widget child;

  static OverlayWindowsManagerState of(BuildContext context) {
    return context.findAncestorStateOfType<OverlayWindowsManagerState>()!;
  }

  @override
  State<OverlayWindowsManager> createState() => OverlayWindowsManagerState();
}

class OverlayWindowsManagerState extends State<OverlayWindowsManager> {
  final List<OverlayWindow> windows = List.empty(growable: true);

  void addWindow(OverlayWindow window) {
    setState(() {
      windows.add(window);

      window.onClose.listen((_) {
        if (mounted) {
          removeWindow(window);
        }
      });
    });
  }

  void removeWindow(OverlayWindow window) {
    setState(() {
      windows.remove(window);
    });
  }

  void windowClosed(OverlayWindow window) {
    removeWindow(window);
  }

  @override
  Widget build(BuildContext context) {
    return OverlayWindowsData(windows: windows, child: widget.child);
  }
}

class OverlayWindowsSurface extends StatelessWidget {
  const OverlayWindowsSurface({super.key});

  @override
  Widget build(BuildContext context) {
    var data = OverlayWindowsData.of(context);
    return Stack(children: [
      for (var i in data.windows)
        OverlayWindowWidget(
          window: i,
          onClose: () {
            OverlayWindowsManager.of(context).windowClosed(i);
          },
        ),
    ]);
  }
}
