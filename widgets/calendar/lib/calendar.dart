import 'dart:async';
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
import 'package:uuid/uuid.dart';

import 'package:timezone/standalone.dart' as tz;

class MatrixCalendarEventState {
  RFC8984CalendarEvent data;
  bool loaded = false;
  String? senderId;
  String? eventId;
  String? remoteSourceId;
  String? type;

  bool get isUnavailability => type == "unavailability";

  MatrixCalendarEventState({this.senderId, required this.data, this.type});

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    if (other is! MatrixCalendarEventState) {
      return false;
    }

    var js = data.toJson();
    var otherJs = other.data.toJson();

    js.remove("updated");
    js.remove("uid");
    otherJs.remove("updated");
    otherJs.remove("uid");

    return other.type == type &&
        other.remoteSourceId == remoteSourceId &&
        jsonEncode(js) == jsonEncode(otherJs);
  }
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

  StreamController onNeedsMigration = StreamController.broadcast();

  Map<String, Map<String, dynamic>> roomState = {};

  MatrixCalendarConfig config;

  bool needsStateMigration = false;

  MatrixCalendar(this.widgetApi, {this.config = const MatrixCalendarConfig()}) {
    this.controller = EventController();

    widgetApi.onReady.listen(onWidgetReady);

    widgetApi.onAction(
        ToWidgetAction.updateState,
        preventDefaultHandler: true,
        onStateUpdated);

    widgetApi.onAction(
        ToWidgetAction.sendEvent, preventDefaultHandler: true, onEventReceived);
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

      if (type == "chat.commet.calendar_event" &&
          stateKey == widgetApi.userId) {
        if ((event["content"] as Map<String, dynamic>).isNotEmpty) {
          needsStateMigration = true;
          onNeedsMigration.add(null);
        }
      }

      if (!roomState.containsKey(type)) {
        roomState[type] = {};
      }

      roomState[type]![stateKey] = event;

      if (type == "chat.commet.calendars") {
        readExistingEvents();
      }
    }

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

  bool canDeleteEvent(MatrixCalendarEventState event) {
    if (event.senderId != widgetApi.userId) {
      return false;
    }

    return true;
  }

  void onWidgetReady(void event) async {
    await widgetApi.requestCapabilities([
      MatrixCapability.getRoomState("chat.commet.calendar_event"),
      MatrixCapability.setRoomState(
        "chat.commet.calendar_event",
        stateKey: widgetApi.userId,
      ),
      MatrixCapability.getRoomState("chat.commet.calendars"),
      MatrixCapability.setRoomState("chat.commet.calendars"),
      MatrixCapability.sendEvent("chat.commet.calendar_events"),
      MatrixCapability.receiveEvent("chat.commet.calendar_events"),
      MatrixCapability.sendEvent("m.room.redaction"),
      MatrixCapability.receiveEvent("m.room.redaction"),
      MatrixCapability.sendEvent("chat.commet.calendar_create"),
    ]);

    await readExistingEvents();
  }

  Future<void> readExistingEvents({String? nextChunk}) async {
    var calendarId = await getCalendarId();
    if (calendarId == null) return;

    var response = await widgetApi.sendAction(FromWidgetAction.readRelations, {
      "event_id": calendarId,
      "event_type": "chat.commet.calendar_events",
      "limit": 100,
      if (nextChunk != null) "from": nextChunk,
      "rel_type": "m.reference",
    });

    var events = response["chunk"] as List<dynamic>;

    for (var event in events) {
      handleCalendarEventReceived(event);
    }

    if (response["next_batch"] is String) {
      await readExistingEvents(nextChunk: response["next_batch"]);
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

  List<MatrixCalendarEventState> getAllEvents() {
    return controller.allEvents.map((i) => i.event!).toList();
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
            title: event.title + " ${event.uid} ",
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

  Future<void> syncEvents(
    Map<String, List<RFC8984CalendarEvent>> events, {
    String? eventType,
  }) async {
    var calenarId = await getCalendarId(createIfNotFound: true);

    for (var entry in events.entries) {
      var eventsToSync = entry.value;
      var remoteSourceId = entry.key;

      await removeAllEventsFromRemoteCalendar(remoteSourceId);

      var migratedContent = {
        "type": "chat.commet.calendar_events",
        "content": {
          "m.relates_to": {"event_id": calenarId, "rel_type": "m.reference"},
          "format": "chat.commet.calendar.event.rfc8984",
          "remote_source_id": remoteSourceId,
          "events": entry.value
              .map((i) => {
                    if (eventType != null) "type": eventType,
                    "event": i.toJson(),
                  })
              .toList(),
        }
      };

      var result = await widgetApi.sendAction(
          FromWidgetAction.sendEvent, migratedContent);
    }
  }

  Future<void> removeAllEventsFromRemoteCalendar(String id) async {
    var existing =
        controller.allEvents.where((i) => i.event?.remoteSourceId == id);

    Set<String> removeEvents = Set();
    for (var e in existing) {
      if (e.event?.eventId != null) removeEvents.add(e.event!.eventId!);
    }

    print("Events to remove: $removeEvents");

    for (var i in removeEvents) {
      await redactEvent(i);
    }
  }

  Future<void> deleteEvent(RFC8984CalendarEvent event) async {
    print("Deleting event");
    for (var e in controller.allEvents.toList()) {
      if (e.event?.data.uid == event.uid) {
        var eventId = e.event?.eventId;
        print("Event id: $eventId");
        if (eventId != null) {
          await redactEvent(eventId);
        }
      }
    }
  }

  Future<void> redactEvent(String eventId) async {
    await widgetApi.sendAction(FromWidgetAction.sendEvent, {
      "type": "m.room.redaction",
      "chat.commet.calendar.redaction": "edit",
      "content": {"redacts": eventId}
    });
  }

  Future<bool> createEvent(RFC8984CalendarEvent event,
      {String? eventType}) async {
    if (event.uid == "") {
      event.uid = _generateId();
    }

    var existing = controller.allEvents
        .where((i) =>
            i.event?.data.uid == event.uid &&
            i.event?.senderId == widgetApi.userId)
        .firstOrNull;

    var existingEventId = existing?.event?.eventId;

    print("Existing event for this event:  ${existing}");

    controller.removeWhere((e) => e.event?.data.uid == event.uid);

    print("Removed existing events");
    var calendarEvents = fromRfcEvent(event, eventType: eventType);
    for (var calendarEvent in calendarEvents) {
      print("A");
      var color = config.getColorFromUser(widgetApi.userId);

      print("B");
      calendarEvent = calendarEvent.copyWith(color: color);
      calendarEvent.event!.senderId = widgetApi.userId;

      print("C");

      print("D");
    }

    print("Added event");

    var calendarId = await getCalendarId(createIfNotFound: true);
    print("Calendar id: $calendarId");
    if (calendarId == null) return false;

    var result = await widgetApi.sendAction(FromWidgetAction.sendEvent, {
      "type": "chat.commet.calendar_events",
      "content": {
        "m.relates_to": {"event_id": calendarId, "rel_type": "m.reference"},
        "format": "chat.commet.calendar.event.rfc8984",
        "events": [
          {
            if (eventType != null) "type": eventType,
            "event": event.toJson(),
          }
        ],
      }
    });

    print("Sent event!");
    print(result);

    if (existingEventId != null) {
      await widgetApi.sendAction(FromWidgetAction.sendEvent, {
        "type": "m.room.redaction",
        "content": {"redacts": existingEventId}
      });
    }

    return true;
  }

  Future<String?> getCalendarId({bool createIfNotFound = false}) async {
    var calendar = roomState["chat.commet.calendars"];
    print("Getting calendar id, create: $createIfNotFound");

    String? calendarId;

    print("State: $calendar");

    try {
      var calendars = calendar![""]["content"]["calendars"] as List<dynamic>;
      calendarId = calendars.first as String;
    } catch (e) {
      print("Failed to get calendar id: ${e}");
    }

    if (calendarId == null && createIfNotFound) {
      var result = await widgetApi.sendAction(FromWidgetAction.sendEvent,
          {"type": "chat.commet.calendar_create", "content": {}});

      print("Sent action");
      print("Result: $result");

      if (result.containsKey("event_id")) {
        calendarId = result["event_id"] as String;

        await widgetApi.sendAction(FromWidgetAction.sendEvent, {
          "type": "chat.commet.calendars",
          "state_key": "",
          "content": {
            "calendars": [
              result["event_id"],
            ]
          }
        });

        print("Added calendar to room state");
      }
    }

    return calendarId;
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

  Map<String, dynamic>? onEventReceived(Map<String, dynamic> apiData) {
    var eventType = apiData["data"]["type"];

    if (eventType == "chat.commet.calendar_events") {
      handleCalendarEventReceived(apiData["data"]);
    }

    if (eventType == "m.room.redaction") {
      handleCalendarEventDeleted(apiData["data"]);
    }

    return null;
  }

  void handleCalendarEventReceived(Map<String, dynamic> eventData) {
    var sender = eventData["sender"];
    var content = eventData["content"] as Map<String, dynamic>;

    if (!content.containsKey("events")) {
      return;
    }
    var events = content["events"] as List<dynamic>;
    var remoteSource = content["remote_source_id"];

    var eventId = eventData["event_id"];
    for (var event in events) {
      var mxCalendarEvent = RFC8984CalendarEvent.fromJson(event["event"]);
      var eventType = event["type"];

      var color = config.getColorFromUser(sender);
      var calendarEvents = fromRfcEvent(mxCalendarEvent, eventType: eventType);
      controller.removeWhere((i) =>
          i.event!.data.uid == mxCalendarEvent.uid && i.event!.eventId == null);

      for (var calendarEvent in calendarEvents) {
        calendarEvent = calendarEvent.copyWith(color: color);
        calendarEvent.event!.senderId = sender;
        calendarEvent.event!.loaded = true;
        calendarEvent.event!.remoteSourceId = remoteSource;
        calendarEvent.event!.type = eventType;
        calendarEvent.event!.eventId = eventId;

        controller.add(calendarEvent);
      }
    }
  }

  void handleCalendarEventDeleted(eventData) {
    var content = eventData["content"];
    var eventId = content["redacts"];

    var events = List.empty(growable: true);

    for (int i = 0; i < controller.allEvents.length; i++) {
      var e = controller.allEvents[i];

      if (e.event?.eventId == eventId) {
        events.add(e);
      }
    }

    for (var e in events) {
      controller.remove(e);
    }
  }

  Future<void> migrateRoomStateEvents(
      Function(int progress, int total) onProgress) async {
    var stateEvent = roomState["chat.commet.calendar_event"]![widgetApi.userId];

    var events = Map<String, dynamic>.from(
        stateEvent["content"]['events'] as Map<String, dynamic>);

    var calendarId = await getCalendarId(createIfNotFound: true);
    print("Calendar id: $calendarId");
    if (calendarId == null) return;

    int total = events.length;

    while (events.isNotEmpty) {
      var key = events.keys.first;
      var e = events[key];

      var remoteSource = e["remote_source_id"];

      var keys = [
        key,
        if (remoteSource != null)
          ...events.keys
              .where((e) => events[e]["remote_source_id"] == remoteSource)
      ];

      var eventsGroup =
          keys.map((i) => Map<String, dynamic>.from(events[i])).toList();

      for (var event in keys) {
        print("Removing key: $event");
        events.remove(event);
      }

      for (var e in eventsGroup) {
        e.remove("remote_source_id");
      }

      int eventsLeft = events.length;

      onProgress(eventsLeft, total);

      var migratedContent = {
        "type": "chat.commet.calendar_events",
        "content": {
          "m.relates_to": {"event_id": calendarId, "rel_type": "m.reference"},
          "format": "chat.commet.calendar.event.rfc8984",
          if (remoteSource != null) "remote_source_id": remoteSource,
          "events": eventsGroup,
        }
      };

      var result = await widgetApi.sendAction(
          FromWidgetAction.sendEvent, migratedContent);

      await Future.delayed(Duration(seconds: 2));

      print("Source: $remoteSource, events: $eventsGroup");
    }

    await widgetApi.sendAction(FromWidgetAction.sendEvent, {
      "type": "chat.commet.calendar_event",
      "state_key": widgetApi.userId,
      "content": {}
    });

    needsStateMigration = false;
    print("Finished migrating");
  }
}
