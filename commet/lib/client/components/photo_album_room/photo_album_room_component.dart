import 'package:commet/client/client.dart';
import 'package:commet/client/components/photo_album_room/photo_album_timeline.dart';
import 'package:commet/client/components/room_component.dart';

abstract class PhotoAlbumRoom<R extends Client, T extends Room>
    implements RoomComponent<R, T> {
  bool get isPhotoAlbum;

  bool get canUpload;

  Future<PhotoAlbumTimeline> getTimeline();
}
