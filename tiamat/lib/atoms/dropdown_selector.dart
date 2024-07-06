import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:flutter/material.dart';
import 'package:tiamat/atoms/text.dart';
import 'package:tiamat/config/config.dart';

import 'package:widgetbook_annotation/widgetbook_annotation.dart';
import 'package:tiamat/tiamat.dart' as tiamat;

@UseCase(name: 'String Selector', type: DropdownSelector)
Widget wbDropdownSelector(BuildContext context) {
  return tiamat.Tile.low2(
    child: Padding(
      padding: EdgeInsets.all(10.0),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: EdgeInsets.all(8.0),
              child: DropdownSelector<String>(
                items: ["Alpha", "Bravo", "Charlie", "Delta"],
                itemBuilder: (item) {
                  return Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: tiamat.Text(item),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

@UseCase(name: 'Multi Line Text', type: DropdownSelector)
Widget wbDropdownSelectorMultiLine(BuildContext context) {
  return tiamat.Tile.low2(
    child: Padding(
      padding: EdgeInsets.all(10.0),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: EdgeInsets.all(8.0),
              child: DropdownSelector<String>(
                itemHeight: 80,
                items: [loremIpsum, "Bravo", loremIpsum + " ", "Delta"],
                itemBuilder: (item) {
                  return Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: tiamat.Text(item),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

@UseCase(name: 'Avatar Selector', type: DropdownSelector)
Widget wbDropdownAvatarSelector(BuildContext context) {
  return tiamat.Tile(
    child: Padding(
      padding: EdgeInsets.all(10.0),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: EdgeInsets.all(8.0),
              child: SizedBox(
                child: DropdownSelector<ImageProvider>(
                  itemHeight: 70,
                  items: [
                    AssetImage(
                        "assets/images/placeholder/generic/checker_purple.png"),
                    AssetImage(
                        "assets/images/placeholder/generic/checker_red.png"),
                    AssetImage(
                        "assets/images/placeholder/generic/checker_green.png"),
                    AssetImage(
                        "assets/images/placeholder/generic/checker_orange.png")
                  ],
                  itemBuilder: (item) {
                    return Row(
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: tiamat.Avatar.medium(image: item),
                        ),
                        tiamat.Text.labelEmphasised("Avatar with text")
                      ],
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class DropdownSelector<T> extends StatefulWidget {
  const DropdownSelector(
      {required this.items,
      required this.itemBuilder,
      this.itemHeight = 50,
      this.onItemSelected,
      this.defaultIndex = 0,
      this.hint,
      super.key});
  final List<T> items;
  final Widget Function(T item) itemBuilder;
  final void Function(T item)? onItemSelected;
  final int? defaultIndex;
  final double itemHeight;
  final Widget? hint;

  @override
  State<DropdownSelector<T>> createState() => DropdownSelectorState<T>();
}

class DropdownSelectorState<T> extends State<DropdownSelector<T>> {
  T? value;

  @override
  void initState() {
    if (widget.defaultIndex != null) {
      value = widget.items[widget.defaultIndex!];
    }
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: Material(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: BorderSide(
              color: Theme.of(context).colorScheme.outline, width: 1.4),
        ),
        color: Colors.transparent,
        child: LayoutBuilder(
            builder: (BuildContext context, BoxConstraints constraints) {
          return DropdownButtonHideUnderline(
              child: DropdownButton2(
            menuItemStyleData: MenuItemStyleData(height: widget.itemHeight),
            value: value,
            hint: widget.hint,
            dropdownStyleData: DropdownStyleData(
                decoration: BoxDecoration(
                    borderRadius: BorderRadius.only(
                        bottomRight: Radius.circular(10),
                        bottomLeft: Radius.circular(10)),
                    color: Theme.of(context).colorScheme.surfaceContainerHigh)),
            items: widget.items.map((value) {
              return DropdownMenuItem(
                alignment: Alignment.centerLeft,
                value: value,
                child: SizedBox(
                    width: constraints.maxWidth - 60,
                    child: widget.itemBuilder(value)),
              );
            }).toList(),
            onChanged: (newValue) {
              setState(() {
                value = newValue!;
              });
              widget.onItemSelected?.call(newValue!);
            },
          ));
        }),
      ),
    );
  }
}
