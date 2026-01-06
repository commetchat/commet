import 'package:commet/config/layout_config.dart';
import 'package:commet/ui/atoms/scaled_safe_area.dart';
import 'package:flutter/material.dart';
import 'package:tiamat/tiamat.dart' as tiamat;

class AdaptiveContextMenu extends StatelessWidget {
  const AdaptiveContextMenu(
      {required this.items,
      this.modal = false,
      required this.child,
      super.key});
  final List<tiamat.ContextMenuItem> items;
  final Widget child;
  final bool modal;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return child;
    }

    if (Layout.desktop) {
      return tiamat.ContextMenu(
        child: child,
        items: items,
        modal: modal,
      );
    } else {
      var callback = () => showModalBottomSheet(
          isDismissible: true,
          showDragHandle: true,
          context: context,
          builder: (modalContext) => ScaledSafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    spacing: 4,
                    mainAxisSize: MainAxisSize.min,
                    children: items
                        .map((item) => SizedBox(
                              height: 50,
                              child: tiamat.TextButton(
                                item.text,
                                textColor:
                                    Theme.of(context).colorScheme.onSurface,
                                icon: item.icon,
                                onTap: () {
                                  Navigator.of(modalContext).pop();
                                  item.onPressed?.call();
                                },
                              ),
                            ))
                        .toList(),
                  ),
                ),
              ));

      return InkWell(
        child: child,
        onLongPress: modal ? null : callback,
        onTap: modal ? callback : null,
      );
    }
  }
}
