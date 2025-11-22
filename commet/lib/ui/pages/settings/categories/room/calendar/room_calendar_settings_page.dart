import 'dart:async';

import 'package:commet/client/components/calendar_room/calendar_room_component.dart';
import 'package:commet/ui/navigation/adaptive_dialog.dart';
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
  late Map<String, String> syncedCalendarUrls;

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

  addIcsUrl() {
    var text = controller.text;

    print(text);

    widget.calendarComponent.addSyncedCalendar(text);

    controller.text = "";
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
                      child: tiamat.Text(
                        Uri.parse(syncedCalendarUrls[remoteCalendarId]!).host,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          SizedBox(
            height: 50,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: TextFormField(
                    controller: controller,
                    decoration: InputDecoration(labelText: "ICS Url"),
                  ),
                ),
                SizedBox(
                  height: 50,
                  width: 50,
                  child: tiamat.IconButton(
                    icon: Icons.add,
                    onPressed: addIcsUrl,
                  ),
                ),
              ],
            ),
          ),
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
    );
  }
}
