import 'dart:io';

import 'package:commet_calendar_widget/rfc8984.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:tiamat/tiamat.dart' as tiamat;

import 'package:intl/intl.dart' as intl;

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
  late DateTime pickedStartDate;
  late TimeOfDay pickedStartTime;

  late DateTime pickedEndDate;
  late TimeOfDay pickedEndTime;

  late bool allDayEvent;

  DateTime get startTime => allDayEvent
      ? DateTime(
          pickedStartDate.year,
          pickedStartDate.month,
          pickedEndDate.day,
        )
      : DateTime(
          pickedStartDate.year,
          pickedStartDate.month,
          pickedStartDate.day,
          pickedStartTime.hour,
          pickedStartTime.minute,
        );

  DateTime get endTime => DateTime(
        pickedEndDate.year,
        pickedEndDate.month,
        pickedEndDate.day,
        pickedEndTime.hour,
        pickedEndTime.minute,
      );

  String eventName = "";

  bool submitting = false;

  @override
  void initState() {
    var time = widget.initialEvent?.start ?? DateTime.now();
    eventName = widget.initialEvent?.title ?? "";
    pickedStartDate = time;
    pickedStartTime = TimeOfDay.fromDateTime(time);

    allDayEvent = widget.initialEvent?.duration == Duration(hours: 24) &&
        widget.initialEvent?.start.isUtc == false;

    var end = time.add(Duration(hours: 1));
    pickedEndDate = end;
    pickedEndTime = TimeOfDay.fromDateTime(end);

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    bool use24h = false;
    if (kIsWeb == false) {
      if (Platform.isAndroid || Platform.isIOS) {
        use24h = MediaQuery.of(context).alwaysUse24HourFormat;
      }
    }

    var formatter = switch (use24h) {
      true => intl.DateFormat.Hm(),
      false => intl.DateFormat.jm()
    };

    bool hasValidName = eventName.trim().isNotEmpty;

    bool isValidInput = switch (allDayEvent) {
      true => true,
      false => endTime.isAfter(startTime) && hasValidName,
    };

    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
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
          // Start Time
          SizedBox(
            width: 400,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (allDayEvent) SizedBox(width: 50, child: Text("Date:")),
                if (!allDayEvent) SizedBox(width: 50, child: Text("From:")),
                TextButton.icon(
                  onPressed: () => showDatePicker(
                    context: context,
                    firstDate: DateTime.fromMicrosecondsSinceEpoch(0),
                    lastDate: DateTime(2100),
                    initialDate: pickedStartDate,
                  ).then(
                    (v) => setState(() {
                      pickedStartDate = v ?? pickedStartDate;
                    }),
                  ),
                  label: Text(
                    DateFormat(
                      DateFormat.YEAR_MONTH_WEEKDAY_DAY,
                    ).format(pickedStartDate),
                  ),
                ),
                if (!allDayEvent)
                  TextButton.icon(
                    onPressed: () => showTimePicker(
                      context: context,
                      builder: (context, child) {
                        return MediaQuery(
                          data: MediaQuery.of(context)
                              .copyWith(alwaysUse24HourFormat: use24h),
                          child: child!,
                        );
                      },
                      initialTime: pickedStartTime,
                    ).then(
                      (result) => setState(() {
                        pickedStartTime = result ?? pickedStartTime;
                      }),
                    ),
                    label: Text(formatter.format(startTime)),
                  ),
              ],
            ),
          ),
          // End Time
          if (!allDayEvent)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                SizedBox(width: 50, child: Text("To:")),
                TextButton.icon(
                  onPressed: () => showDatePicker(
                    context: context,
                    firstDate: DateTime.fromMicrosecondsSinceEpoch(0),
                    lastDate: DateTime(2100),
                    initialDate: pickedEndDate,
                  ).then(
                    (v) => setState(() {
                      pickedEndDate = v ?? pickedEndDate;
                    }),
                  ),
                  label: Text(
                    DateFormat(
                      DateFormat.YEAR_MONTH_WEEKDAY_DAY,
                    ).format(pickedEndDate),
                  ),
                ),
                TextButton.icon(
                  onPressed: () => showTimePicker(
                    context: context,
                    builder: (context, child) {
                      return MediaQuery(
                        data: MediaQuery.of(context)
                            .copyWith(alwaysUse24HourFormat: use24h),
                        child: child!,
                      );
                    },
                    initialTime: pickedEndTime,
                  ).then(
                    (result) => setState(() {
                      pickedEndTime = result ?? pickedEndTime;
                    }),
                  ),
                  label: Text(formatter.format(endTime)),
                ),
              ],
            ),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("All Day: "),
              tiamat.Switch(
                state: allDayEvent,
                onChanged: (value) => setState(() {
                  allDayEvent = value;
                }),
              )
            ],
          ),

          if (startTime.isAfter(endTime))
            tiamat.Text.error("End time must be after start time"),

          if (!hasValidName) tiamat.Text.error("Event must have a name"),
          IgnorePointer(
            ignoring: !isValidInput,
            child: Opacity(
              opacity: isValidInput ? 1.0 : 0.3,
              child: Padding(
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
                          var duration = switch (allDayEvent) {
                            true => Duration(hours: 24),
                            false => endTime.difference(startTime)
                          };

                          var start = switch (allDayEvent) {
                            true => startTime.toLocal(),
                            false => startTime.toUtc(),
                          };

                          var event = RFC8984CalendarEvent(
                            uid: widget.initialEvent?.uid ?? "",
                            updated: DateTime.now().toUtc(),
                            title: eventName,
                            start: start.toUtc(),
                            duration: duration,
                          );

                          setState(() {
                            submitting = true;
                          });

                          try {
                            var succeeded =
                                await widget.createEvent(event).timeout(
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
            ),
          ),
        ],
      ),
    );
  }
}
