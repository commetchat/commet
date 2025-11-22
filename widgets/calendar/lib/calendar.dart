import 'dart:convert';
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

class MatrixCalendarEventState {
  RFC8984CalendarEvent data;
  bool loaded = false;
  String? senderId;
  String? remoteSourceId;
  String? type;

  MatrixCalendarEventState({this.senderId, required this.data});
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
      (update) {
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
      },
    );
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
        var events = entry.value["content"]["events"];
        var sender = entry.value["sender"];
        for (var event in events) {
          var data = Map<String, dynamic>.from(event);
          try {
            var rfc8984Event = data["event"];
            var remoteSource = data["remote_source_id"];
            var eventType = data["type"];
            var mxCalendarEvent = RFC8984CalendarEvent.fromJson(rfc8984Event);

            var color = config.getColorFromUser(sender);
            var calendarEvents = fromRfcEvent(mxCalendarEvent);
            for (var calendarEvent in calendarEvents) {
              calendarEvent = calendarEvent.copyWith(color: color);
              calendarEvent.event!.senderId = sender;
              calendarEvent.event!.loaded = true;
              calendarEvent.event!.remoteSourceId = remoteSource;
              calendarEvent.event!.type = eventType;

              controller.add(calendarEvent);
            }
          } catch (error) {
            print("Failed to parse event item: ${data}, $error");
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
  ) {
    var localTime = event.start.toLocal();

    bool oneOffAllDayEvent =
        (event.duration.inMinutes == 24 * 60 &&
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
      event: MatrixCalendarEventState(data: event),
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
            event: MatrixCalendarEventState(data: event),
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
    const _chars =
        'AaBbCcDdEeFfGgHhIiJjKkLlMmNnOoPpQqRrSsTtUuVvWwXxYyZz1234567890';
    Random _rnd = Random();

    return String.fromCharCodes(
      Iterable.generate(
        20,
        (_) => _chars.codeUnitAt(_rnd.nextInt(_chars.length)),
      ),
    );
  }

  Future<void> syncEvents(
    Map<String, List<RFC8984CalendarEvent>> events,
  ) async {
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
        var calendarEvents = fromRfcEvent(event);
        for (var calendarEvent in calendarEvents) {
          var color = config.getColorFromUser(widgetApi.userId);

          calendarEvent = calendarEvent.copyWith(color: color);
          calendarEvent.event!.senderId = widgetApi.userId;
          calendarEvent.event!.remoteSourceId = remoteSourceId;
          calendarEvent.event!.type = "event";

          controller.add(calendarEvent);
        }
      }
    }

    await _syncControllerEventsToRoomState();

    updateFromRoomState();
  }

  Future<void> removeAllEventsFromRemoteCalendar(String id) async {
    controller.removeWhere((i) => i.event?.remoteSourceId == id);
    await _syncControllerEventsToRoomState();
  }

  Future<void> createEvent(RFC8984CalendarEvent event) async {
    if (event.uid == "") {
      event.uid = _generateId();
    }

    var calendarEvents = fromRfcEvent(event);
    for (var calendarEvent in calendarEvents) {
      var color = config.getColorFromUser(widgetApi.userId);

      calendarEvent = calendarEvent.copyWith(color: color);
      calendarEvent.event!.senderId = widgetApi.userId;

      controller.add(calendarEvent);
    }

    _syncControllerEventsToRoomState();
  }

  Future<void> _syncControllerEventsToRoomState() async {
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

    var json = uniqueEvents
        .map(
          (e) => {
            "format": "chat.commet.calendar.event.rfc8984",
            if (e.remoteSourceId != null) "remote_source_id": e.remoteSourceId,
            if (e.type != null) "type": e.type!,
            "event": e.data.toJson(),
          },
        )
        .toList();

    await widgetApi.sendAction(FromWidgetAction.sendEvent, {
      "type": "chat.commet.calendar_event",
      "state_key": widgetApi.userId,
      "content": {"events": json},
    });
  }
}
