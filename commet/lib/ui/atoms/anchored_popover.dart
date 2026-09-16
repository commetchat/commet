import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Shows [popoverBuilder] in the root overlay, anchored to the widget built
/// by [anchorBuilder]. The popover opens above the anchor (below when there
/// is no room), stays inside the screen, and closes on an outside tap or
/// Escape. Pure Flutter, so it works the same on web.
class AnchoredPopover extends StatefulWidget {
  const AnchoredPopover({
    super.key,
    required this.anchorBuilder,
    required this.popoverBuilder,
    this.onOpenChanged,
    this.alignment = PopoverAlignment.center,
    this.gap = 8,
  });

  /// Builds the anchor; call `toggle` to open or close the popover.
  final Widget Function(BuildContext context, bool open, VoidCallback toggle)
      anchorBuilder;

  /// Builds the popover; call `close` to dismiss it.
  final Widget Function(BuildContext context, VoidCallback close)
      popoverBuilder;

  final ValueChanged<bool>? onOpenChanged;
  final PopoverAlignment alignment;
  final double gap;

  @override
  State<AnchoredPopover> createState() => AnchoredPopoverState();
}

/// How the popover lines up horizontally with its anchor.
enum PopoverAlignment { start, center, end }

class AnchoredPopoverState extends State<AnchoredPopover> {
  final OverlayPortalController _controller = OverlayPortalController();

  bool get isOpen => _controller.isShowing;

  void open() {
    if (isOpen) return;
    setState(_controller.show);
    widget.onOpenChanged?.call(true);
  }

  void close() {
    if (!isOpen) return;
    setState(_controller.hide);
    widget.onOpenChanged?.call(false);
  }

  void toggle() => isOpen ? close() : open();

  @override
  void dispose() {
    // Removed while open: the owner still needs to hear that it closed.
    final onOpenChanged = widget.onOpenChanged;
    if (isOpen && onOpenChanged != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => onOpenChanged(false));
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return OverlayPortal.overlayChildLayoutBuilder(
      controller: _controller,
      overlayLocation: OverlayChildLocation.rootOverlay,
      overlayChildBuilder: (context, info) {
        final anchor = MatrixUtils.transformRect(
            info.childPaintTransform, Offset.zero & info.childSize);
        return Stack(
          children: [
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: close,
              ),
            ),
            Positioned.fill(
              child: CustomSingleChildLayout(
                delegate: _PopoverLayout(
                  anchor: anchor,
                  alignment: widget.alignment,
                  gap: widget.gap,
                  padding: MediaQuery.paddingOf(context),
                ),
                child: CallbackShortcuts(
                  bindings: {
                    const SingleActivator(LogicalKeyboardKey.escape): close,
                  },
                  child: FocusScope(
                    autofocus: true,
                    child: widget.popoverBuilder(context, close),
                  ),
                ),
              ),
            ),
          ],
        );
      },
      child: widget.anchorBuilder(context, isOpen, toggle),
    );
  }
}

class _PopoverLayout extends SingleChildLayoutDelegate {
  static const double margin = 8;

  final Rect anchor;
  final PopoverAlignment alignment;
  final double gap;
  final EdgeInsets padding;

  _PopoverLayout({
    required this.anchor,
    required this.alignment,
    required this.gap,
    required this.padding,
  });

  Rect _safe(Size size) =>
      padding.deflateRect(Offset.zero & size).deflate(margin);

  double _spaceAbove(Size size) => anchor.top - gap - _safe(size).top;
  double _spaceBelow(Size size) => _safe(size).bottom - anchor.bottom - gap;

  @override
  BoxConstraints getConstraintsForChild(BoxConstraints constraints) {
    final size = constraints.biggest;
    final safe = _safe(size);
    final height = _spaceAbove(size) >= _spaceBelow(size)
        ? _spaceAbove(size)
        : _spaceBelow(size);
    return BoxConstraints.loose(Size(
        safe.width.clamp(0, double.infinity), height.clamp(0, safe.height)));
  }

  @override
  Offset getPositionForChild(Size size, Size childSize) {
    final safe = _safe(size);
    final above = childSize.height <= _spaceAbove(size) ||
        _spaceAbove(size) >= _spaceBelow(size);
    final y = above ? anchor.top - gap - childSize.height : anchor.bottom + gap;
    final x = switch (alignment) {
      PopoverAlignment.start => anchor.left,
      PopoverAlignment.center => anchor.center.dx - childSize.width / 2,
      PopoverAlignment.end => anchor.right - childSize.width,
    };
    final maxX =
        (safe.right - childSize.width).clamp(safe.left, double.infinity);
    final maxY =
        (safe.bottom - childSize.height).clamp(safe.top, double.infinity);
    return Offset(x.clamp(safe.left, maxX), y.clamp(safe.top, maxY));
  }

  @override
  bool shouldRelayout(_PopoverLayout oldDelegate) =>
      anchor != oldDelegate.anchor ||
      alignment != oldDelegate.alignment ||
      gap != oldDelegate.gap ||
      padding != oldDelegate.padding;
}
