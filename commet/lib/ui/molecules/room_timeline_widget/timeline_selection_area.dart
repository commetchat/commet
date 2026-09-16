import 'package:flutter/material.dart';

/// Tracks the text the user has selected with the mouse inside a timeline, so
/// actions such as the message menu's "Copy" can copy just that fragment.
class TimelineTextSelection {
  String _selectedText = "";

  /// The text to copy for a message whose full body is [fullText]: the
  /// current selection when there is one, otherwise the whole body.
  String textToCopy(String fullText) =>
      _selectedText.isEmpty ? fullText : _selectedText;

  /// The selection of the nearest enclosing [TimelineSelectionArea], if any.
  ///
  /// Look this up when building a menu, not when running its action: menus
  /// live in an overlay, outside the timeline.
  static TimelineTextSelection? maybeOf(BuildContext context) => context
      .getInheritedWidgetOfExactType<_TimelineSelectionScope>()
      ?.selection;
}

/// Makes the text of a timeline selectable with the mouse and exposes the
/// selection to descendants through [TimelineTextSelection.maybeOf].
class TimelineSelectionArea extends StatefulWidget {
  const TimelineSelectionArea({required this.child, super.key});
  final Widget child;

  @override
  State<TimelineSelectionArea> createState() => _TimelineSelectionAreaState();
}

class _TimelineSelectionAreaState extends State<TimelineSelectionArea> {
  final TimelineTextSelection selection = TimelineTextSelection();

  @override
  Widget build(BuildContext context) {
    return SelectionArea(
      onSelectionChanged: (content) =>
          selection._selectedText = content?.plainText ?? "",
      // Right clicks are handled by each event's own context menu, which
      // copies the selection. A toolbar here would open a second menu.
      contextMenuBuilder: (context, selectableRegionState) => Container(),
      child: _TimelineSelectionScope(selection: selection, child: widget.child),
    );
  }
}

class _TimelineSelectionScope extends InheritedWidget {
  const _TimelineSelectionScope(
      {required this.selection, required super.child});
  final TimelineTextSelection selection;

  @override
  bool updateShouldNotify(_TimelineSelectionScope oldWidget) =>
      selection != oldWidget.selection;
}
