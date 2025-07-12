import 'dart:typed_data';

import 'package:commet/client/client.dart';
import 'package:commet/client/components/photo_album_room/photo_album_timeline.dart';
import 'package:commet/client/components/room_component.dart';

class PickedPhoto {
  String? filepath;
  String name;
  final Future<Uint8List> Function() getBytes;

  PickedPhoto({this.filepath, required this.name, required this.getBytes});
}

abstract class PhotoAlbumRoom<R extends Client, T extends Room>
    implements RoomComponent<R, T> {
  bool get isPhotoAlbum;

  bool get canUpload;

  Future<void> uploadPhotos(List<PickedPhoto> photos,
      {bool sendOriginal = false, bool extractMetadata = true});

  Future<PhotoAlbumTimeline> getTimeline();
}
