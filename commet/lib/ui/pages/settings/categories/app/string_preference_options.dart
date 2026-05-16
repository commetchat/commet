import 'package:commet/config/preferences/string_preference.dart';
import 'package:flutter/material.dart';

import 'package:tiamat/tiamat.dart' as tiamat;

class StringPreferenceOptionsPicker extends StatefulWidget {
  const StringPreferenceOptionsPicker(
      {required this.preference,
      required this.title,
      this.description,
      this.onChanged,
      required this.options,
      super.key});

  final StringPreference preference;
  final Function(bool)? onChanged;

  final String title;
  final String? description;
  final List<String> options;

  @override
  State<StringPreferenceOptionsPicker> createState() =>
      _StringPreferenceOptionsPickerState();
}

class _StringPreferenceOptionsPickerState
    extends State<StringPreferenceOptionsPicker> {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
          color: ColorScheme.of(context).surfaceContainer.withAlpha(100),
          border: BoxBorder.all(
              color: ColorScheme.of(context).secondary.withAlpha(20)),
          borderRadius: BorderRadius.circular(8)),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            tiamat.Text(widget.title),
            if (widget.description != null)
              tiamat.Text.labelLow(widget.description!),
            SizedBox(
              height: 8,
            ),
            tiamat.DropdownSelector(
                color: ColorScheme.of(context).surfaceContainerLow,
                items: widget.options,
                itemBuilder: (item) {
                  return tiamat.Text(item);
                },
                onItemSelected: (item) {
                  setState(() {
                    if (item != null) {
                      widget.preference.set(item);
                    }
                  });
                },
                value: widget.preference.value)
          ],
        ),
      ),
    );
  }
}
