import 'package:desktop_drop/desktop_drop.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:tiamat/tiamat.dart' as tiamat;

class DragDropFileTarget extends StatefulWidget {
  const DragDropFileTarget({super.key, this.onDropComplete});
  final Function(DropDoneDetails details)? onDropComplete;
  @override
  State<DragDropFileTarget> createState() => _DragDropFileTargetState();
}

class _DragDropFileTargetState extends State<DragDropFileTarget> {
  bool isFileHovered = false;

  String get fileDragDropPrompt => Intl.message("Drop a file to upload...",
      desc: "Text that is shown when a user is dragging a file");

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: DropTarget(
          onDragEntered: (_) {
            setState(() {
              isFileHovered = true;
            });
          },
          onDragExited: (_) {
            setState(() {
              isFileHovered = false;
            });
          },
          onDragDone: (detail) => widget.onDropComplete?.call(detail),
          child: Stack(
            children: [
              AnimatedOpacity(
                duration: const Duration(milliseconds: 500),
                curve: Curves.easeOutExpo,
                opacity: isFileHovered ? 0.5 : 0,
                child: Container(color: Colors.black),
              ),
              AnimatedOpacity(
                duration: const Duration(milliseconds: 500),
                curve: Curves.easeOutExpo,
                opacity: isFileHovered ? 1 : 0,
                child: Align(
                    alignment: Alignment.center,
                    child: tiamat.Text.largeTitle(fileDragDropPrompt)),
              ),
            ],
          )),
    );
  }
}
