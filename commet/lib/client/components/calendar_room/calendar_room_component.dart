import 'package:commet/client/client.dart';
import 'package:commet/client/components/room_component.dart';
import 'package:commet/utils/stored_stream_controller.dart';
import 'package:commet_calendar_widget/calendar.dart';

abstract class CalendarRoom<R extends Client, T extends Room>
    implements RoomComponent<R, T> {
  bool get isCalendar;

  MatrixCalendar get calendar;

  Stream<void> get onEventsChanged;

  List<MatrixCalendarEventState> getEventsOnDay(DateTime date);

  StoredStreamController<Map<String, String>> get syncedCalendars;

  Future<void> addSyncedCalendar(String uri);

  Future<void> removeSyncedCalendar(String id);

  Future<void> runCalendarSync();
}
