import 'package:commet/main.dart';

class Experiments {
  static bool get voip => preferences.isExperimentEnabled("voip");

  static bool get photoAlbumRooms =>
      preferences.isExperimentEnabled("photo_album_rooms");

  static bool get elementCall =>
      preferences.isExperimentEnabled("element_call");

  static bool get calendarRooms =>
      preferences.isExperimentEnabled("calendar_room");

  static Future<void> setVoip(bool value) =>
      preferences.setExperimentEnabled("voip", value);

  static Future<void> setElementCall(bool value) =>
      preferences.setExperimentEnabled("element_call", value);

  static Future<void> setPhotoAlbumRooms(bool value) =>
      preferences.setExperimentEnabled("photo_album_rooms", value);

  static Future<void> setCalendarRoom(bool value) =>
      preferences.setExperimentEnabled("calendar_room", value);
}
