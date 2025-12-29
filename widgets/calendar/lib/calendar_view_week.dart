import 'package:calendar_view/calendar_view.dart';
import 'package:commet_calendar_widget/calendar.dart';
import 'package:commet_calendar_widget/calendar_view_header.dart';
import 'package:commet_calendar_widget/event_view.dart';
import 'package:commet_calendar_widget/main.dart';
import 'package:commet_calendar_widget/unavailability_painter.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:tiamat/tiamat.dart' as tiamat;

class CalendarViewWeek extends StatefulWidget {
  const CalendarViewWeek({
    required this.calendar,
    required this.useMobileLayout,
    super.key,
    this.createEvent,
    this.setViewMode,
    this.onPageChanged,
    this.onEventTapped,
    this.initialDate,
  });

  final Function(DateTime)? createEvent;
  final Function(CalendarViewMode)? setViewMode;

  final Function(MatrixCalendarEventState)? onEventTapped;

  final Function(DateTime)? onPageChanged;

  final bool useMobileLayout;
  final DateTime? initialDate;
  final MatrixCalendar calendar;

  @override
  State<CalendarViewWeek> createState() => _CalendarViewWeekState();
}

class _CalendarViewWeekState extends State<CalendarViewWeek> {
  var key = GlobalKey<WeekViewState>();

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
      child: LayoutBuilder(
        builder: (context, constraints) {
          const minutesPerDay = (60.0 * 24.0);
          const headerSize = 60.0;
          var heightPerMinute =
              (constraints.maxHeight - headerSize) / minutesPerDay;

          print(heightPerMinute);

          const minHeightPerMinute = 0.4;
          if (heightPerMinute < minHeightPerMinute) {
            heightPerMinute = minHeightPerMinute;
          }

          return Stack(
            children: [
              Padding(
                padding: EdgeInsets.fromLTRB(
                    0, 0, 0, widget.useMobileLayout ? 80 : 0),
                child: WeekView(
                  initialDay: widget.initialDate,
                  key: key,
                  headerStyle: headerStyle,
                  heightPerMinute: heightPerMinute,
                  safeAreaOption: SafeAreaOption(
                    left: false,
                    top: false,
                    right: false,
                    bottom: false,
                  ),
                  weekPageHeaderBuilder: (startDate, endDate) =>
                      CalendarViewHeader(
                    date: startDate,
                    useMobileLayout: widget.useMobileLayout,
                    secondaryDate: endDate,
                    mode: CalendarViewMode.week,
                    nextPage: () => key.currentState?.nextPage(),
                    prevPage: () => key.currentState?.previousPage(),
                    setViewMode: widget.setViewMode,
                  ),
                  hourIndicatorSettings: HourIndicatorSettings(
                    color: Theme.of(context).colorScheme.surfaceContainer,
                  ),
                  showHalfHours: false,
                  halfHourIndicatorSettings: HourIndicatorSettings(
                    color: Theme.of(context).colorScheme.surfaceContainerLow,
                  ),
                  showLiveTimeLineInAllDays: false,
                  controller: widget.calendar.controller,
                  liveTimeIndicatorSettings: LiveTimeIndicatorSettings(
                      color: Theme.of(context).colorScheme.primary,
                      textColor: Theme.of(context).colorScheme.onPrimary,
                      showTime: true,
                      height: 2,
                      timeBackgroundViewWidth: 62,
                      showTimeBackgroundView: true,
                      showBullet: false),
                  weekDayBuilder: (date) {
                    var now = DateTime.now();
                    bool isToday = date.year == now.year &&
                        date.month == now.month &&
                        date.day == now.day;
                    var format = DateFormat('EEEE').format(date);

                    return Material(
                      color: isToday ? colorScheme.primary : Colors.transparent,
                      borderRadius: BorderRadius.circular(15),
                      clipBehavior: Clip.hardEdge,
                      child: InkWell(
                        onTap: () {
                          widget.onPageChanged?.call(date);
                          widget.setViewMode?.call(CalendarViewMode.day);
                        },
                        child: Padding(
                          padding: const EdgeInsets.all(0.0),
                          child: Padding(
                            padding: const EdgeInsets.all(0.0),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Center(
                                  child: Center(
                                    child: Text(
                                      format.substring(0, 1), //.day.toString(),
                                      style: isToday
                                          ? Theme.of(
                                              context,
                                            ).textTheme.bodySmall?.copyWith(
                                                color: colorScheme.onPrimary,
                                                fontWeight: FontWeight.bold,
                                              )
                                          : Theme.of(context)
                                              .textTheme
                                              .bodySmall,
                                    ),
                                  ),
                                ),
                                Text(
                                  DateFormat(DateFormat.ABBR_MONTH_DAY)
                                      .format(date),
                                  style: (isToday
                                          ? Theme.of(
                                              context,
                                            ).textTheme.bodySmall?.copyWith(
                                                color: colorScheme.onPrimary,
                                                fontWeight: FontWeight.bold,
                                              )
                                          : Theme.of(context)
                                              .textTheme
                                              .bodySmall)
                                      ?.copyWith(fontSize: 10),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                  fullDayEventBuilder: (events, date) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: events.map((e) {
                        return Padding(
                            padding: const EdgeInsets.fromLTRB(2, 0, 2, 2),
                            child: EventViewMini(
                              e,
                              widget.calendar,
                              onEventTapped: widget.onEventTapped,
                            ));
                      }).toList(),
                    );
                  },
                  timeLineWidth: 80,
                  onDateTap: (date) => widget.createEvent?.call(date),
                  weekNumberBuilder: (firstDayOfWeek) =>
                      Container(color: colorScheme.surfaceContainerLow),
                  eventTileBuilder:
                      (date, events, boundary, startDuration, endDuration) {
                    return Padding(
                        padding: const EdgeInsets.fromLTRB(2, 2, 2, 0),
                        child: EventViewBox(
                          events.first,
                          widget.calendar,
                          boundary: boundary,
                          onEventTapped: widget.onEventTapped,
                          avatarRadius: 8,
                        ));
                  },
                  backgroundColor: Theme.of(context).colorScheme.surface,
                  onPageChange: (date, pageIndex) {
                    widget.onPageChanged?.call(date);
                  },
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
        },
      ),
    );
  }
}
