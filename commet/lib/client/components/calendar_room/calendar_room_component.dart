import 'package:commet/client/client.dart';
import 'package:commet/client/components/room_component.dart';
import 'package:commet_calendar_widget/calendar.dart';

abstract class CalendarRoom<R extends Client, T extends Room>
    implements RoomComponent<R, T> {
  bool get isCalendar;

  MatrixCalendar get calendar;

  Stream<void> get onEventsChanged;

  List<MatrixCalendarEventState> getEventsOnDay(DateTime date);
}
