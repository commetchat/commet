import 'dart:async';

import 'package:commet/client/client.dart';
import 'package:commet/client/components/event_search/event_search_component.dart';
import 'package:commet/client/timeline_events/timeline_event.dart';
import 'package:commet/ui/molecules/timeline_events/timeline_event_view_single.dart';
import 'package:commet/utils/debounce.dart';
import 'package:flutter/material.dart';
import 'package:implicitly_animated_list/implicitly_animated_list.dart';
import 'package:tiamat/tiamat.dart' as tiamat;

class RoomEventSearchWidget extends StatefulWidget {
  const RoomEventSearchWidget(
      {required this.room, this.close, this.onEventClicked, super.key});
  final Room room;
  final void Function()? close;
  final void Function(String eventId)? onEventClicked;

  @override
  State<RoomEventSearchWidget> createState() => _RoomEventSearchWidgetState();
}

class _RoomEventSearchWidgetState extends State<RoomEventSearchWidget> {
  TextEditingController controller = TextEditingController();
  EventSearchSession? searchSession;

  Stream? currentStream;
  StreamSubscription? currentSubscription;
  List<TimelineEvent>? currentResults;

  Debouncer debouncer = Debouncer(delay: const Duration(seconds: 1));

  bool loading = false;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    currentSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        tiamat.Tile(
          child: Row(
            children: [
              Flexible(
                child: Padding(
                  padding: const EdgeInsets.all(1.0),
                  child: TextField(
                    autofocus: true,
                    onChanged: onTextChanged,
                    style: Theme.of(context).textTheme.bodyMedium!,
                    controller: controller,
                    decoration: InputDecoration(
                        hintText: "Search",
                        prefix: const SizedBox(
                          width: 10,
                        ),
                        suffix: loading
                            ? const SizedBox(
                                width: 15,
                                height: 15,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ))
                            : null,
                        contentPadding: const EdgeInsets.fromLTRB(8, 0, 8, 0)),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 0, 8, 0),
                child: tiamat.IconButton(
                  icon: Icons.close,
                  size: 20,
                  onPressed: widget.close,
                ),
              )
            ],
          ),
        ),
        if (currentResults != null)
          Flexible(
            child: ClipRect(
              child: ImplicitlyAnimatedList(
                itemEquality: (a, b) => a.eventId == b.eventId,
                itemData: currentResults!,
                itemBuilder: (context, data) {
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
          ),
      ],
    );
  }

  void onTextChanged(String value) {
    setState(() {
      currentResults = null;
      currentSubscription?.cancel();
      searchSession = null;
      currentStream = null;
      currentResults = null;
    });

    if (value.trim().isEmpty) {
      setState(() {
        debouncer.cancel();
        loading = false;
      });
    } else {
      debouncer.run(() => startSearch(value));
      setState(() {
        loading = debouncer.running;
      });
    }
  }

  void startSearch(String value) async {
    var search = widget.room.client.getComponent<EventSearchComponent>()!;

    searchSession = await search.createSearchSession(widget.room);
    var stream = searchSession!.startSearch(value);
    currentSubscription = stream.listen(onResultsChanged);
  }

  void onResultsChanged(List<TimelineEvent<Client>> results) {
    setState(() {
      loading = searchSession?.currentlySearching == true;
      currentResults = results;
    });
  }
}
