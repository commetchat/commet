import 'package:calendar_view/calendar_view.dart';
import 'package:commet_calendar_widget/calendar.dart';
import 'package:commet_calendar_widget/calendar_view_header.dart';
import 'package:commet_calendar_widget/event_view.dart';
import 'package:commet_calendar_widget/main.dart';
import 'package:flutter/material.dart';

class CalendarViewMonth extends StatefulWidget {
  const CalendarViewMonth({
    required this.calendar,
    required this.useMobileLayout,
    this.createEvent,
    this.setViewMode,
    this.onEventTapped,
    this.onPageChanged,
    this.initialDate,
    super.key,
  });
  final MatrixCalendar calendar;
  final bool useMobileLayout;
  final DateTime? initialDate;
  final Function(DateTime)? createEvent;
  final Function(CalendarViewMode)? setViewMode;
  final Function(MatrixCalendarEventState)? onEventTapped;
  final Function(DateTime)? onPageChanged;

  @override
  State<CalendarViewMonth> createState() => _CalendarViewMonthState();
}

class _CalendarViewMonthState extends State<CalendarViewMonth> {
  var key = GlobalKey<MonthViewState>();

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
      child: Stack(
        children: [
          Padding(
            padding:
                EdgeInsets.fromLTRB(0, 0, 0, widget.useMobileLayout ? 80 : 0),
            child: MonthView(
              initialMonth: widget.initialDate,
              key: key,
              safeAreaOption: SafeAreaOption(
                left: false,
                right: false,
                top: false,
                bottom: false,
              ),
              onPageChange: (date, page) {
                widget.onPageChanged?.call(date);
              },
              weekDayBuilder: (day) {
                return DecoratedBox(
                  decoration:
                      BoxDecoration(color: colorScheme.surfaceContainerLow),
                  child: SizedBox(
                    height: 30,
                    child: Center(
                      child: Text(
                        "MTWTFSS".characters.elementAt(day).toString(),
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                  ),
                );
              },
              controller: widget.calendar.controller,
              useAvailableVerticalSpace: true,
              borderColor: colorScheme.surfaceContainer,
              headerStyle: headerStyle,
              headerBuilder: (date) => CalendarViewHeader(
                useMobileLayout: widget.useMobileLayout,
                mode: CalendarViewMode.month,
                date: date,
                nextPage: () => key.currentState?.nextPage(),
                prevPage: () => key.currentState?.previousPage(),
                setViewMode: widget.setViewMode,
              ),
              cellBuilder:
                  (date, event, isToday, isInMonth, hideDaysNotInMonth) {
                return DecoratedBox(
                  decoration: BoxDecoration(
                    color: isInMonth
                        ? colorScheme.surface
                        : colorScheme.surfaceContainerLow,
                  ),
                  child: Opacity(
                    opacity: isInMonth ? 1 : 0.4,
                    child: Material(
                      child: InkWell(
                        mouseCursor: SystemMouseCursors.basic,
                        onTap: () =>
                            widget.createEvent?.call(date.copyWith(hour: 9)),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.max,
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(2.0),
                              child: DecoratedBox(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(15),
                                  color: isToday
                                      ? colorScheme.primary
                                      : Colors.transparent,
                                ),
                                child: SizedBox(
                                  width: 30,
                                  height: 30,
                                  child: Center(
                                    child: Text(
                                      date.day.toString(),
                                      style: isToday
                                          ? Theme.of(
                                              context,
                                            ).textTheme.bodyLarge?.copyWith(
                                                color: isToday
                                                    ? colorScheme.onPrimary
                                                    : null,
                                              )
                                          : Theme.of(context)
                                              .textTheme
                                              .bodySmall,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            if (event.isNotEmpty)
                              Expanded(
                                child: SingleChildScrollView(
                                  child: Column(
                                    spacing: 3,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.stretch,
                                    mainAxisSize: MainAxisSize.max,
                                    children: event
                                        .map(
                                          (e) => EventViewMini(
                                            e,
                                            widget.calendar,
                                            onEventTapped: widget.onEventTapped,
                                          ),
                                        )
                                        .toList(),
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
      ),
    );
  }
}
