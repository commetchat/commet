import 'dart:async';

import 'package:commet/client/components/calendar_room/calendar_room_component.dart';
import 'package:commet/client/matrix/matrix_client.dart';
import 'package:commet/client/matrix/matrix_room.dart';
import 'package:commet/client/matrix/widget/matrix_widget_runner.dart';
import 'package:commet/ui/navigation/adaptive_dialog.dart';
import 'package:flutter/material.dart';
import 'package:matrix/matrix.dart';
import 'package:commet_calendar_widget/calendar.dart';

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
    implements CalendarRoom<MatrixClient, MatrixRoom> {
  late MatrixCalendar _calendar;

  StreamController controller = StreamController.broadcast();

  MatrixCalendarRoomComponent(this.client, this.room) {
    var api = MatrixWidgetRunner(client.matrixClient, room.matrixRoom);
    _calendar = MatrixCalendar(api, config: CustomMatrixCalendarConfig());
    _calendar.controller.addListener(() {
      controller.add(());
    });
  }

  @override
  MatrixClient client;

  @override
  bool get isCalendar =>
      room.matrixRoom.getState(EventTypes.RoomCreate)?.content['type'] ==
      "chat.commet.calendar";

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
    _calendar.widgetApi.start();
    return _calendar.getEventsOnDay(date);
  }
}
