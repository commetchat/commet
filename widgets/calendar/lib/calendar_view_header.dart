import 'package:commet_calendar_widget/main.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:tiamat/tiamat.dart' as tiamat;

class CalendarViewHeader extends StatelessWidget {
  const CalendarViewHeader({
    required this.mode,
    required this.date,
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

  String getHeaderText() {
    if (mode == CalendarViewMode.month) {
      var format = DateFormat(DateFormat.YEAR_MONTH);
      var result = format.format(date);

      if (secondaryDate != null) {
        result += " - ${format.format(secondaryDate!)}";
      }

      return result;
    } else {
      var format = DateFormat(DateFormat.YEAR_ABBR_MONTH_DAY);
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
    return Container(
      color: Theme.of(context).colorScheme.surfaceContainerLow,
      child: SizedBox(
        child: Row(
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
                tiamat.Tooltip(
                  text: "Day View",
                  preferredDirection: AxisDirection.down,
                  child: Opacity(
                    opacity: mode == CalendarViewMode.day ? 0.5 : 1,
                    child: IconButton(
                        onPressed: () =>
                            setViewMode?.call(CalendarViewMode.day),
                        icon: Icon(Icons.calendar_view_day)),
                  ),
                ),
                tiamat.Tooltip(
                  text: "Week View",
                  preferredDirection: AxisDirection.down,
                  child: Opacity(
                    opacity: mode == CalendarViewMode.week ? 0.5 : 1,
                    child: IconButton(
                      onPressed: () => setViewMode?.call(CalendarViewMode.week),
                      icon: Icon(Icons.calendar_view_week),
                    ),
                  ),
                ),
                tiamat.Tooltip(
                  text: "Month View",
                  preferredDirection: AxisDirection.down,
                  child: Opacity(
                    opacity: mode == CalendarViewMode.month ? 0.5 : 1,
                    child: IconButton(
                      onPressed: () =>
                          setViewMode?.call(CalendarViewMode.month),
                      icon: Icon(Icons.calendar_view_month),
                    ),
                  ),
                ),
                IconButton(
                  onPressed: nextPage,
                  icon: Icon(Icons.chevron_right),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
