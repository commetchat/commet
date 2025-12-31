import 'package:commet_calendar_widget/main.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:tiamat/tiamat.dart' as tiamat;

class CalendarViewHeader extends StatelessWidget {
  const CalendarViewHeader({
    required this.mode,
    required this.date,
    required this.useMobileLayout,
    this.secondaryDate,
    this.prevPage,
    this.nextPage,
    this.setViewMode,
    super.key,
  });
  final CalendarViewMode mode;
  final DateTime date;
  final DateTime? secondaryDate;

  final Function()? nextPage;
  final Function()? prevPage;
  final Function(CalendarViewMode)? setViewMode;
  final bool useMobileLayout;
  String getHeaderText() {
    if (mode == CalendarViewMode.month) {
      var format = DateFormat(DateFormat.YEAR_MONTH);
      var result = format.format(date);

      if (secondaryDate != null) {
        result += " - ${format.format(secondaryDate!)}";
      }

      return result;
    } else {
      var format = mode == CalendarViewMode.day
          ? DateFormat(DateFormat.YEAR_ABBR_MONTH_WEEKDAY_DAY)
          : DateFormat(DateFormat.YEAR_ABBR_MONTH_DAY);
      var result = format.format(date);
      var now = DateTime.now();
      if (secondaryDate == null &&
          (date.day == now.day &&
              date.month == now.month &&
              date.year == now.year)) {
        result = "Today (${result})";
      }

      if (secondaryDate != null) {
        result += " - ${format.format(secondaryDate!)}";
      }

      return result;
    }
  }

  @override
  Widget build(BuildContext context) {
    var result = useMobileLayout
        ? buildMobileLayout(context)
        : buildDesktopLayout(context);
    return Container(
      color: Theme.of(context).colorScheme.surfaceContainerLow,
      child: SizedBox(
        child: result,
      ),
    );
  }

  Widget buildMobileLayout(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 0, 0, 0),
          child: Text(getHeaderText()),
        ),
        Align(
            alignment: AlignmentGeometry.centerRight,
            child: createLayoutButtons(context)),
      ],
    );
  }

  Widget buildDesktopLayout(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            IconButton(onPressed: prevPage, icon: Icon(Icons.chevron_left)),
            Opacity(
              opacity: 0,
              child: IgnorePointer(
                child: Row(
                  children: [
                    IconButton(onPressed: () {}, icon: Icon(Icons.abc)),
                    IconButton(onPressed: () {}, icon: Icon(Icons.abc)),
                    IconButton(onPressed: () {}, icon: Icon(Icons.abc))
                  ],
                ),
              ),
            ),
          ],
        ),
        Text(getHeaderText()),
        Row(
          children: [
            createLayoutButtons(context),
            IconButton(
              onPressed: nextPage,
              icon: Icon(Icons.chevron_right),
            ),
          ],
        ),
      ],
    );
  }

  Widget createLayoutButtons(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        tiamat.Tooltip(
          text: "Day View",
          preferredDirection: AxisDirection.down,
          child: IconButton(
              onPressed: () => setViewMode?.call(CalendarViewMode.day),
              icon: Icon(
                  color: mode == CalendarViewMode.day
                      ? Theme.of(context).colorScheme.primary
                      : null,
                  Icons.calendar_view_day)),
        ),
        tiamat.Tooltip(
          text: "Week View",
          preferredDirection: AxisDirection.down,
          child: IconButton(
            onPressed: () => setViewMode?.call(CalendarViewMode.week),
            icon: Icon(
                color: mode == CalendarViewMode.week
                    ? Theme.of(context).colorScheme.primary
                    : null,
                Icons.calendar_view_week),
          ),
        ),
        tiamat.Tooltip(
          text: "Month View",
          preferredDirection: AxisDirection.down,
          child: IconButton(
            onPressed: () => setViewMode?.call(CalendarViewMode.month),
            icon: Icon(
                color: mode == CalendarViewMode.month
                    ? Theme.of(context).colorScheme.primary
                    : null,
                Icons.calendar_view_month),
          ),
        ),
      ],
    );
  }
}
