import 'package:commet/config/layout_config.dart';
import 'package:flutter/material.dart';
import 'package:tiamat/tiamat.dart' as tiamat;

class AdaptiveContextMenu extends StatelessWidget {
  const AdaptiveContextMenu(
      {required this.items, required this.child, super.key});
  final List<tiamat.ContextMenuItem> items;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return child;
    }

    if (Layout.desktop) {
      return tiamat.ContextMenu(child: child, items: items);
    } else {
      return InkWell(
        child: child,
        onLongPress: () => showModalBottomSheet(
            isDismissible: true,
            showDragHandle: true,
            context: context,
            builder: (modalContext) => Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: items
                        .map((item) => SizedBox(
                              height: 50,
                              child: tiamat.TextButton(
                                item.text,
                                icon: item.icon,
                                onTap: () {
                                  item.onPressed?.call();
                                  Navigator.of(modalContext).pop();
                                },
                              ),
                            ))
                        .toList(),
                  ),
                )),
      );
    }
  }
}
