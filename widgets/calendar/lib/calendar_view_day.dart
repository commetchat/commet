import 'package:calendar_view/calendar_view.dart';
import 'package:commet_calendar_widget/calendar.dart';
import 'package:commet_calendar_widget/calendar_view_header.dart';
import 'package:commet_calendar_widget/event_view.dart';
import 'package:commet_calendar_widget/main.dart';
import 'package:commet_calendar_widget/unavailability_painter.dart';
import 'package:flutter/material.dart';

class CalendarViewDay extends StatefulWidget {
  const CalendarViewDay({
    required this.calendar,
    required this.useMobileLayout,
    this.createEvent,
    this.onPageChanged,
    this.setViewMode,
    this.onEventTapped,
    this.initialDate,
    super.key,
  });
  final MatrixCalendar calendar;
  final Function(DateTime)? onPageChanged;
  final Function(DateTime)? createEvent;
  final Function(CalendarViewMode)? setViewMode;
  final Function(MatrixCalendarEventState)? onEventTapped;
  final DateTime? initialDate;
  final bool useMobileLayout;

  @override
  State<CalendarViewDay> createState() => _CalendarViewDayState();
}

class _CalendarViewDayState extends State<CalendarViewDay> {
  var key = GlobalKey<DayViewState>();

  @override
  Widget build(BuildContext context) {
    var colorScheme = Theme.of(context).colorScheme;
    var headerStyle = HeaderStyle(
      decoration: BoxDecoration(color: colorScheme.surfaceContainerLowest),
      leftIconConfig: IconDataConfig(color: colorScheme.onSurface),
      rightIconConfig: IconDataConfig(color: colorScheme.onSurface),
      headerTextStyle: Theme.of(
        context,
      ).textTheme.bodyMedium?.copyWith(color: colorScheme.onSurface),
    );

    return Material(
      child: LayoutBuilder(builder: (context, constraints) {
        const minutesPerDay = (60.0 * 24.0);
        const headerSize = 60.0;
        var heightPerMinute =
            (constraints.maxHeight - headerSize) / minutesPerDay;

        const minHeightPerMinute = 0.4;
        if (heightPerMinute < minHeightPerMinute) {
          heightPerMinute = minHeightPerMinute;
        }
        return Stack(
          children: [
            Padding(
              padding:
                  EdgeInsets.fromLTRB(0, 0, 0, widget.useMobileLayout ? 80 : 0),
              child: DayView(
                key: key,
                initialDay: widget.initialDate,
                showVerticalLine: false,
                backgroundColor: Theme.of(context).colorScheme.surface,
                heightPerMinute: heightPerMinute,
                headerStyle: headerStyle,
                safeAreaOption: SafeAreaOption(
                  left: false,
                  right: false,
                  top: false,
                  bottom: false,
                ),
                timeLineWidth: 80,
                onDateTap: (date) => widget.createEvent?.call(date),
                fullDayEventBuilder: (events, date) {
                  return Row(
                    mainAxisSize: MainAxisSize.max,
                    children: events.map((e) {
                      return Expanded(
                        child: EventViewMini(
                            e.event!, widget.calendar.config, e.color),
                      );
                    }).toList(),
                  );
                },
                hourIndicatorSettings: HourIndicatorSettings(
                  color: Theme.of(context).colorScheme.surfaceContainer,
                ),
                eventTileBuilder:
                    (date, events, boundary, startDuration, endDuration) {
                  var event = events.first;

                  return Padding(
                      padding: const EdgeInsets.fromLTRB(2, 1, 12, 0),
                      child: EventViewBox(
                        event.event!,
                        color: event.color,
                        widget.calendar.config,
                        boundary: boundary,
                        onEventTapped: widget.onEventTapped,
                      ));
                },
                onEventTap: (events, date) => print("Tapped event!"),
                liveTimeIndicatorSettings: LiveTimeIndicatorSettings(
                  color: Theme.of(context).colorScheme.primary,
                  showTime: true,
                  height: 2,
                  textColor: Theme.of(context).colorScheme.onPrimary,
                  timeBackgroundViewWidth: 62,
                  showBullet: false,
                  showTimeBackgroundView: true,
                ),
                dayTitleBuilder: (date) => CalendarViewHeader(
                  date: date,
                  useMobileLayout: widget.useMobileLayout,
                  mode: CalendarViewMode.day,
                  nextPage: () => key.currentState?.nextPage(),
                  prevPage: () => key.currentState?.previousPage(),
                  setViewMode: widget.setViewMode,
                ),
                onPageChange: (date, page) {
                  widget.onPageChanged?.call(date);
                },
                controller: widget.calendar.controller,
              ),
            ),
            if (widget.useMobileLayout)
              Align(
                alignment: AlignmentGeometry.bottomCenter,
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      FloatingActionButton(
                          child: Icon(Icons.chevron_left),
                          onPressed: () => key.currentState?.previousPage()),
                      FloatingActionButton(
                          child: Icon(Icons.chevron_right),
                          onPressed: () => key.currentState?.nextPage()),
                    ],
                  ),
                ),
              ),
          ],
        );
      }),
    );
  }
}
