import 'package:commet/utils/debounce.dart';
import 'package:flutter/material.dart';

class HoverMenu extends StatefulWidget {
  const HoverMenu(
      {super.key,
      this.menuAlignment = Alignment.topLeft,
      this.parentAlignment = Alignment.topLeft,
      this.onHoverStateChanged,
      required this.builder,
      required this.child});
  final Widget child;
  final Widget Function(BuildContext context) builder;
  final Function(bool hovered)? onHoverStateChanged;
  final Alignment menuAlignment;
  final Alignment parentAlignment;

  @override
  State<HoverMenu> createState() => HoverMenuState();
}

class HoverMenuState extends State<HoverMenu> {
  OverlayEntry? entry;
  LayerLink link = LayerLink();

  bool overlayHovered = false;

  Debouncer overlayRemoveDebounder =
      Debouncer(delay: Duration(milliseconds: 20));

  void addOverlay() {

    widget.onHoverStateChanged?.call(true);

    if (entry != null) {
      entry?.remove();
      entry = null;
    }

    entry = OverlayEntry(
      canSizeOverlay: true,
      builder: (context) {
        return Row(
          children: [
            CompositedTransformFollower(
                link: link,
                followerAnchor: widget.menuAlignment,
                targetAnchor: widget.parentAlignment,
                child: MouseRegion(
                    onEnter: (event) {
                      overlayRemoveDebounder.cancel();
                    },
                    onExit: (event) {
                      overlayRemoveDebounder.run(removeOverlay);
                    },
                    child: widget.builder(context))),
          ],
        );
      },
    );

    Overlay.of(
      context,
    ).insert(entry!);
  }

  void removeOverlay() {


    widget.onHoverStateChanged?.call(false);

    if (entry != null) {
      entry?.remove();
      entry = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return CompositedTransformTarget(
      link: link,
      child: MouseRegion(
          onEnter: (event) {
            overlayRemoveDebounder.cancel();
            if (entry == null) {
              addOverlay();
            }
          },
          onExit: (event) {
            if (!overlayHovered) {
              overlayRemoveDebounder.run(removeOverlay);
            }
          },
          child: widget.child),
    );
  }
}
