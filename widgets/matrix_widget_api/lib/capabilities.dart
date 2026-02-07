abstract class MatrixCapability {
  static const String screenshots = "m.capability.screenshot";
  static const String stickerSending = "m.sticker";
  static const String alwaysOnScreen = "m.always_on_screen";
  static const String requiresClient = "io.element.requires_client";
  static const String navigate = "org.matrix.msc2931.navigate";
  static const String turnServers = "town.robin.msc3846.turn_servers";
  static const String userDirectorySearch =
      "org.matrix.msc3973.user_directory_search";
  static const String uploadFile = "org.matrix.msc4039.upload_file";
  static const String downloadFile = "org.matrix.msc4039.download_file";
  static const String sendDelayedEvent =
      "org.matrix.msc4157.send.delayed_event";
  static const String updateDelayedEvent =
      "org.matrix.msc4157.update_delayed_event";
  static const String sendStickyEvent = "org.matrix.msc4354.send_sticky_event";

  static String sendEvent(String event) {
    return "org.matrix.msc2762.send.event:$event";
  }

  static String receiveEvent(String event) {
    return "org.matrix.msc2762.receive.event:$event";
  }

  static String _roomState(String direction, String type, String? stateKey) {
    var result = "org.matrix.msc2762.$direction.state_event:$type";

    if (stateKey != null) {
      result += "#$stateKey";
    }

    return result;
  }

  static String setRoomState(String type, {String? stateKey}) =>
      _roomState("send", type, stateKey);

  static String getRoomState(String type, {String? stateKey}) =>
      _roomState("receive", type, stateKey);
}
