import 'dart:async';
import 'package:commet/client/components/calendar_room/calendar_room_component.dart';
import 'package:commet/client/components/calendar_room/calendar_sync.dart';
import 'package:commet/client/components/component.dart';
import 'package:commet/client/matrix/components/matrix_sync_listener.dart';
import 'package:commet/client/matrix/matrix_client.dart';
import 'package:commet/client/matrix/matrix_room.dart';
import 'package:commet/client/matrix/widget/matrix_widget_runner.dart';
import 'package:commet/debug/log.dart';
import 'package:commet/main.dart';
import 'package:commet/ui/navigation/adaptive_dialog.dart';
import 'package:commet/utils/stored_stream_controller.dart';
import 'package:commet/utils/timezone_utils.dart';
import 'package:commet_calendar_widget/rfc8984.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:icalendar_parser/icalendar_parser.dart';
import 'package:icalendar_parser/icalendar_parser.dart' as ical;
import 'package:matrix/matrix.dart';
import 'package:commet_calendar_widget/calendar.dart';
import 'package:http/http.dart' as http;
import 'package:uuid/uuid.dart';

class CustomMatrixCalendarConfig extends MatrixCalendarConfig {
  @override
  Future<T?> dialog<T>({
    required BuildContext context,
    required Widget Function(BuildContext context) builder,
  }) {
    return AdaptiveDialog.show(context, builder: builder);
  }
}

class MatrixCalendarRoomComponent
    implements
        CalendarRoom<MatrixClient, MatrixRoom>,
        MatrixRoomSyncListener,
        NeedsPostLoginInit {
  late MatrixCalendar _calendar;

  static const String syncedCalendarsEventType =
      "chat.commet.calendar.synced_calendar_urls";

  StreamController controller = StreamController.broadcast();

  late StoredStreamController<Map<String, String>> syncedCalendars;

  static bool isCalendarRoom(MatrixRoom room) {
    return room.matrixRoom.getState(EventTypes.RoomCreate)?.content['type'] ==
        "chat.commet.calendar";
  }

  MatrixCalendarRoomComponent(this.client, this.room) {
    var api = MatrixWidgetRunner(client.matrixClient, room.matrixRoom);
    _calendar = MatrixCalendar(api, config: CustomMatrixCalendarConfig());
    _calendar.controller.addListener(() {
      controller.add(());
    });

    syncedCalendars = StoredStreamController(getCalendarsFromAccountData());
  }

  @override
  void postLoginInit() {
    if (!isHeadless) {
      TimezoneUtils.instance.init().then((_) {
        _calendar.widgetApi.start();
        CalendarSync.instance.startSyncing();
      });
    }
  }

  @override
  MatrixClient client;

  @override
  MatrixRoom room;

  @override
  MatrixCalendar get calendar {
    return _calendar;
  }

  @override
  Stream<void> get onEventsChanged => controller.stream;

  @override
  List<MatrixCalendarEventState> getEventsOnDay(DateTime date) {
    return _calendar.getEventsOnDay(date);
  }

  @override
  onSync(JoinedRoomUpdate update) {
    if (update.accountData?.any((i) => i.type == syncedCalendarsEventType) ==
        true) {
      syncedCalendars.add(getCalendarsFromAccountData());
    }
  }

  Map<String, String> getCalendarsFromAccountData() {
    var data = room.matrixRoom.roomAccountData[syncedCalendarsEventType];
    if (data == null) {
      return {};
    }

    try {
      var content = data.content["urls"];
      if (content == null) {
        return {};
      }

      var result = Map<String, String>.from(content as dynamic);
      return result;
    } catch (_) {
      return {};
    }
  }

  @override
  Future<void> addSyncedCalendar(String url) {
    var urls = syncedCalendars.value ?? {};
    var uuid = const Uuid();
    var id = uuid.v4();
    urls = {};
    urls[id] = url.toString();
    var c = room.matrixRoom.client;

    Log.i("Setting synced calendars: ${urls}");
    return room.matrixRoom.client.setAccountDataPerRoom(
      c.userID!,
      room.matrixRoom.id,
      syncedCalendarsEventType,
      {"urls": urls},
    );
  }

  @override
  Future<void> runCalendarSync() async {
    var urls = syncedCalendars.value;
    if (urls == null) {
      return;
    }

    Map<String, List<RFC8984CalendarEvent>> foundEvents = {};

    for (var entry in urls.entries) {
      var url = Uri.parse(entry.value);
      var result = await http.get(url);

      if (result.statusCode != 200) {
        Log.e("Failed to get calendar");
        continue;
      }

      var content = result.body;
      final iCal = ICalendar.fromString(content);

      var results =
          iCal.data.map((e) => fromIcal(entry.key, e)).nonNulls.toList();

      Log.i("Found ${results.length} events to sync to calendar");

      foundEvents[entry.key] = results;
    }
    calendar.syncEvents(foundEvents);
  }

  RFC8984CalendarEvent? fromIcal(String calendarId, Map<String, dynamic> data) {
    if (data["type"] != "VEVENT") {
      return null;
    }

    final startIcs = (data["dtstart"] as ical.IcsDateTime?);
    final endIcs = (data["dtend"] as ical.IcsDateTime?);

    var start = startIcs?.toDateTime();
    var end = endIcs?.toDateTime();
    var rrule = data["rrule"] as String?;
    var startTimezone = startIcs?.tzid;

    RFC8984RecurrenceRule? recur;
    if (rrule != null) {
      recur = parseRecurrenceRule(rrule);
    }

    if (start == null || end == null) {
      Log.i("Event had no start or end time, skipping");
      return null;
    }

    final title = (data["summary"] as String?) ?? "(No title)";

    var updated = (data["lastModified"] as ical.IcsDateTime?)?.toDateTime() ??
        DateTime.now();

    var uid = sha1.convert("$calendarId/${data["uid"]}".codeUnits);

    var duration = end.difference(start);

    return RFC8984CalendarEvent(
      uid: uid.toString(),
      timeZone: startTimezone,
      updated: updated.toUtc(),
      title: title,
      recurrenceRules: recur != null ? [recur] : null,
      start: start,
      duration: duration,
    );
  }

  RFC8984RecurrenceRule? parseRecurrenceRule(String rrule) {
    Log.i(rrule);
    var rule = Map<String, String>.new();
    var parts = rrule.split(";");
    for (var part in parts) {
      var otherParts = part.split("=");
      var key = otherParts[0];
      var value = otherParts[1];
      rule[key] = value;
    }

    var frequency = rule["FREQ"]?.toLowerCase();
    var firstDayOfWeek = rule["WKST"]?.toLowerCase();
    int? count = rule["COUNT"] != null ? int.parse(rule["COUNT"]!) : null;
    int? interval =
        rule["INTERVAL"] != null ? int.parse(rule["INTERVAL"]!) : null;
    print(parts);
    if (frequency == null) return null;

    List<Rfc8984NDay>? byDays;
    if (rule["BYDAY"] != null) {
      byDays = parseByDays(rule["BYDAY"]!);
    }

    return RFC8984RecurrenceRule(
        firstDayOfWeek: firstDayOfWeek,
        frequency: frequency,
        interval: interval,
        count: count,
        byDay: byDays);
  }

  List<Rfc8984NDay> parseByDays(String rule) {
    var days = rule.split(",");
    var result = List<Rfc8984NDay>.empty(growable: true);
    for (var day in days) {
      var lower = day.toLowerCase();
      var dayName = lower.substring(lower.length - 2);
      int? period;
      if (lower.length > 2) {
        var periodStr = lower.substring(0, lower.length - 2);
        period = int.tryParse(periodStr);
      }

      if (["mo", "tu", "we", "th", "fr", "sa", "su"].contains(dayName)) {
        result.add(Rfc8984NDay(dayName, nthOfPeriod: period));
      }
    }

    return result;
  }

  @override
  Future<void> removeSyncedCalendar(String id) async {
    if (syncedCalendars.value == null) {
      return;
    }

    var urls = syncedCalendars.value ?? {};
    urls.remove(id);
    var c = room.matrixRoom.client;

    await room.matrixRoom.client.setAccountDataPerRoom(
      c.userID!,
      room.matrixRoom.id,
      syncedCalendarsEventType,
      {if (urls.isNotEmpty) "urls": urls},
    );

    calendar.removeAllEventsFromRemoteCalendar(id);
  }
}
