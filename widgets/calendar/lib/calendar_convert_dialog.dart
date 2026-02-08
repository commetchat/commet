import 'package:commet_calendar_widget/calendar.dart';
import 'package:flutter/material.dart';

import 'package:tiamat/tiamat.dart' as tiamat;

class CalendarConvertDialog extends StatefulWidget {
  const CalendarConvertDialog(this.calendar, {super.key});
  final MatrixCalendar calendar;

  @override
  State<CalendarConvertDialog> createState() => _CalendarConvertDialogState();
}

class _CalendarConvertDialogState extends State<CalendarConvertDialog> {
  bool running = false;

  double? progress;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 300,
      child: Column(
        children: [
          tiamat.Text.body(
              "This calendar is storing data in an older format and needs to be converted"),
          if (running)
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: SizedBox(
                width: 50,
                height: 50,
                child: CircularProgressIndicator(
                  value: progress,
                ),
              ),
            ),
          if (!running)
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: 8,
              children: [
                tiamat.Button(
                  text: "Convert",
                  onTap: () {
                    setState(() {
                      running = true;
                    });

                    widget.calendar
                        .migrateRoomStateEvents(onProgress)
                        .then((_) {
                      Navigator.of(context).pop();
                    });
                  },
                ),
                tiamat.Button.secondary(
                  text: "Cancel",
                  onTap: () => Navigator.of(context).pop(),
                )
              ],
            )
        ],
      ),
    );
  }

  onProgress(int remaining, int total) {
    print("Progressed: ${remaining}/${total}");

    setState(() {
      progress = (total - remaining).toDouble() / total.toDouble();
    });
  }
}
