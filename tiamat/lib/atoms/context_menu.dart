import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:just_the_tooltip/just_the_tooltip.dart';
import 'package:tiamat/atoms/seperator.dart';
import 'package:tiamat/atoms/text.dart';
import 'package:tiamat/atoms/tile.dart';
import 'package:tiamat/tiamat.dart' as tiamat;
import 'package:widgetbook_annotation/widgetbook_annotation.dart';

@UseCase(name: "Context Menu", type: ContextMenu)
Widget wbContextMenu(BuildContext context) {
  return Tile.low1(
    child: Center(
        child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: ContextMenu(
              items: [
                ContextMenuItem(
                    text: "Copy Text",
                    icon: Icons.copy_rounded,
                    onPressed: () {
                      print("Copying text");
                    }),
                ContextMenuItem(
                  text: "Delete Message",
                  icon: Icons.delete,
                  color: Theme.of(context).colorScheme.error,
                ),
              ],
              child: const Tile.low3(
                child: SizedBox(
                    width: 500,
                    height: 500,
                    child: Center(
                        child:
                            const tiamat.Text.label("Right Click Somewhere"))),
              ),
            ))),
  );
}

class ContextMenuOverlay extends StatefulWidget {
  const ContextMenuOverlay(
      {super.key, required this.globalOffset, required this.items, this.close});
  final Offset globalOffset;
  final List<ContextMenuItem> items;
  final Function()? close;

  @override
  State<ContextMenuOverlay> createState() => _ContextMenuOverlayState();
}

class _ContextMenuOverlayState extends State<ContextMenuOverlay>
    with TickerProviderStateMixin {
  Offset? calculatedOffset;
  Size? size;
  GlobalKey sizeGetKey = GlobalKey();
  bool leftAlign = false;
  bool topAlign = false;

  late final AnimationController _controller = AnimationController(
    duration: const Duration(milliseconds: 200),
    vsync: this,
  );

  late final Animation<double> _animation = CurvedAnimation(
    parent: _controller,
    curve: Curves.fastOutSlowIn,
  );

  @override
  void initState() {
    SchedulerBinding.instance.scheduleFrameCallback(onFirstFrame);

    var view = WidgetsBinding.instance.platformDispatcher.views.first;
    var size = view.physicalSize;

    leftAlign = widget.globalOffset.dx > size.width / 2;
    topAlign = widget.globalOffset.dy > size.height / 2;

    super.initState();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (calculatedOffset == null) {
      return Container(
        child: Offstage(
          child: buildMenu(context, key: sizeGetKey),
        ),
      );
    } else {
      return Positioned(
          left: calculatedOffset!.dx - (leftAlign ? size!.width : 0),
          top: calculatedOffset!.dy - (topAlign ? size!.height : 0),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(7),
            child: SizeTransition(
              axisAlignment: -1,
              sizeFactor: _animation,
              child: Tile.low4(
                child: buildMenu(context),
              ),
            ),
          ));
    }
  }

  Widget buildMenu(BuildContext context, {GlobalKey? key}) {
    return IntrinsicWidth(
      key: key,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: widget.items
            .map((e) => e.build(context, () {
                  e.onPressed?.call();
                  _controller
                      .animateTo(0)
                      .then((value) => widget.close?.call());
                }))
            .toList(),
      ),
    );
  }

  void onFirstFrame(Duration timeStamp) {
    RenderBox getBox = context.findRenderObject() as RenderBox;
    var local = getBox.globalToLocal(widget.globalOffset);

    print("Local position: $local");
    print("Size: ${getBox.size}");

    var menuBox = sizeGetKey.currentContext!.findRenderObject() as RenderBox;
    print(menuBox);
    print(menuBox.size);

    setState(() {
      size = menuBox.size;
      calculatedOffset = local;
      _controller.animateTo(1);
    });
  }
}

class ContextMenu extends StatefulWidget {
  const ContextMenu(
      {super.key, required this.child, this.separator, required this.items});

  final Seperator? separator;
  final List<ContextMenuItem> items;
  final Widget child;

  @override
  State<ContextMenu> createState() => _ContextMenuState();
}

class _ContextMenuState extends State<ContextMenu> {
  JustTheController controller = JustTheController();
  Offset mousePosition = Offset.zero;
  OverlayEntry? entry;

  void addOverlay() {
    if (entry != null) {
      removeOverlay();
    }

    entry = OverlayEntry(builder: buildOverlay);
    Overlay.of(context).insert(entry!);
  }

  void removeOverlay() {
    entry?.remove();
    entry = null;
  }

  Widget buildOverlay(BuildContext overlayContext) {
    if (mounted)
      return GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: removeOverlay,
        child: Stack(
          children: [
            Theme(
              data: Theme.of(context),
              child: ContextMenuOverlay(
                globalOffset: mousePosition,
                items: widget.items,
                close: removeOverlay,
              ),
            ),
          ],
        ),
      );
    return Container();
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: (event) {
        mousePosition = event.position;
      },
      child: GestureDetector(
        onLongPress: () => _showMenu(context, mousePosition),
        onSecondaryTap: () => _showMenu(context, mousePosition),
        child: widget.child,
      ),
    );
  }

  void _showMenu(BuildContext context, Offset mousePosition) {
    addOverlay();
  }
}

class ContextMenuItem {
  const ContextMenuItem(
      {required this.text, this.onPressed, this.icon, this.color});

  final String text;
  final Function? onPressed;
  final IconData? icon;
  final Color? color;

  Widget build(BuildContext context, Function() onClicked) {
    var c = color ?? Theme.of(context).textTheme.bodyMedium!.color;
    return Material(
      color: Colors.transparent,
      child: Padding(
        padding: const EdgeInsets.all(3.0),
        child: InkWell(
            onTap: onClicked,
            borderRadius: BorderRadius.circular(8),
            child: Container(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisSize: MainAxisSize.max,
                  children: [
                    tiamat.Text(text,
                        type: TextType.body, maxLines: 1, color: c),
                    if (icon != null)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 0, 0, 0),
                        child: Icon(icon, color: c),
                      )
                  ],
                ))),
      ),
    );
  }
}
