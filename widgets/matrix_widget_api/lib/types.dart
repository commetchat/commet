abstract class ToWidgetAction {
  static const String supportedApiVersions = "supported_api_versions";
  static const String capabilities = "capabilities";
  static const String notifyCapabilities = "notify_capabilities";
  static const String themeChange = "theme_change";
  static const String languageChange = "language_change";
  static const String takeScreenshot = "screenshot";
  static const String updateVisibility = "visibility";
  static const String openIDCredentials = "openid_credentials";
  static const String widgetConfig = "widget_config";
  static const String closeModalWidget = "close_modal";
  static const String buttonClicked = "button_clicked";
  static const String sendEvent = "send_event";
  static const String sendToDevice = "send_to_device";
  static const String updateState = "update_state";
  static const String updateTurnServers = "update_turn_servers";

  static const String msc2764UpdateState = "org.matrix.msc2762_update_state";
}

class FromWidgetAction {
  static const String supportedApiVersions = "supported_api_versions";
  static const String contentLoaded = "content_loaded";
  static const String sendSticker = "m.sticker";
  static const String updateAlwaysOnScreen = "set_always_on_screen";
  static const String getOpenIDCredentials = "get_openid";
  static const String closeModalWidget = "close_modal";
  static const String openModalWidget = "open_modal";
  static const String setModalButtonEnabled = "set_button_enabled";
  static const String sendEvent = "send_event";
  static const String sendToDevice = "send_to_device";
  static const String watchTurnServers = "watch_turn_servers";
  static const String unwatchTurnServers = "unwatch_turn_servers";
  static const String beeperReadRoomAccountData =
      "com.beeper.read_room_account_data";

  // Experimental, use with caution
  static const String readEvents = "org.matrix.msc2876.read_events";
  static const String navigate = "org.matrix.msc2931.navigate";
  static const String renegotiateCapabilities =
      "org.matrix.msc2974.request_capabilities";
  static const String readRelations = "org.matrix.msc3869.read_relations";
  static const String userDirectorySearch =
      "org.matrix.msc3973.user_directory_search";
  static const String getMediaConfigAction =
      "org.matrix.msc4039.get_media_config";
  static const String uploadFileAction = "org.matrix.msc4039.upload_file";
  static const String downloadFileAction = "org.matrix.msc4039.download_file";
  static const String updateDelayedEvent =
      "org.matrix.msc4157.update_delayed_event";
  static const String sendStickyEvent = "org.matrix.msc4354.send_sticky_event";
  static const String msc2876ReadEvents = "org.matrix.msc2876.read_events";
}
