import 'package:commet/ui/atoms/room_panel.dart';
import 'package:commet/utils/event_bus.dart';
import 'package:flutter/material.dart';
import 'package:commet/ui/atoms/notifying_list_builder.dart';

import 'package:commet/ui/pages/main/main_page.dart';

import 'package:tiamat/tiamat.dart' as tiamat;

class ImportantRoomsList extends StatelessWidget {
  const ImportantRoomsList({
    super.key,
    required this.state,
    required this.directMessagesListHeaderDesktop,
  });

  final MainPageState state;
  final String directMessagesListHeaderDesktop;

  @override
  Widget build(BuildContext context) {
    var padding = const EdgeInsets.fromLTRB(0, 4, 0, 4);

    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          NotifyingListBuilder(
            shrinkWrap: true,
            list: state.favoriteRooms,
            builder: (context, {required child, required list}) {
              if (list.isNotEmpty) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: tiamat.Text.labelLow("Favorites"),
                    ),
                    Padding(
                        padding: const EdgeInsetsGeometry.fromLTRB(3, 0, 0, 0),
                        child: child)
                  ],
                );
              }

              return child;
            },
            itemBuilder: (context, value) {
              return Padding(
                  padding: padding,
                  child: RoomPanel(
                    key: ValueKey("RoomFavoritesList-${value.localId}"),
                    value,
                    onTap: () {
                      EventBus.doOpenRoom(value.identifier,
                          clientId: value.client.identifier,
                          openInSpace: false);
                    },
                  ));
            },
          ),
          NotifyingListBuilder(
            shrinkWrap: true,
            list: state.directMessages,
            sortFunction: (p0, p1) {
              return p1.lastEventTimestamp.compareTo(p0.lastEventTimestamp);
            },
            builder: (context, {required child, required list}) {
              if (list.isNotEmpty) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: tiamat.Text.labelLow(
                            directMessagesListHeaderDesktop,
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: tiamat.IconButton(
                            icon: Icons.add,
                            onPressed: () {
                              state.searchUserToDm();
                            },
                          ),
                        ),
                      ],
                    ),
                    Padding(
                        padding: const EdgeInsetsGeometry.fromLTRB(3, 0, 0, 0),
                        child: child)
                  ],
                );
              }

              return child;
            },
            itemBuilder: (context, value) {
              return Padding(
                padding: padding,
                key: ValueKey("DirectMessagesList-${value.localId}"),
                child: RoomPanel(value),
              );
            },
          ),
        ],
      ),
    );
  }
}
