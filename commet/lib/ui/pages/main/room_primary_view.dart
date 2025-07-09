import 'package:commet/client/components/photo_album_room/photo_album_room_component.dart';
import 'package:commet/client/room.dart';
import 'package:commet/ui/organisms/chat/chat.dart';
import 'package:commet/ui/organisms/photo_albums/photo_album_view.dart';
import 'package:flutter/material.dart';

class RoomPrimaryView extends StatelessWidget {
  const RoomPrimaryView(this.room, {super.key});
  final Room room;

  @override
  Widget build(BuildContext context) {
    var photos = room.getComponent<PhotoAlbumRoom>();
    if (photos?.isPhotoAlbum == true) {
      return PhotoAlbumView(photos!);
    }

    return Chat(
      room,
      key: ValueKey("room-timeline-key-${room.localId}"),
    );
  }
}
