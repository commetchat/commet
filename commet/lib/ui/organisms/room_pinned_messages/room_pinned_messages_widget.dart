import 'package:commet/client/components/pinned_messages/pinned_messages_component.dart';
import 'package:commet/client/room.dart';
import 'package:commet/client/timeline_events/timeline_event.dart';
import 'package:commet/ui/molecules/timeline_events/timeline_event_view_single.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:tiamat/tiamat.dart' as tiamat;

class RoomPinnedMessagesWidget extends StatefulWidget {
  const RoomPinnedMessagesWidget(
      {required this.room, this.onEventClicked, super.key});
  final Room room;
  final void Function(String eventId)? onEventClicked;

  @override
  State<RoomPinnedMessagesWidget> createState() =>
      _RoomPinnedMessagesWidgetState();
}

class _RoomPinnedMessagesWidgetState extends State<RoomPinnedMessagesWidget> {
  List<TimelineEvent>? events;

  String get noPinnedMessages => Intl.message("No messages have been pinned!",
      desc:
          "Placeholder label in the pinned messages menu that is shown when there are no pinned messages",
      name: "noPinnedMessages");

  @override
  void initState() {
    super.initState();

    loadPinnedMessages();
  }

  @override
  Widget build(BuildContext context) {
    if (events == null) {
      return const tiamat.Tile(
          child: Center(child: CircularProgressIndicator()));
    }

    if (events!.isEmpty) {
      return tiamat.Tile(
          child: Center(child: tiamat.Text.label(noPinnedMessages)));
    }

    return tiamat.Tile.low(
      child: Column(
        children: [
          Flexible(
            child: ListView.builder(
              padding: EdgeInsets.all(0),
              itemCount: events!.length,
              itemBuilder: (context, index) {
                var data = events![index];
                return Padding(
                  padding: const EdgeInsets.fromLTRB(4, 2, 4, 2),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Material(
                        borderRadius: BorderRadius.circular(8),
                        child: InkWell(
                          onTap: () =>
                              widget.onEventClicked?.call(data.eventId),
                          child: Padding(
                            padding: const EdgeInsets.all(4.0),
                            child: TimelineEventViewSingle(
                                room: widget.room, event: data),
                          ),
                        )),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void loadPinnedMessages() async {
    final comp = widget.room.getComponent<PinnedMessagesComponent>()!;
    var eventIds = comp.getPinnedMessages();

    var allEvents = await Future.wait<TimelineEvent?>(
        eventIds.map((id) => widget.room.getEvent(id)));

    setState(() {
      events = List<TimelineEvent>.from(allEvents.where((e) => e != null));
    });
  }
}
