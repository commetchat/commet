import 'package:flutter/widgets.dart';
import 'package:flutter/material.dart' as m;
import '../atoms/icon_button.dart' as i;

class PopupIconMenu extends StatelessWidget {
  const PopupIconMenu({super.key, this.height = 20, required this.icons});
  final double height;
  final List<MapEntry<IconData, Function>> icons;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          color: m.Theme.of(context).colorScheme.surface,
          boxShadow: [
            BoxShadow(blurRadius: 4, color: m.Theme.of(context).shadowColor)
          ]),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: icons
              .map((icon) => Padding(
                    padding: const EdgeInsets.fromLTRB(4, 0, 4, 0),
                    child: i.IconButton(
                      icon: icon.key,
                      size: height / 1.5,
                      onPressed: () {
                        icon.value.call();
                      },
                    ),
                  ))
              .toList(),
        ),
      ),
    );
  }
}
