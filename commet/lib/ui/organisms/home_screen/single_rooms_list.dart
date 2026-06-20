import 'package:commet/client/room.dart';
import 'package:commet/main.dart';
import 'package:commet/ui/atoms/notifying_list_builder.dart';
import 'package:commet/ui/atoms/room_panel.dart';
import 'package:commet/ui/atoms/scaled_safe_area.dart';
import 'package:commet/ui/pages/get_or_create_room/get_or_create_room.dart';
import 'package:commet/ui/pages/main/main_page.dart';
import 'package:flutter/material.dart';

import 'package:tiamat/tiamat.dart' as tiamat;

class SingleRoomsList extends StatelessWidget {
  const SingleRoomsList({required this.state, this.onSelectRoom, super.key});
  final MainPageState state;
  final Function(Room room)? onSelectRoom;

  @override
  Widget build(BuildContext context) {
    var padding = const EdgeInsets.fromLTRB(0, 4, 0, 4);

    return ScaledSafeArea(
        top: true,
        bottom: false,
        child: SingleChildScrollView(
          child: NotifyingListBuilder(
            sortFunction: (p0, p1) {
              return (p1.lastEventTimestamp.compareTo(p0.lastEventTimestamp));
            },
            shrinkWrap: true,
            list: state.singleRooms,
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
                            "Rooms",
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: tiamat.IconButton(
                            icon: Icons.add,
                            onPressed: () {
                              GetOrCreateRoom.show(null, context,
                                  pickExisting: false, showAllRoomTypes: true);
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
                  child: RoomPanel(
                      shouldShowAvatarForRoom: (room) =>
                          clientManager!.clients
                              .where((i) => i.hasRoom(room.identifier))
                              .length >
                          1,
                      key: ValueKey("SingleRoomsList-${value.localId}"),
                      value,
                      onTap: () {
                        onSelectRoom?.call(value);
                      }));
            },
          ),
        ));
  }
}
