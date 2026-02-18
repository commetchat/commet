import 'package:commet/client/components/calendar_room/calendar_room_component.dart';
import 'package:commet/client/components/photo_album_room/photo_album_room_component.dart';
import 'package:commet/client/components/voip_room/voip_room_component.dart';
import 'package:commet/client/room.dart';
import 'package:commet/main.dart';
import 'package:commet/ui/atoms/scaled_safe_area.dart';
import 'package:commet/ui/organisms/calendar_view/calendar_room_view.dart';
import 'package:commet/ui/organisms/call_view/call.dart';
import 'package:commet/ui/organisms/chat/chat.dart';
import 'package:commet/ui/organisms/photo_albums/photo_album_view.dart';
import 'package:commet/ui/organisms/voip_room_view/voip_room_view.dart';
import 'package:flutter/material.dart';

class RoomPrimaryView extends StatelessWidget {
  const RoomPrimaryView(this.room,
      {super.key, this.bypassSpecialRoomTypes = false});
  final Room room;
  final bool bypassSpecialRoomTypes;

  @override
  Widget build(BuildContext context) {
    if (!bypassSpecialRoomTypes) {
      var photos = room.getComponent<PhotoAlbumRoom>();
      var voip = room.getComponent<VoipRoomComponent>();
      var calendar = room.getComponent<CalendarRoom>();

      var key = ValueKey("room-primary-view-${room.localId}");

      if (voip != null) {
        return ScaledSafeArea(
          bottom: true,
          top: false,
          child: VoipRoomView(
            voip,
            key: key,
          ),
        );
      }

      if (photos != null) {
        return PhotoAlbumView(
          photos,
          key: key,
        );
      }

      if (calendar?.isCalendarRoom == true) {
        return CalendarRoomView(
          calendar!,
          key: key,
        );
      }
    }

    final call = clientManager.callManager.getCallInRoom(
      room.client,
      room.roomId,
    );

    return Column(
      children: [
        if (call != null) Flexible(child: CallWidget(call)),
        Flexible(
          child: Chat(room, key: key),
        ),
      ],
    );
  }
}
