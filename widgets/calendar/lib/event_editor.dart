import 'package:commet_calendar_widget/rfc8984.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:tiamat/tiamat.dart' as tiamat;

class CalendarEventEditor extends StatefulWidget {
  const CalendarEventEditor({
    this.initialEvent,
    required this.createEvent,
    super.key,
  });
  final RFC8984CalendarEvent? initialEvent;
  final Future<bool> Function(RFC8984CalendarEvent event) createEvent;

  @override
  State<CalendarEventEditor> createState() => _CalendarEventEditorState();
}

class _CalendarEventEditorState extends State<CalendarEventEditor> {
  late DateTime pickedDate;
  late TimeOfDay pickedTime;

  String eventName = "";

  bool submitting = false;

  @override
  void initState() {
    var time = widget.initialEvent?.start ?? DateTime.now();
    eventName = widget.initialEvent?.title ?? "";
    pickedDate = time;
    pickedTime = TimeOfDay.fromDateTime(time);

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextFormField(
              initialValue: eventName,
              decoration: const InputDecoration(
                border: UnderlineInputBorder(),
                labelText: 'Event Name',
              ),
              onChanged: (value) => setState(() {
                eventName = value;
              }),
            ),
          ),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              TextButton.icon(
                onPressed: () =>
                    showDatePicker(
                      context: context,
                      firstDate: DateTime.fromMicrosecondsSinceEpoch(0),
                      lastDate: DateTime(2100),
                      initialDate: pickedDate,
                    ).then(
                      (v) => setState(() {
                        pickedDate = v ?? pickedDate;
                      }),
                    ),
                label: Text(
                  DateFormat(
                    DateFormat.YEAR_MONTH_WEEKDAY_DAY,
                  ).format(pickedDate),
                ),
              ),
              TextButton.icon(
                onPressed: () =>
                    showTimePicker(
                      context: context,
                      initialTime: pickedTime,
                    ).then(
                      (result) => setState(() {
                        pickedTime = result ?? pickedTime;
                      }),
                    ),
                label: Text(pickedTime.format(context)),
              ),
            ],
          ),

          Padding(
            padding: const EdgeInsets.fromLTRB(0, 12, 0, 0),
            child: Row(
              spacing: 8,
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: tiamat.Button.secondary(
                    text: "Cancel",
                    onTap: () {
                      Navigator.of(context).pop();
                    },
                  ),
                ),
                Expanded(
                  child: tiamat.Button(
                    text: "Submit",
                    isLoading: submitting,
                    onTap: () async {
                      var event = RFC8984CalendarEvent(
                        uid: widget.initialEvent?.uid ?? "",
                        updated: DateTime.now().toUtc(),
                        title: eventName,
                        start: DateTime(
                          pickedDate.year,
                          pickedDate.month,
                          pickedDate.day,
                          pickedTime.hour,
                          pickedTime.minute,
                        ).toUtc(),
                        duration: Duration(hours: 1),
                      );

                      setState(() {
                        submitting = true;
                      });

                      try {
                        var succeeded = await widget
                            .createEvent(event)
                            .timeout(
                              Duration(seconds: 10),
                              onTimeout: () async {
                                setState(() {
                                  submitting = false;
                                });

                                return false;
                              },
                            );

                        if (succeeded == true) {
                          Navigator.of(context).pop(true);
                        } else {
                          setState(() {
                            submitting = false;
                          });
                        }
                      } catch (_) {
                        setState(() {
                          submitting = false;
                        });
                      }
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
