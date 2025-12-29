import 'dart:math';
import 'dart:ui';

import 'package:calendar_view/calendar_view.dart';
import 'package:commet_calendar_widget/rfc8984.dart';
import 'package:commet_calendar_widget/utils.dart';
import 'package:flutter/material.dart';
import 'package:matrix_widget_api/capabilities.dart';
import 'package:matrix_widget_api/matrix_widget_api.dart';
import 'package:matrix_widget_api/types.dart';
import 'package:tiamat/tiamat.dart' as tiamat;
import 'package:uuid/uuid.dart';

import 'package:timezone/standalone.dart' as tz;

class MatrixCalendarEventState {
  RFC8984CalendarEvent data;
  bool loaded = false;
  String? senderId;
  String? remoteSourceId;
  String? type;

  bool get isUnavailability => type == "unavailability";

  MatrixCalendarEventState({this.senderId, required this.data, this.type});
}

class MatrixCalendarConfig {
  Color getColorFromUser(String userId) {
    return Utils.hashColor(userId);
  }

  Color processEventColor(Color color, BuildContext context) {
    return tiamat.Text.adjustColor(context, color, saturationMultiplier: 0.5);
  }

  Color processEventTextColor(Color color, BuildContext context) {
    var hsl = HSLColor.fromColor(color);
    double lightness = hsl.lightness;
    double saturation = hsl.saturation;
    if (Theme.of(context).brightness == Brightness.dark) {
      saturation = clampDouble(hsl.saturation * 2, 0, 1);
      lightness = clampDouble(hsl.lightness, 0, 0.1);
    } else {
      lightness = clampDouble(hsl.lightness, 0.99, 1.0);
      saturation = saturation * 0.1;
    }

    return HSLColor.fromAHSL(
      hsl.alpha,
      hsl.hue,
      saturation,
      lightness,
    ).toColor();
  }

  Future<T?> dialog<T>({
    required BuildContext context,
    required Widget Function(BuildContext) builder,
  }) {
    return showDialog<T>(
      context: context,
      builder: (context) {
        return AlertDialog(content: builder(context));
      },
    );
  }

  DateTime convertToLocalTime(DateTime time, String? timezone) {
    var localTimezone = DateTime.now().timeZoneName;

    if (time.isUtc) {
      return time.toLocal();
    }

    if (timezone == null || timezone == localTimezone) {
      return time;
    }

    var tztime = tz.TZDateTime(
      tz.getLocation(timezone),
      time.year,
      time.month,
      time.day,
      time.hour,
      time.minute,
      time.second,
      time.millisecond,
      time.microsecond,
    );
    var utc = tztime.toUtc();

    var local = utc.native.toLocal();
    return local;
  }

  ImageProvider? getUserAvatar(String userId) {
    return null;
  }

  String? getUserDisplayname(String userId) {
    return userId.split("@")[1].split(":").first;
  }

  const MatrixCalendarConfig();
}

class MatrixCalendar {
  final MatrixWidgetApi widgetApi;

  late EventController<MatrixCalendarEventState> controller;

  Map<String, Map<String, dynamic>> roomState = {};

  MatrixCalendarConfig config;

  MatrixCalendar(this.widgetApi, {this.config = const MatrixCalendarConfig()}) {
    this.controller = EventController();

    widgetApi.onReady.listen(onWidgetReady);

    widgetApi.onAction(
        ToWidgetAction.updateState,
        preventDefaultHandler: true,
        onStateUpdated);
  }

  Map<String, dynamic>? onStateUpdated(Map<String, dynamic> update) {
    var states = Map<String, dynamic>.from(update);
    var data = states['data'];
    var stateEvents = data['state'];

    for (var stateEvent in stateEvents) {
      var event = Map<String, dynamic>.from(stateEvent);

      var type = event['type'];

      print("CalendarWidget: received ${type} state event");
      var stateKey = event['state_key'] ?? "";
      if (!roomState.containsKey(type)) {
        roomState[type] = {};
      }

      roomState[type]![stateKey] = event;
    }

    updateFromRoomState();
    return null;
  }

  bool canEditEvent(MatrixCalendarEventState event) {
    if (event.remoteSourceId != null) {
      return false;
    }

    if (event.senderId != widgetApi.userId) {
      return false;
    }

    return true;
  }

  void onWidgetReady(void event) {
    widgetApi.requestCapabilities([
      MatrixCapability.getRoomState(
        "chat.commet.calendar_event",
        //stateKey: userId,
      ),
      MatrixCapability.setRoomState(
        "chat.commet.calendar_event",
        stateKey: widgetApi.userId,
      ),
    ]);
  }

  void updateFromRoomState() {
    var states = roomState["chat.commet.calendar_event"];
    var events = controller.allEvents.toList();
    controller.removeAll(events);

    for (var entry in states!.entries) {
      try {
        var events = Map<String, dynamic>.from(
          entry.value["content"]["events"],
        );
        var sender = entry.value["sender"];
        for (var key in events.keys) {
          var event = events[key];
          var data = Map<String, dynamic>.from(event);
          try {
            var rfc8984Event = Map<String, dynamic>.from(data["event"]);
            var remoteSource = data["remote_source_id"];
            var eventType = data["type"];
            var mxCalendarEvent = RFC8984CalendarEvent.fromJson(rfc8984Event);

            var color = config.getColorFromUser(sender);
            var calendarEvents =
                fromRfcEvent(mxCalendarEvent, eventType: eventType);
            for (var calendarEvent in calendarEvents) {
              calendarEvent = calendarEvent.copyWith(color: color);
              calendarEvent.event!.senderId = sender;
              calendarEvent.event!.loaded = true;
              calendarEvent.event!.remoteSourceId = remoteSource;
              calendarEvent.event!.type = eventType;

              controller.add(calendarEvent);
            }
          } catch (error, stack) {
            print("Failed to parse event item: ${data}, $error");
            print(stack);
          }
        }
      } catch (_) {
        print("Failed to state event: ${entry}");
      }
    }
  }

  List<MatrixCalendarEventState> getEventsOnDay(DateTime date) {
    return controller
        .getEventsOnDay(date)
        .map((e) => e.event)
        .nonNulls
        .map((e) => e)
        .toList();
  }

  // Converts an RFC8984 Calendar events to a events which can be displayed by the calendar widget
  // If an event spans multiple days, it gets split in to one event per day
  List<CalendarEventData<MatrixCalendarEventState>> fromRfcEvent(
      RFC8984CalendarEvent event,
      {String? eventType}) {
    var eventTimezone = event.timeZone;
    var localTime = config.convertToLocalTime(event.start, eventTimezone);

    bool oneOffAllDayEvent = (event.duration.inMinutes == 24 * 60 &&
        localTime.hour == 0 &&
        localTime.minute == 0);

    var endTime = localTime.add(event.duration);

    var clippedEndTime = clipToValidEndTime(localTime, endTime);

    List<CalendarEventData<MatrixCalendarEventState>> events = List.empty(
      growable: true,
    );

    var finalEvent = CalendarEventData(
      title: event.title,
      date: localTime,
      startTime: localTime,
      endTime: clippedEndTime,
      recurrenceSettings: toRecurrenceSettings(event),
      event: MatrixCalendarEventState(data: event, type: eventType),
    );

    events.add(finalEvent);

    if (oneOffAllDayEvent) {
      return events;
    }

    if (clippedEndTime != endTime) {
      while (endTime.isAfter(clippedEndTime)) {
        var startTime = clippedEndTime;

        var newClippedEndTime = clipToValidEndTime(startTime, endTime);

        events.add(
          CalendarEventData(
            title: event.title,
            date: startTime,
            startTime: startTime,
            endTime: newClippedEndTime.subtract(
              Duration(minutes: 1),
            ), // to prevent the calendar view from considering this as 'all day event'
            event: MatrixCalendarEventState(data: event, type: eventType),
          ),
        );

        if (clippedEndTime == newClippedEndTime) {
          break;
        }

        clippedEndTime = newClippedEndTime;
      }
    }

    return events;
  }

  DateTime clipToValidEndTime(DateTime startTime, DateTime endTime) {
    if (endTime.withoutTime != startTime.withoutTime) {
      return startTime.copyWith(hour: 23, minute: 59).add(Duration(minutes: 1));
    }

    return endTime;
  }

  String _generateId() {
    var uuid = const Uuid();
    var label = uuid.v4();

    return label;
  }

  Future<void> syncEvents(Map<String, List<RFC8984CalendarEvent>> events,
      {String? eventType, bool push = false}) async {
    for (var entry in events.entries) {
      var eventsToSync = entry.value;
      var remoteSourceId = entry.key;

      var existing = controller.allEvents.toList();
      for (var existingEvent in existing) {
        if (existingEvent.event?.remoteSourceId == remoteSourceId) {
          controller.remove(existingEvent);
        }
      }

      for (var event in eventsToSync) {
        var calendarEvents = fromRfcEvent(event, eventType: eventType);
        for (var calendarEvent in calendarEvents) {
          var color = config.getColorFromUser(widgetApi.userId);

          calendarEvent = calendarEvent.copyWith(color: color);
          calendarEvent.event!.senderId = widgetApi.userId;
          calendarEvent.event!.remoteSourceId = remoteSourceId;

          controller.add(calendarEvent);
        }
      }
    }

    if (push) {
      await _syncControllerEventsToRoomState();
      updateFromRoomState();
    }
  }

  Future<void> removeAllEventsFromRemoteCalendar(String id) async {
    controller.removeWhere((i) => i.event?.remoteSourceId == id);
    await _syncControllerEventsToRoomState();
  }

  Future<void> deleteEvent(RFC8984CalendarEvent event) async {
    for (var e in controller.allEvents.toList()) {
      if (e.event?.data.uid == event.uid) {
        controller.remove(e);
      }
    }
    await _syncControllerEventsToRoomState();
  }

  Future<bool> createEvent(RFC8984CalendarEvent event,
      {String? eventType}) async {
    if (event.uid == "") {
      event.uid = _generateId();
    }

    controller.removeWhere((e) => e.event?.data.uid == event.uid);

    var calendarEvents = fromRfcEvent(event, eventType: eventType);
    for (var calendarEvent in calendarEvents) {
      var color = config.getColorFromUser(widgetApi.userId);

      calendarEvent = calendarEvent.copyWith(color: color);
      calendarEvent.event!.senderId = widgetApi.userId;

      controller.add(calendarEvent);
    }

    return _syncControllerEventsToRoomState();
  }

  Future<bool> _syncControllerEventsToRoomState() async {
    var events = controller.allEvents
        .where((e) => e.event?.senderId == widgetApi.userId)
        .map((e) => e.event)
        .nonNulls
        .toList();

    events.sort((a, b) => a.data.uid.compareTo(b.data.uid));

    List<MatrixCalendarEventState> uniqueEvents = List.empty(growable: true);

    for (var event in events) {
      if (uniqueEvents.any((i) => i.data.uid == event.data.uid)) {
        continue;
      }

      uniqueEvents.add(event);
    }

    var json = {};

    for (var e in uniqueEvents) {
      var event = {
        "format": "chat.commet.calendar.event.rfc8984",
        if (e.remoteSourceId != null) "remote_source_id": e.remoteSourceId,
        if (e.type != null) "type": e.type!,
        "event": e.data.toJson(),
      };

      json[e.data.uid] = event;
    }

    var result = await widgetApi.sendAction(FromWidgetAction.sendEvent, {
      "type": "chat.commet.calendar_event",
      "state_key": widgetApi.userId,
      "content": {"events": json},
    });

    if (result.containsKey("event_id")) {
      return true;
    } else {
      return false;
    }
  }

  RecurrenceSettings? toRecurrenceSettings(RFC8984CalendarEvent event) {
    if (event.recurrenceRules == null) return null;

    var rule = event.recurrenceRules?.firstOrNull;
    if (rule == null) return null;

    var frequency = switch (rule.frequency) {
      "daily" => RepeatFrequency.daily,
      "weekly" => RepeatFrequency.weekly,
      "montly" => RepeatFrequency.monthly,
      "yearly" => RepeatFrequency.yearly,
      _ => RepeatFrequency.doNotRepeat,
    };

    if (rule.interval != null) {
      print("Calendar does not currently support repeat intervals");
      return null;
    }

    List<int>? weekdays;

    if (rule.byDay != null) {
      weekdays = List.empty(growable: true);
      for (var day in rule.byDay!) {
        var dayNum = switch (day.day) {
          "mo" => 0,
          "tu" => 1,
          "we" => 2,
          "th" => 3,
          "fr" => 4,
          "sa" => 5,
          "su" => 6,
          _ => throw UnimplementedError()
        };

        weekdays.add(dayNum);
      }
    }

    return RecurrenceSettings(
      startDate: event.start,
      occurrences: rule.count,
      frequency: frequency,
      weekdays: weekdays,
    );
  }
}
