import 'package:commet/client/components/calendar_room/calendar_room_component.dart';
import 'package:commet/debug/log.dart';
import 'package:commet/utils/debounce.dart';
import 'package:commet_calendar_widget/rfc8984.dart';
import 'package:flutter/material.dart';
import 'package:tiamat/tiamat.dart' as tiamat;

class AddRemoteCalendarDialog extends StatefulWidget {
  const AddRemoteCalendarDialog(this.component, {super.key});
  final CalendarRoom component;
  @override
  State<AddRemoteCalendarDialog> createState() =>
      _AddRemoteCalendarDialogState();
}

class _AddRemoteCalendarDialogState extends State<AddRemoteCalendarDialog> {
  String url = "";
  String eventName = "";
  String? error;

  CalendarSyncType eventType = CalendarSyncType.events;

  Debouncer fetchEventsDebouncer = Debouncer(delay: Duration(seconds: 1));

  bool loading = false;
  List<RFC8984CalendarEvent>? events;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 300,
      width: 400,
      child: Column(
        spacing: 12,
        mainAxisSize: MainAxisSize.max,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            spacing: 12,
            mainAxisSize: MainAxisSize.max,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                onChanged: (value) => setState(() {
                  url = value;
                  events = null;
                  error = null;

                  if (url.isNotEmpty) {
                    loading = true;
                    fetchEventsDebouncer.run(() {
                      fetchEvents();
                    });
                  } else {
                    fetchEventsDebouncer.cancel();
                    loading = false;
                    events = null;
                  }
                  print(url);
                }),
                decoration: InputDecoration(labelText: "Calendar Url"),
              ),
              TextFormField(
                  onChanged: (value) => setState(() {
                        eventName = value;
                      }),
                  decoration: InputDecoration(
                      labelText: "Event Name Override (Optional)")),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(0, 0, 0, 4),
                    child: tiamat.Text.labelLow("Sync as:"),
                  ),
                  SegmentedButton(
                    emptySelectionAllowed: true,
                    multiSelectionEnabled: false,
                    showSelectedIcon: false,
                    segments: [
                      ButtonSegment(
                          value: CalendarSyncType.events,
                          label: Text("Events")),
                      ButtonSegment(
                          value: CalendarSyncType.unavailability,
                          label: Text("Unavailability")),
                    ],
                    expandedInsets: EdgeInsets.all(0),
                    selected: {eventType},
                    onSelectionChanged: (a) => setState(() {
                      eventType = a.first;
                    }),
                  ),
                ],
              ),
              if (events != null && events!.isNotEmpty)
                Center(
                    child:
                        tiamat.Text.labelLow("Found ${events!.length} events")),
              if (loading) Center(child: CircularProgressIndicator()),
              if (error != null) tiamat.Text.error(error!)
            ],
          ),
          tiamat.Button(
            text: "Add Calendar",
            onTap: () async {
              setState(() {
                loading = true;
              });

              await widget.component.addSyncedCalendar(SyncedCalendar(
                  url, CalendarSource.ical, eventType,
                  overrideEventName: eventName.isNotEmpty ? eventName : null));

              Navigator.of(context).pop();
            },
          )
        ],
      ),
    );
  }

  void fetchEvents() async {
    try {
      var results = await widget.component.getEventsFromIcsUrl(Uri.parse(url));

      setState(() {
        loading = false;
        events = results;
      });
    } catch (e, trace) {
      Log.onError(e, trace, content: "Error while loading calendar");
      setState(() {
        loading = false;
        error = e.toString();
      });
    }
  }
}
