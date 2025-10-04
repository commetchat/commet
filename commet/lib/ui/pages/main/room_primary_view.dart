import 'package:commet/client/components/photo_album_room/photo_album_room_component.dart';
import 'package:commet/client/components/voip_room/voip_room_component.dart';
import 'package:commet/client/room.dart';
import 'package:commet/main.dart';
import 'package:commet/ui/organisms/call_view/call.dart';
import 'package:commet/ui/organisms/call_view/call_view.dart';
import 'package:commet/ui/organisms/chat/chat.dart';
import 'package:commet/ui/organisms/photo_albums/photo_album_view.dart';
import 'package:commet/ui/organisms/voip_room_view/voip_room_view.dart';
import 'package:flutter/material.dart';

class RoomPrimaryView extends StatelessWidget {
  const RoomPrimaryView(this.room, {super.key});
  final Room room;

  @override
  Widget build(BuildContext context) {
    var photos = room.getComponent<PhotoAlbumRoom>();
    var voip = room.getComponent<VoipRoomComponent>();

    if (voip?.isVoipRoom == true) {
      return VoipRoomView(voip!);
    }

    if (photos?.isPhotoAlbum == true) {
      return PhotoAlbumView(photos!);
    }

    final call =
        clientManager?.callManager.getCallInRoom(room.client, room.identifier);

    return Column(
      children: [
        if (call != null) Flexible(child: CallWidget(call)),
        Flexible(
          child: Chat(
            room,
            key: ValueKey("room-timeline-key-${room.localId}"),
          ),
        ),
      ],
    );
  }
}
