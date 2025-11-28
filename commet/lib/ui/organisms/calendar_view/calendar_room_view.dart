import 'package:commet/client/components/calendar_room/calendar_room_component.dart';
import 'package:commet/config/layout_config.dart';
import 'package:commet_calendar_widget/main.dart';
import 'package:flutter/material.dart';

import 'package:tiamat/tiamat.dart' as tiamat;

class CalendarRoomView extends StatefulWidget {
  const CalendarRoomView(this.calendar, {super.key});
  final CalendarRoom calendar;

  @override
  State<CalendarRoomView> createState() => _CalendarRoomViewState();
}

class _CalendarRoomViewState extends State<CalendarRoomView> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    var query = MediaQuery.of(context);

    // I dont know why, but I had to manually specify the height like this
    // in order to get the month view to fill all the space
    Widget result = LayoutBuilder(
      builder: (context, constraints) {
        var newQuery = query.copyWith(
          size: Size(constraints.maxWidth, constraints.maxHeight),
        );
        return SizedBox(
          height: constraints.maxHeight,
          width: constraints.maxWidth,
          child: MediaQuery(
            data: newQuery,
            child: CalendarWidgetView(
              calendar: widget.calendar.calendar,
              useMobileLayout: Layout.mobile,
              watermark: false,
            ),
          ),
        );
      },
    );

    if (Layout.desktop) {
      result = tiamat.Tile.lowest(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
          child: ClipRRect(
            borderRadius: BorderRadiusGeometry.only(
              topLeft: Radius.circular(8),
              topRight: Radius.circular(8),
            ),
            child: result,
          ),
        ),
      );
    }

    return result;
  }
}
