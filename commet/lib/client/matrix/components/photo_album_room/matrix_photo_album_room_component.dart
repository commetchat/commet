import 'package:commet/client/components/photo_album_room/photo_album_room_component.dart';
import 'package:commet/client/components/photo_album_room/photo_album_timeline.dart';
import 'package:commet/client/matrix/components/matrix_sync_listener.dart';
import 'package:commet/client/matrix/components/photo_album_room/matrix_photo_album_timeline.dart';
import 'package:commet/client/matrix/matrix_client.dart';
import 'package:commet/client/matrix/matrix_room.dart';
import 'package:matrix/matrix.dart';

class MatrixPhotoAlbumRoomComponent
    implements
        PhotoAlbumRoom<MatrixClient, MatrixRoom>,
        MatrixRoomSyncListener {
  @override
  MatrixClient client;

  @override
  MatrixRoom room;

  MatrixPhotoAlbumRoomComponent(this.client, this.room);

  @override
  onSync(JoinedRoomUpdate update) {}

  @override
  bool get isPhotoAlbum =>
      room.matrixRoom.getState(EventTypes.RoomCreate)?.content['type'] ==
      "chat.commet.photo_album";

  @override
  bool get canUpload => room.permissions.canSendMessage;

  @override
  Future<PhotoAlbumTimeline> getTimeline() async {
    var timeline = MatrixPhotoAlbumTimeline(room);
    await timeline.initTimeline();
    return timeline;
  }
}
