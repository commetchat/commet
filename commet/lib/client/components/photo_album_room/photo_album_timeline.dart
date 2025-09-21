import 'package:commet/client/components/photo_album_room/photo.dart';

abstract class PhotoAlbumTimeline {
  Stream<int> get onAdded;
  Stream<int> get onChanged;
  Stream<int> get onRemoved;

  List<Photo> get photos;

  bool get canLoadMorePhotos;
  Future<void> loadMorePhotos();
}
