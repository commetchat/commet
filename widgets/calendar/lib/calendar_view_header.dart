import 'package:commet_calendar_widget/main.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

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

      if (secondaryDate != null) {
        result += " - ${format.format(secondaryDate!)}";
      }

      return result;
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(onPressed: prevPage, icon: Icon(Icons.chevron_left)),
          Text(getHeaderText()),
          Row(
            children: [
              if (mode != CalendarViewMode.month)
                IconButton(
                  onPressed: () => setViewMode?.call(CalendarViewMode.month),
                  icon: Icon(Icons.calendar_view_month),
                ),
              if (mode != CalendarViewMode.week)
                IconButton(
                  onPressed: () => setViewMode?.call(CalendarViewMode.week),
                  icon: Icon(Icons.calendar_view_week),
                ),
              IconButton(onPressed: nextPage, icon: Icon(Icons.chevron_right)),
            ],
          ),
        ],
      ),
    );
  }
}
