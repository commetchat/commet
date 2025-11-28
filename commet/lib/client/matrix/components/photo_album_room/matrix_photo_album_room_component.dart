import 'package:commet/client/components/photo_album_room/photo_album_room_component.dart';
import 'package:commet/client/components/photo_album_room/photo_album_timeline.dart';
import 'package:commet/client/matrix/components/matrix_sync_listener.dart';
import 'package:commet/client/matrix/components/photo_album_room/matrix_photo_album_timeline.dart';
import 'package:commet/client/matrix/components/photo_album_room/matrix_upload_photos_task.dart';
import 'package:commet/client/matrix/matrix_client.dart';
import 'package:commet/client/matrix/matrix_room.dart';
import 'package:commet/main.dart';
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

  static bool isPhotoAlbumRoom(MatrixRoom room) {
    return room.matrixRoom.getState(EventTypes.RoomCreate)?.content['type'] ==
        "chat.commet.photo_album";
  }

  @override
  bool get canUpload => room.permissions.canSendMessage;

  @override
  Future<PhotoAlbumTimeline> getTimeline() async {
    var timeline = MatrixPhotoAlbumTimeline(room);
    await timeline.initTimeline();
    return timeline;
  }

  @override
  Future<void> uploadPhotos(
    List<PickedPhoto> photos, {
    bool sendOriginal = false,
    bool extractMetadata = true,
  }) async {
    var task = MatrixUploadPhotosTask(
      photos,
      room,
      sendOriginal: sendOriginal,
      extractMetadata: extractMetadata,
    );
    backgroundTaskManager.addTask(task);
    await task.uploadImages();
  }
}
