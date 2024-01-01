import 'package:flutter/material.dart';
import 'package:tiamat/atoms/seperator.dart';
import 'package:tiamat/atoms/text.dart';
import 'package:tiamat/tiamat.dart' as tiamat;
import 'package:widgetbook_annotation/widgetbook_annotation.dart';

@UseCase(name: "Context Menu", type: ContextMenu)
Widget wbContextMenu(BuildContext context) {
  return const Center(
      child: Padding(
          padding: EdgeInsets.all(8.0),
          // TODO: generally any widget can be passed through which is a no-no in this use case
          child: ContextMenu(
            items: [
              ContextMenuItem(
                text: "Add Reaction",
                icon: Icons.add_reaction_rounded,
                danger: false,
              ),
              ContextMenuItem(
                text: "Copy Text",
                icon: Icons.copy_rounded,
                danger: false,
              ),
              Seperator(),
              ContextMenuItem(
                  text: "Delete Message", danger: true, icon: Icons.delete),
            ],
          )));
}

class ContextMenu extends StatefulWidget {
  const ContextMenu({super.key, this.separator, required this.items});

  final Seperator? separator;
  final List<Widget> items; //TODO: this could afford a better name

  @override
  State<ContextMenu> createState() => _ContextMenuState();
}

class _ContextMenuState extends State<ContextMenu> {
  @override
  Widget build(BuildContext context) {
    return UnconstrainedBox(
      child: tiamat.Tile.low1(
        child: Column(
          children: widget.items,
        ),
      ),
    );
  }
}

class ContextMenuItem extends StatefulWidget {
  const ContextMenuItem(
      {required this.text,
      this.onPressed,
      this.icon,
      required this.danger,
      super.key});

  final String text;
  final Function? onPressed;
  final IconData? icon;
  final bool danger;

  @override
  State<StatefulWidget> createState() => _ContextMenuItemState();
}

class _ContextMenuItemState extends State<ContextMenuItem> {
  bool hovered = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(0, 4, 0, 4),
      // color: hovered ? Theme.of(context).colorScheme.onPrimary : null, //TODO: Revist this for coming with a more subtle hover color
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: GestureDetector(
          onTap: () => widget.onPressed?.call(),
          child: MouseRegion(
              onEnter: (event) {
                setState(() {
                  hovered = true;
                });
              },
              onExit: (event) {
                setState(() {
                  hovered = false;
                });
              },
              child: SizedBox(
                width: 250,
                height: 25,
                child: Wrap(
                  alignment: WrapAlignment.spaceBetween,
                  children: [
                    tiamat.Text(
                      type: widget.danger ? TextType.error : TextType.label,
                      widget.text,
                      maxLines: 1,
                    ),
                    Icon(
                      widget.icon,
                      color: widget.danger ? Colors.red : Colors.grey,
                    )
                  ],
                ),
              ))),
    );
  }
}
