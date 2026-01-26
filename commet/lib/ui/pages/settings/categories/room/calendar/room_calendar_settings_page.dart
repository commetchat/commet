import 'dart:async';

import 'package:commet/client/components/calendar_room/calendar_room_component.dart';
import 'package:commet/main.dart';
import 'package:commet/ui/navigation/adaptive_dialog.dart';
import 'package:commet/ui/pages/settings/categories/room/calendar/add_calendar_dialog.dart';
import 'package:flutter/material.dart';
import 'package:tiamat/atoms/tile.dart';
import 'package:tiamat/tiamat.dart' as tiamat;

class RoomCalendarSettingsPage extends StatefulWidget {
  const RoomCalendarSettingsPage(this.calendarComponent, {super.key});
  final CalendarRoom calendarComponent;
  @override
  State<RoomCalendarSettingsPage> createState() =>
      _RoomCalendarSettingsPageState();
}

class _RoomCalendarSettingsPageState extends State<RoomCalendarSettingsPage> {
  late Map<String, SyncedCalendar> syncedCalendarUrls;

  TextEditingController controller = TextEditingController();

  StreamSubscription? sub;

  bool runningSync = false;

  @override
  void initState() {
    syncedCalendarUrls = widget.calendarComponent.syncedCalendars.value ?? {};
    sub = widget.calendarComponent.syncedCalendars.stream.listen(
      (data) => setState(() {
        syncedCalendarUrls = data;
      }),
    );
    super.initState();
  }

  @override
  void dispose() {
    sub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return tiamat.Panel(
      mode: TileType.surfaceContainerLow,
      header: "Synced Calendars",
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListView.builder(
            shrinkWrap: true,
            itemCount: syncedCalendarUrls.length,
            itemBuilder: (context, index) {
              var remoteCalendarId = syncedCalendarUrls.keys.elementAt(index);
              return Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  mainAxisSize: MainAxisSize.max,
                  children: [
                    SizedBox(
                      width: 30,
                      height: 30,
                      child: tiamat.IconButton(
                        icon: Icons.delete,
                        onPressed: () {
                          AdaptiveDialog.confirmation(context).then((v) {
                            if (v == true) {
                              widget.calendarComponent.removeSyncedCalendar(
                                remoteCalendarId,
                              );
                            }
                          });
                        },
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child:
                          buildSyncEntry(syncedCalendarUrls[remoteCalendarId]!),
                    ),
                  ],
                ),
              );
            },
          ),
          SizedBox(
            height: 50,
            child: Row(
              mainAxisSize: MainAxisSize.max,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                SizedBox(
                  height: 50,
                  width: 50,
                  child: tiamat.IconButton(
                    icon: Icons.add,
                    onPressed: () => AdaptiveDialog.pickOne(
                      context,
                      title: "Sync Calendar Source",
                      items: [
                        //  CalendarSource.room,
                        CalendarSource.ical,
                      ],
                      itemBuilder: (context, item, callback) {
                        var text = switch (item) {
                          CalendarSource.ical => "Calendar Url",
                          CalendarSource.room => "Room",
                        };

                        var icon = switch (item) {
                          CalendarSource.ical => Icons.calendar_month,
                          CalendarSource.room => Icons.tag,
                        };
                        return SizedBox(
                          height: 50,
                          child: tiamat.TextButton(
                            text,
                            icon: icon,
                            onTap: callback,
                          ),
                        );
                      },
                    ).then((type) {
                      switch (type) {
                        case CalendarSource.ical:
                          AdaptiveDialog.show(context,
                              builder: (context) => AddRemoteCalendarDialog(
                                  widget.calendarComponent));
                        case CalendarSource.room:
                          // TODO: Handle this case.
                          throw UnimplementedError();
                        case _:
                          break;
                      }
                    }),
                  ),
                ),
                if (syncedCalendarUrls.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Align(
                      alignment: AlignmentGeometry.centerRight,
                      child: tiamat.Button.secondary(
                        text: "Run Sync",
                        isLoading: runningSync,
                        onTap: () {
                          setState(() {
                            runningSync = true;
                          });

                          widget.calendarComponent.runCalendarSync().then((_) {
                            setState(() {
                              runningSync = false;
                            });
                          });
                        },
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget buildSyncEntry(SyncedCalendar calendar) {
    var description = switch (calendar.sourceType) {
      CalendarSource.ical => Uri.parse(calendar.source).host,
      CalendarSource.room => "Room ${calendar.source}",
    };

    var entryStyle = Theme.of(context).textTheme.bodyMedium!.copyWith(
          color: Theme.of(context).colorScheme.secondary,
          fontWeight: FontWeight.w400,
          fontSize: 12,
        );

    return RichText(
      text: TextSpan(children: [
        TextSpan(text: description),
        TextSpan(text: " as ", style: entryStyle),
        TextSpan(
          text: switch (calendar.syncType) {
            CalendarSyncType.events => "Events",
            CalendarSyncType.unavailability => "Unavailability",
          },
        ),
        if (calendar.overrideEventName != null)
          TextSpan(text: " with name ", style: entryStyle),
        if (calendar.overrideEventName != null)
          TextSpan(text: "'${calendar.overrideEventName!}'"),
        if (preferences.developerMode)
          TextSpan(text: " (${calendar.id})", style: entryStyle)
      ]),
    );
  }
}
