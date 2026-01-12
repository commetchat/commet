import 'dart:io';

import 'package:commet_calendar_widget/calendar.dart';
import 'package:commet_calendar_widget/recurrence_editor.dart';
import 'package:commet_calendar_widget/rfc8984.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:intl/intl.dart';
import 'package:tiamat/tiamat.dart' as tiamat;

import 'package:intl/intl.dart' as intl;

class CalendarEventEditor extends StatefulWidget {
  const CalendarEventEditor({
    this.initialEvent,
    required this.submitEvent,
    required this.config,
    required this.editingExistingEvent,
    this.deleteEvent,
    this.eventType,
    super.key,
  });
  final RFC8984CalendarEvent? initialEvent;
  final MatrixCalendarConfig config;
  final String? eventType;
  final bool editingExistingEvent;
  final Future<bool> Function(RFC8984CalendarEvent event, {String? eventType})
      submitEvent;
  final Future<void> Function(RFC8984CalendarEvent event)? deleteEvent;

  @override
  State<CalendarEventEditor> createState() => _CalendarEventEditorState();
}

class _CalendarEventEditorState extends State<CalendarEventEditor> {
  late DateTime pickedStartDate;
  late TimeOfDay pickedStartTime;

  late DateTime pickedEndDate;
  late TimeOfDay pickedEndTime;

  String? timezone;

  RFC8984RecurrenceRule? recurrenceRule;

  late bool allDayEvent;

  String eventType = "event";

  bool get requiresTimezone =>
      !allDayEvent &&
      (recurrenceRule != null && recurrenceRule?.frequency != "yearly");

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
    time =
        widget.config.convertToLocalTime(time, widget.initialEvent?.timeZone);
    eventName = widget.initialEvent?.title ?? "";
    pickedStartDate = time;
    pickedStartTime = TimeOfDay.fromDateTime(time);
    timezone = widget.initialEvent?.timeZone;
    if (widget.eventType != null) {
      eventType = widget.eventType!;
    }
    recurrenceRule = widget.initialEvent?.recurrenceRules?.firstOrNull;

    if (timezone == null) {
      FlutterTimezone.getLocalTimezone().then((info) => setState(() {
            timezone = info.identifier;
          }));
    }

    allDayEvent = widget.initialEvent?.duration == Duration(hours: 24) &&
        widget.initialEvent?.start.isUtc == false;

    var end = time.add(widget.initialEvent?.duration ?? Duration(hours: 1));
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

    bool isValidInput = hasValidName;

    if (!allDayEvent) {
      isValidInput &= endTime.isAfter(startTime);
    }

    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(0, 8, 8, 8),
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
          SegmentedButton(
            emptySelectionAllowed: true,
            multiSelectionEnabled: false,
            showSelectedIcon: false,
            segments: [
              ButtonSegment(
                  value: "event",
                  label: tiamat.Text.labelEmphasised(
                    "Event",
                  )),
              ButtonSegment(
                  value: "unavailability",
                  label: tiamat.Text.labelEmphasised("Unavailability")),
            ],
            expandedInsets: EdgeInsets.all(0),
            selected: {eventType},
            onSelectionChanged: (a) => setState(() {
              eventType = a.first;
            }),
          ),
          // Start Time
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (allDayEvent) tiamat.Text.label("Date:"),
              if (!allDayEvent) tiamat.Text.label("From:"),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
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
                    label: tiamat.Text.labelEmphasised(
                      color: ColorScheme.of(context).primary,
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
                      label: SizedBox(
                          width: 65,
                          child: Align(
                              alignment: AlignmentGeometry.centerRight,
                              child: tiamat.Text.labelEmphasised(
                                  color: ColorScheme.of(context).primary,
                                  formatter.format(startTime)))),
                    ),
                ],
              )
            ],
          ),
          // End Time
          if (!allDayEvent)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("To:"),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
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
                      label: tiamat.Text.labelEmphasised(
                        color: ColorScheme.of(context).primary,
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
                      label: SizedBox(
                          width: 65,
                          child: Align(
                              alignment: AlignmentGeometry.centerRight,
                              child: tiamat.Text.labelEmphasised(
                                  color: ColorScheme.of(context).primary,
                                  formatter.format(endTime)))),
                    ),
                  ],
                ),
              ],
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(0, 8, 0, 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("Repeat:"),
                TextButton.icon(
                    onPressed: () {
                      widget.config
                          .dialog<RecurrenceRuleEditorResult?>(
                        context: context,
                        builder: (context) => RecurrenceRuleEditor(
                          initialRule: recurrenceRule,
                        ),
                      )
                          .then((result) {
                        if (result != null) {
                          setState(() {
                            recurrenceRule = result.rule;
                          });
                        }
                      });
                    },
                    label: tiamat.Text.labelEmphasised(
                        color: ColorScheme.of(context).primary,
                        recurrenceRule == null
                            ? "Never Repeats"
                            : recurrenceRule!.toString())),
              ],
            ),
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

          if (requiresTimezone && timezone != null)
            tiamat.Tooltip(
              child: tiamat.Text.labelLow(timezone!),
              text:
                  "A timezone is required when an event repeats more than once a year, and is not an all-day event",
            ),

          if (startTime.isAfter(endTime))
            tiamat.Text.error("End time must be after start time"),

          if (!hasValidName) tiamat.Text.error("Event must have a name"),
          Padding(
            padding: const EdgeInsets.fromLTRB(0, 12, 0, 0),
            child: Row(
              spacing: 8,
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (widget.editingExistingEvent && widget.deleteEvent != null)
                  Expanded(
                    child: tiamat.Button.danger(
                      text: "Delete",
                      onTap: () {
                        widget.deleteEvent
                            ?.call(widget.initialEvent!)
                            .then((_) {
                          Navigator.of(context).pop();
                        });
                      },
                    ),
                  ),
                Expanded(
                  child: tiamat.Button.secondary(
                    text: "Cancel",
                    onTap: () {
                      Navigator.of(context).pop();
                    },
                  ),
                ),
                Expanded(
                  child: IgnorePointer(
                    ignoring: !isValidInput,
                    child: Opacity(
                      opacity: isValidInput ? 1.0 : 0.3,
                      child: tiamat.Button(
                        text: "Submit",
                        isLoading: submitting,
                        onTap: () async {
                          var duration = switch (allDayEvent) {
                            true => Duration(hours: 24),
                            false => endTime.difference(startTime)
                          };

                          var start = switch (allDayEvent) {
                            true => DateTime(
                                startTime.year, startTime.month, startTime.day),
                            false => requiresTimezone
                                ? startTime.toLocal()
                                : startTime.toUtc(),
                          };

                          var tz = requiresTimezone ? timezone : null;

                          var event = RFC8984CalendarEvent(
                            uid: widget.initialEvent?.uid ?? "",
                            updated: DateTime.now().toUtc(),
                            title: eventName,
                            timeZone: tz,
                            recurrenceRules: recurrenceRule != null
                                ? [recurrenceRule!]
                                : null,
                            start: start,
                            duration: duration,
                          );

                          setState(() {
                            submitting = true;
                          });

                          try {
                            var succeeded = await widget
                                .submitEvent(event, eventType: eventType)
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
