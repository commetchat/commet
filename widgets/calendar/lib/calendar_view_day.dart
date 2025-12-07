import 'package:calendar_view/calendar_view.dart';
import 'package:commet_calendar_widget/calendar.dart';
import 'package:commet_calendar_widget/calendar_view_header.dart';
import 'package:commet_calendar_widget/main.dart';
import 'package:flutter/material.dart';

class CalendarViewDay extends StatefulWidget {
  const CalendarViewDay({
    required this.calendar,
    required this.useMobileLayout,
    this.createEvent,
    this.setViewMode,
    this.onEventTapped,
    super.key,
  });
  final MatrixCalendar calendar;

  final Function(DateTime)? createEvent;
  final Function(CalendarViewMode)? setViewMode;
  final Function(MatrixCalendarEventState)? onEventTapped;
  final bool useMobileLayout;

  @override
  State<CalendarViewDay> createState() => _CalendarViewMonthState();
}

class _CalendarViewMonthState extends State<CalendarViewDay> {
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
                onDateTap: (date) => widget.createEvent?.call(date),
                fullDayEventBuilder: (events, date) {
                  return Row(
                    mainAxisSize: MainAxisSize.max,
                    children: events.map((e) {
                      return Expanded(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(2, 0, 2, 0),
                          child: Material(
                            clipBehavior: Clip.hardEdge,
                            borderRadius: BorderRadius.circular(8),
                            color: widget.calendar.config.processEventColor(
                              e.color,
                              context,
                            ),
                            child: Listener(
                              behavior: HitTestBehavior.opaque,
                              onPointerUp: (_) =>
                                  widget.onEventTapped?.call(e.event!),
                              child: InkWell(
                                onTap: () {},
                                child: Padding(
                                  padding:
                                      const EdgeInsets.fromLTRB(8, 2, 8, 2),
                                  child: Text(
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
                                ),
                              ),
                            ),
                          ),
                        ),
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
                    child: Opacity(
                      opacity: events.first.event?.loaded != true ? 0.3 : 1.0,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: ClipRect(
                          child: Material(
                            clipBehavior: Clip.hardEdge,
                            borderRadius: BorderRadius.circular(8),
                            color: widget.calendar.config.processEventColor(
                              event.color,
                              context,
                            ),
                            child: Listener(
                              behavior: HitTestBehavior.opaque,
                              onPointerUp: (_) =>
                                  widget.onEventTapped?.call(event.event!),
                              child: InkWell(
                                onTap: () {},
                                child: Stack(
                                  children: [
                                    Padding(
                                      padding:
                                          const EdgeInsets.fromLTRB(8, 4, 4, 0),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            event.title,
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
                                                    event.color,
                                                    context,
                                                  ),
                                                ),
                                          ),
                                          if (event.description != null &&
                                              boundary.height > 70)
                                            Text(
                                              maxLines: 3,
                                              event.description!,
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .bodySmall
                                                  ?.copyWith(
                                                    color: widget
                                                        .calendar.config
                                                        .processEventTextColor(
                                                      event.color,
                                                      context,
                                                    ),
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                  ),
                                            ),
                                        ],
                                      ),
                                    ),
                                    if (event.event?.remoteSourceId != null)
                                      Align(
                                        alignment:
                                            AlignmentGeometry.bottomRight,
                                        child: Padding(
                                          padding: const EdgeInsets.all(2.0),
                                          child: Container(
                                            child: Padding(
                                              padding:
                                                  const EdgeInsets.all(2.0),
                                              child: Icon(
                                                size: 10,
                                                Icons.satellite_alt,
                                                color: widget.calendar.config
                                                    .processEventTextColor(
                                                  event.color,
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
                        ),
                      ),
                    ),
                  );
                },
                onEventTap: (events, date) => print("Tapped event!"),
                liveTimeIndicatorSettings: LiveTimeIndicatorSettings(
                  color: Theme.of(context).colorScheme.primary,
                  showTime: true,
                  height: 2,
                  showTimeBackgroundView: false,
                ),
                dayTitleBuilder: (date) => CalendarViewHeader(
                  date: date,
                  useMobileLayout: widget.useMobileLayout,
                  mode: CalendarViewMode.day,
                  nextPage: () => key.currentState?.nextPage(),
                  prevPage: () => key.currentState?.previousPage(),
                  setViewMode: widget.setViewMode,
                ),
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
