import 'dart:convert';
import 'dart:math';
import 'dart:ui';

import 'package:calendar_view/calendar_view.dart';
import 'package:commet_calendar_widget/rfc8984.dart';
import 'package:commet_calendar_widget/utils.dart';
import 'package:flutter/material.dart';
import 'package:matrix_widget_api/matrix_widget_api.dart';
import 'package:matrix_widget_api/types.dart';
import 'package:tiamat/tiamat.dart' as tiamat;

class MatrixCalendarEventState {
  RFC8984CalendarEvent data;
  bool loaded = false;
  String? senderId;

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
    return showDialog<T>(context: context, builder: builder);
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

    print("Reading calendar events");
    widgetApi.onAction(ToWidgetAction.msc2764UpdateState, (data) {
      print("Received room state: ${data}");
    });

    widgetApi.onAction(
      ToWidgetAction.updateState,
      preventDefaultHandler: true,
      (update) {
        print("Received update room state: $update");
        var states = Map<String, dynamic>.from(update);
        var data = states['data'];
        var stateEvents = data['state'];
        print(stateEvents);

        for (var stateEvent in stateEvents) {
          var event = Map<String, dynamic>.from(stateEvent);
          print(event);

          var type = event['type'];
          var stateKey = event['state_key'] ?? "";
          if (!roomState.containsKey(type)) {
            roomState[type] = {};
          }

          roomState[type]![stateKey] = event;
        }

        print(JsonEncoder.withIndent("  ").convert(roomState));

        updateFromRoomState();
        return null;
      },
    );
  }

  void updateFromRoomState() {
    var states = roomState["chat.commet.calendar_event"];
    var events = controller.allEvents.toList();
    controller.removeAll(events);

    for (var entry in states!.entries) {
      try {
        var events = entry.value["content"]["events"];
        var sender = entry.value["sender"];
        print(events);
        for (var event in events) {
          var data = Map<String, dynamic>.from(event);
          try {
            var mxCalendarEvent = RFC8984CalendarEvent.fromJson(data);

            var color = config.getColorFromUser(sender);
            var calendarEvent = fromRfcEvent(mxCalendarEvent);
            calendarEvent.event?.senderId = sender;
            calendarEvent = calendarEvent.copyWith(color: color);
            calendarEvent.event?.loaded = true;

            controller.add(calendarEvent);
          } catch (_) {
            print("Failed to parse event item: ${data}");
          }
        }
      } catch (_) {
        print("Failed to state event: ${entry}");
      }
    }
  }

  List<RFC8984CalendarEvent> getEventsOnDay(DateTime date) {
    return controller
        .getEventsOnDay(date)
        .map((e) => e.event)
        .nonNulls
        .map((e) => e.data)
        .toList();
  }

  CalendarEventData<MatrixCalendarEventState> fromRfcEvent(
    RFC8984CalendarEvent event,
  ) {
    var localTime = event.start.toLocal();
    return CalendarEventData(
      title: event.title,
      date: localTime,
      startTime: localTime,
      endTime: localTime.add(event.duration),
      event: MatrixCalendarEventState(data: event),
    );
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

  Future<void> createEvent(RFC8984CalendarEvent event) async {
    event.uid = _generateId();

    var calendarEvent = fromRfcEvent(event);

    var color = config.getColorFromUser(widgetApi.userId);

    calendarEvent = calendarEvent.copyWith(color: color);
    calendarEvent.event?.senderId = widgetApi.userId;

    controller.add(calendarEvent);

    print("Got Events");
    print(controller.allEvents.toList());

    var events = controller.allEvents
        .where((e) => e.event?.senderId == widgetApi.userId)
        .map((e) => e.event)
        .nonNulls
        .toList();

    print(events);
    events.sort((a, b) => a.data.uid.compareTo(b.data.uid));

    var json = events.map((e) => e.data.toJson()).toList();

    widgetApi.sendAction(FromWidgetAction.sendEvent, {
      "type": "chat.commet.calendar_event",
      "state_key": widgetApi.userId,
      "content": {"events": json},
    });
  }
}
