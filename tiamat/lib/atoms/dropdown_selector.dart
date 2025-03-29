import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:flutter/material.dart';

class DropdownSelector<T> extends StatelessWidget {
  const DropdownSelector(
      {required this.items,
      required this.itemBuilder,
      this.itemHeight = 50,
      this.onItemSelected,
      this.hint,
      required this.value,
      super.key});

  final List<T> items;
  final Widget Function(T item) itemBuilder;
  final void Function(T item)? onItemSelected;
  final double itemHeight;
  final Widget? hint;

  final T value;

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
            menuItemStyleData: MenuItemStyleData(height: itemHeight),
            value: value,
            hint: hint,
            dropdownStyleData: DropdownStyleData(
                decoration: BoxDecoration(
                    borderRadius: BorderRadius.only(
                        bottomRight: Radius.circular(10),
                        bottomLeft: Radius.circular(10)),
                    color: Theme.of(context).colorScheme.surfaceContainerHigh)),
            items: items.map((value) {
              return DropdownMenuItem(
                alignment: Alignment.centerLeft,
                value: value,
                child: SizedBox(
                    width: constraints.maxWidth - 60,
                    child: itemBuilder(value)),
              );
            }).toList(),
            onChanged: (newValue) {
              onItemSelected?.call(newValue!);
            },
          ));
        }),
      ),
    );
  }
}
