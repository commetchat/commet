import 'package:commet_calendar_widget/rfc8984.dart';
import 'package:flutter/material.dart';

import 'package:tiamat/tiamat.dart' as tiamat;

class RecurrenceRuleEditor extends StatefulWidget {
  const RecurrenceRuleEditor({super.key, this.initialRule});
  final RFC8984RecurrenceRule? initialRule;
  @override
  State<RecurrenceRuleEditor> createState() => _RecurrenceRuleEditorState();
}

class RecurrenceRuleEditorResult {
  RFC8984RecurrenceRule? rule;

  RecurrenceRuleEditorResult(this.rule);
}

class _RecurrenceRuleEditorState extends State<RecurrenceRuleEditor> {
  late String frequency;
  Set<String> selectedDays = {};
  @override
  void initState() {
    frequency = widget.initialRule?.frequency ?? "never";
    if (widget.initialRule?.byDay != null) {
      for (var day in widget.initialRule!.byDay!) {
        selectedDays.add(day.day);
      }
    }
    super.initState();
  }

  RFC8984RecurrenceRule? get result => frequency == "never"
      ? null
      : RFC8984RecurrenceRule(
          frequency: frequency,
          byDay: frequency == "weekly" && selectedDays.isNotEmpty
              ? selectedDays.map((e) => Rfc8984NDay(e)).toList()
              : null);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 400,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          tiamat.Text.labelLow("Repeat:"),
          Padding(
            padding: const EdgeInsets.fromLTRB(0, 8, 0, 8),
            child: DropdownButtonFormField<String>(
              initialValue: frequency,
              items: [
                DropdownMenuItem(
                  child: Text("Never"),
                  value: "never",
                ),
                DropdownMenuItem(
                  child: Text("Daily"),
                  value: "daily",
                ),
                DropdownMenuItem(
                  child: Text("Weekly"),
                  value: "weekly",
                ),
                // TODO: support monthly recurrence
                // DropdownMenuItem(
                //   child: Text("Montly"),
                //   value: "monthly",
                // ),
                DropdownMenuItem(
                  child: Text("Yearly"),
                  value: "yearly",
                ),
              ],
              onChanged: (result) => setState(() {
                frequency = result as String;
              }),
            ),
          ),
          if (frequency == "weekly")
            Padding(
              padding: const EdgeInsets.fromLTRB(0, 8, 0, 8),
              child: SegmentedButton(
                emptySelectionAllowed: true,
                multiSelectionEnabled: true,
                showSelectedIcon: false,
                segments: [
                  ButtonSegment(value: "mo", label: Text("M")),
                  ButtonSegment(value: "tu", label: Text("T")),
                  ButtonSegment(value: "we", label: Text("W")),
                  ButtonSegment(value: "th", label: Text("T")),
                  ButtonSegment(value: "fr", label: Text("F")),
                  ButtonSegment(value: "sa", label: Text("S")),
                  ButtonSegment(value: "su", label: Text("S")),
                ],
                expandedInsets: EdgeInsets.all(0),
                selected: selectedDays,
                onSelectionChanged: (v) => setState(() {
                  selectedDays = v;
                }),
              ),
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(0, 20, 0, 0),
            child: Row(
              spacing: 8,
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: tiamat.Button.secondary(
                    text: "Cancel",
                    onTap: () => Navigator.of(context).pop(null),
                  ),
                ),
                Expanded(
                  child: tiamat.Button(
                    text: "Submit",
                    onTap: () => {
                      Navigator.of(context)
                          .pop(RecurrenceRuleEditorResult(result))
                    },
                  ),
                )
              ],
            ),
          )
        ],
      ),
    );
  }
}
