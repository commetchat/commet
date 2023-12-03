import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:flutter/material.dart';
import 'package:tiamat/atoms/text.dart';
import 'package:tiamat/config/config.dart';
import 'dart:collection';
import 'package:widgetbook_annotation/widgetbook_annotation.dart';
import 'package:tiamat/tiamat.dart' as tiamat;

extension ExtendedIterable<E> on Iterable<E> {
  /// Like Iterable<T>.map but the callback has index as second argument
  Iterable<T> mapIndexed<T>(T Function(E e, int i) f) {
    var i = 0;
    return map((e) => f(e, i++));
  }
}

@UseCase(name: 'String Selector', type: DropdownTextField)
Widget wbDropdownField(BuildContext context) {
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
              child: DropdownTextField(
                items: ["Alpha", "Bravo", "Charlie", "Delta"],
                onItemSelected: (item) {
                  print("Got selection: $item");
                },
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class DropdownTextField<T> extends StatefulWidget {
  const DropdownTextField(
      {required this.items,
      this.itemHeight = 50,
      this.onItemSelected,
      this.initialValue,
      this.textEditorPlaceholder = "Enter a custom input",
      this.editableEntryPlaceholder = "Custom",
      super.key});
  final List<String> items;
  final String textEditorPlaceholder;
  final String editableEntryPlaceholder;
  final void Function(String item)? onItemSelected;
  final String? initialValue;
  final double itemHeight;

  @override
  State<DropdownTextField> createState() => DropdownTextFieldState();
}

class DropdownTextFieldState extends State<DropdownTextField> {
  late String _value;
  final TextEditingController _textEditingController = TextEditingController();
  late List<String> _items;

  String _customInput = "";

  static const String customInputValue = "CUSTOM_INPUT_VALUE";

  String get value =>
      _value == customInputValue ? _textEditingController.text : _value;

  @override
  void initState() {
    if (widget.initialValue != null) {
      _items = List.from(widget.items);
      _items.add(customInputValue);

      var index = widget.items.indexOf(widget.initialValue!);
      if (index == -1) {
        index = _items.length - 1;
        _textEditingController.text = widget.initialValue!;
      }

      _value = _items[index == -1 ? 0 : index];
    }
    _textEditingController.addListener(onTextInputChanged);
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
              color: Theme.of(context).extension<ExtraColors>()!.outline,
              width: 1.4),
        ),
        color: Colors.transparent,
        child: LayoutBuilder(
            builder: (BuildContext context, BoxConstraints constraints) {
          return DropdownButtonHideUnderline(
              child: DropdownButton2(
                  menuItemStyleData: MenuItemStyleData(
                    height: widget.itemHeight,
                  ),
                  value: _value,
                  dropdownStyleData: DropdownStyleData(
                      decoration: BoxDecoration(
                          borderRadius: const BorderRadius.only(
                              bottomRight: Radius.circular(10),
                              bottomLeft: Radius.circular(10)),
                          color: Theme.of(context)
                              .extension<ExtraColors>()!
                              .surfaceHigh1)),
                  selectedItemBuilder: (context) {
                    return _items.mapIndexed<Widget>((value, index) {
                      if (index == _items.length - 1) {
                        return DropdownMenuItem(
                          alignment: Alignment.centerLeft,
                          value: value,
                          child: SizedBox(
                              width: constraints.maxWidth - 60,
                              height: widget.itemHeight,
                              child: TextField(
                                controller: _textEditingController,
                                decoration: InputDecoration(
                                    border: InputBorder.none,
                                    hintText: widget.textEditorPlaceholder),
                              )),
                        );
                      }
                      return DropdownMenuItem(
                        alignment: Alignment.centerLeft,
                        value: value,
                        child: SizedBox(
                            width: constraints.maxWidth - 60,
                            child: tiamat.Text.label(value)),
                      );
                    }).toList();
                  },
                  items: _items
                      .mapIndexed<DropdownMenuItem<String>>((value, index) {
                    if (index == _items.length - 1) {
                      return DropdownMenuItem(
                        alignment: Alignment.centerLeft,
                        value: value,
                        child: SizedBox(
                            width: constraints.maxWidth - 60,
                            child: tiamat.Text.labelLow(_customInput != ""
                                ? _textEditingController.text
                                : widget.editableEntryPlaceholder)),
                      );
                    }
                    return DropdownMenuItem(
                      alignment: Alignment.centerLeft,
                      value: value,
                      child: SizedBox(
                          width: constraints.maxWidth - 60,
                          child: tiamat.Text.label(value)),
                    );
                  }).toList(),
                  onChanged: onChanged));
        }),
      ),
    );
  }

  void onChanged(String? newValue) {
    String readValue = newValue!;
    if (newValue == customInputValue) {
      readValue = _textEditingController.text;
    }

    widget.onItemSelected?.call(readValue);

    setState(() {
      _value = newValue;
    });
  }

  void onTextInputChanged() {
    setState(() {
      _customInput = _textEditingController.text;
    });
    if (_value == customInputValue) {
      widget.onItemSelected?.call(_textEditingController.text);
    }
  }
}
