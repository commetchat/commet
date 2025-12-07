import 'package:calendar_view/calendar_view.dart';
import 'package:commet_calendar_widget/calendar.dart';
import 'package:commet_calendar_widget/calendar_view_header.dart';
import 'package:commet_calendar_widget/main.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class CalendarViewWeek extends StatefulWidget {
  const CalendarViewWeek({
    required this.calendar,
    required this.useMobileLayout,
    super.key,
    this.createEvent,
    this.setViewMode,
  });

  final Function(DateTime)? createEvent;
  final Function(CalendarViewMode)? setViewMode;
  final bool useMobileLayout;

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
                    showTime: true,
                    height: 2,
                    showTimeBackgroundView: false,
                  ),
                  weekDayBuilder: (date) {
                    var now = DateTime.now();
                    bool isToday = date.year == now.year &&
                        date.month == now.month &&
                        date.day == now.day;
                    var format = DateFormat('EEEE').format(date);

                    return Container(
                      color: colorScheme.surfaceContainerLow,
                      child: Padding(
                        padding: const EdgeInsets.all(0.0),
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(15),
                            color: isToday
                                ? colorScheme.primary
                                : Colors.transparent,
                          ),
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
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                              color: widget.calendar.config.processEventColor(
                                e.color,
                                context,
                              ),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(8, 2, 8, 2),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    e.title,
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodySmall
                                        ?.copyWith(
                                          color: widget.calendar.config
                                              .processEventTextColor(
                                            e.color,
                                            context,
                                          ),
                                        ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    );
                  },
                  timeLineWidth: 80,
                  onDateTap: (date) => widget.createEvent?.call(date),
                  weekNumberBuilder: (firstDayOfWeek) =>
                      Container(color: colorScheme.surfaceContainerLow),
                  eventTileBuilder:
                      (date, events, boundary, startDuration, endDuration) {
                    var aspectRatio = boundary.width / boundary.height;

                    bool rotate = aspectRatio < 0.7 && boundary.width < 50;
                    return Padding(
                      padding: const EdgeInsets.fromLTRB(2, 2, 2, 0),
                      child: Opacity(
                        opacity: events.first.event?.loaded != true ? 0.3 : 1.0,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            color: widget.calendar.config.processEventColor(
                              events.first.color,
                              context,
                            ),
                          ),
                          child: ClipRect(
                            child: Stack(
                              children: [
                                RotatedBox(
                                  quarterTurns: rotate ? 1 : 0,
                                  child: Padding(
                                    padding:
                                        const EdgeInsets.fromLTRB(8, 1, 4, 0),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          events.first.title,
                                          maxLines: ((boundary.height - 11)
                                                      .toInt() /
                                                  (12 +
                                                      1)) // 11 calculated as sum of all top and bottom padding,  then divide by font size + 1
                                              .toInt(),
                                          overflow: TextOverflow.ellipsis,
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodySmall
                                              ?.copyWith(
                                                fontSize: 12,
                                                color: widget.calendar.config
                                                    .processEventTextColor(
                                                  events.first.color,
                                                  context,
                                                ),
                                              ),
                                        ),
                                        if (events.first.description != null &&
                                            boundary.height > 70)
                                          Text(
                                            maxLines: 3,
                                            events.first.description!,
                                            style: Theme.of(context)
                                                .textTheme
                                                .bodySmall
                                                ?.copyWith(
                                                  color: widget.calendar.config
                                                      .processEventTextColor(
                                                    events.first.color,
                                                    context,
                                                  ),
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                          ),
                                      ],
                                    ),
                                  ),
                                ),
                                if (events.first.event?.remoteSourceId != null)
                                  Align(
                                    alignment: AlignmentGeometry.bottomRight,
                                    child: Padding(
                                      padding: const EdgeInsets.all(2.0),
                                      child: Container(
                                        color: widget.calendar.config
                                            .processEventColor(
                                          events.first.color,
                                          context,
                                        ),
                                        child: Padding(
                                          padding: const EdgeInsets.all(2.0),
                                          child: Icon(
                                            size: 10,
                                            Icons.satellite_alt,
                                            color: widget.calendar.config
                                                .processEventTextColor(
                                              events.first.color,
                                              context,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                  backgroundColor: Theme.of(context).colorScheme.surface,
                  onPageChange: (date, pageIndex) => print("$date, $pageIndex"),
                  onEventTap: (event, date) => print(event),
                  onEventDoubleTap: (events, date) => print(events),
                  onEventLongTap: (event, date) => print(event),
                  onDateLongPress: (date) => print(date),
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
