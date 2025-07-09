import 'package:commet/main.dart';

class Experiments {
  static bool get voip => preferences.isExperimentEnabled("voip");

  static bool get photoAlbumRooms =>
      preferences.isExperimentEnabled("photo_album_rooms");

  static Future<void> setVoip(bool value) =>
      preferences.setExperimentEnabled("voip", value);

  static Future<void> setPhotoAlbumRooms(bool value) =>
      preferences.setExperimentEnabled("photo_album_rooms", value);
}
