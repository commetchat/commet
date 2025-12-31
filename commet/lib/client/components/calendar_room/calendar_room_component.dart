import 'package:commet/client/client.dart';
import 'package:commet/client/components/room_component.dart';
import 'package:commet/utils/stored_stream_controller.dart';
import 'package:commet_calendar_widget/calendar.dart';
import 'package:commet_calendar_widget/rfc8984.dart';

enum CalendarSyncType {
  events,
  unavailability,
}

enum CalendarSource {
  ical,
  room,
}

class SyncedCalendar {
  SyncedCalendar(this.source, this.sourceType, this.syncType,
      {this.overrideEventName, this.id});

  String source;
  CalendarSyncType syncType;
  CalendarSource sourceType;
  String? id;
  String? overrideEventName;

  Map<String, dynamic> toJson() {
    return {
      "source": source,
      "source_type": switch (sourceType) {
        CalendarSource.ical => "ical",
        CalendarSource.room => "room",
      },
      "sync_type": switch (syncType) {
        CalendarSyncType.events => "events",
        CalendarSyncType.unavailability => "unavailability"
      },
      if (overrideEventName != null) "override_event_name": overrideEventName!,
    };
  }

  static SyncedCalendar fromJson(Map<String, dynamic> data) {
    var syncType = switch (data["sync_type"]) {
      "events" => CalendarSyncType.events,
      "unavailability" => CalendarSyncType.unavailability,
      _ => throw Exception("Unknown calendar sync type")
    };

    var source_type = switch (data["source_type"]) {
      "ical" => CalendarSource.ical,
      "room" => CalendarSource.room,
      _ => throw Exception("Unknown calendar sync type")
    };

    return SyncedCalendar(data["source"], source_type, syncType,
        overrideEventName: data["override_event_name"]);
  }
}

abstract class CalendarRoom<R extends Client, T extends Room>
    implements RoomComponent<R, T> {
  MatrixCalendar? get calendar;

  bool get hasCalendar;

  bool get isCalendarRoom;

  Stream<void> get onEventsChanged;

  List<MatrixCalendarEventState> getEventsOnDay(DateTime date);

  StoredStreamController<Map<String, SyncedCalendar>> get syncedCalendars;

  Future<List<RFC8984CalendarEvent>> getEventsFromIcsUrl(Uri uri,
      {String? calendarId});

  Future<void> addSyncedCalendar(SyncedCalendar calendar);

  Future<void> removeSyncedCalendar(String id);

  Future<void> runCalendarSync();
}
