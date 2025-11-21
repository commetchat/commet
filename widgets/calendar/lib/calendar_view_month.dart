import 'package:calendar_view/calendar_view.dart';
import 'package:commet_calendar_widget/calendar.dart';
import 'package:commet_calendar_widget/calendar_view_header.dart';
import 'package:commet_calendar_widget/main.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class CalendarViewMonth extends StatefulWidget {
  const CalendarViewMonth({
    required this.calendar,
    this.createEvent,
    this.setViewMode,
    super.key,
  });
  final MatrixCalendar calendar;

  final Function(DateTime)? createEvent;
  final Function(CalendarViewMode)? setViewMode;

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
      child: MonthView(
        key: key,
        pageViewPhysics: NeverScrollableScrollPhysics(),
        safeAreaOption: SafeAreaOption(
          left: false,
          right: false,
          top: false,
          bottom: false,
        ),
        weekDayBuilder: (day) {
          return DecoratedBox(
            decoration: BoxDecoration(color: colorScheme.surfaceContainerLow),
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
          mode: CalendarViewMode.month,
          date: date,
          nextPage: () => key.currentState?.nextPage(),
          prevPage: () => key.currentState?.previousPage(),
          setViewMode: widget.setViewMode,
        ),
        cellBuilder: (date, event, isToday, isInMonth, hideDaysNotInMonth) {
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
                  onTap: () => widget.createEvent?.call(date.copyWith(hour: 9)),
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
                                    : Theme.of(context).textTheme.bodySmall,
                              ),
                            ),
                          ),
                        ),
                      ),
                      if (event.isNotEmpty)
                        Expanded(
                          child: SingleChildScrollView(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              mainAxisSize: MainAxisSize.max,
                              children: event
                                  .map(
                                    (e) => Padding(
                                      padding: const EdgeInsets.fromLTRB(
                                        2,
                                        0,
                                        2,
                                        2,
                                      ),
                                      child: Opacity(
                                        opacity: e.event?.loaded != true
                                            ? 0.3
                                            : 1.0,
                                        child: DecoratedBox(
                                          decoration: BoxDecoration(
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                            color: widget.calendar.config
                                                .processEventColor(
                                                  e.color,
                                                  context,
                                                ),
                                          ),
                                          child: Padding(
                                            padding: const EdgeInsets.fromLTRB(
                                              8,
                                              2,
                                              8,
                                              2,
                                            ),
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  e.title,
                                                  style: Theme.of(context)
                                                      .textTheme
                                                      .bodySmall
                                                      ?.copyWith(
                                                        fontSize: 10,
                                                        color: widget
                                                            .calendar
                                                            .config
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
                                      ),
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
    );
  }
}
