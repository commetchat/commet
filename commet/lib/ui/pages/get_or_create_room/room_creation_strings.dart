import 'package:intl/intl.dart';

class RoomCreationStrings {
  static String get labelCreateRoom =>
      Intl.message("Create Room", name: "labelCreateRoom");

  static String get labelPickExistingRoom => Intl.message(
        "Existing Room",
        name: "labelPickExistingRoom",
      );

  static String get labelJoinRoom => Intl.message(
        "Join Room",
        name: "labelJoinRoom",
      );

  static String get labelRoomTypeTextChat => Intl.message("Text Chat",
      name: "labelRoomTypeTextChat",
      desc: "Label for creating a regular text based chat room");

  static String get labelRoomTypeVoiceChat => Intl.message(
        "Voice Chat",
        name: "labelRoomTypeVoiceChat",
      );

  static String get labelRoomTypePhotoAlbum => Intl.message(
        "Photo Album",
        name: "labelRoomTypePhotoAlbum",
      );

  static String get labelRoomTypeCalendar => Intl.message(
        "Calendar",
        name: "labelRoomTypeCalendar",
      );

  static String get labelRoomTypeSpace => Intl.message(
        "Space",
        name: "labelRoomTypeSpace",
      );
}
