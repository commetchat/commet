import 'package:commet/config/preferences/string_list_preference.dart';
import 'package:commet/ui/navigation/adaptive_dialog.dart';
import 'package:flutter/material.dart';

import 'package:tiamat/tiamat.dart' as tiamat;

class StringListPreferenceEditor extends StatefulWidget {
  const StringListPreferenceEditor(
      {required this.preference,
      required this.title,
      this.description,
      super.key});
  final StringListPreference preference;

  final String title;
  final String? description;

  @override
  State<StringListPreferenceEditor> createState() =>
      _StringListPreferenceEditorState();
}

class _StringListPreferenceEditorState
    extends State<StringListPreferenceEditor> {
  late List<String> items;

  @override
  void initState() {
    items = widget.preference.value;
    super.initState();
  }

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
                Padding(
                  padding: const EdgeInsets.fromLTRB(0, 8, 0, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (items.isEmpty)
                        SizedBox(
                          height: 50,
                          child:
                              Center(child: tiamat.Text.labelLow("No Entries")),
                        ),
                      if (items.isNotEmpty)
                        Column(
                          spacing: 8,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: items
                              .map((i) => Row(
                                    spacing: 8,
                                    children: [
                                      tiamat.IconButton(
                                        size: 18,
                                        icon: Icons.delete,
                                        onPressed: () async {
                                          if (await AdaptiveDialog.confirmation(
                                                  context) ==
                                              true) {
                                            widget.preference.remove(i);

                                            setState(() {
                                              items = widget.preference.value;
                                            });
                                          }
                                        },
                                      ),
                                      tiamat.Text.labelLow(i),
                                    ],
                                  ))
                              .toList(),
                        ),
                    ],
                  ),
                )
              ],
            )));
  }
}
