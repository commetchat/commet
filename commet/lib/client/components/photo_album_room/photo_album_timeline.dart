import 'package:commet/client/components/photo_album_room/photo.dart';

abstract class PhotoAlbumTimeline {
  Stream<Photo> get onAdded;
  Stream<Photo> get onChanged;
  Stream<Photo> get onRemoved;

  List<Photo> get photos;

  bool get canLoadMorePhotos;
  Future<void> loadMorePhotos();
}
