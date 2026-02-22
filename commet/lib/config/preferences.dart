import 'dart:async';
import 'dart:convert';

import 'package:commet/config/build_config.dart';
import 'package:commet/config/platform_utils.dart';
import 'package:commet/config/preferences/bool_preference.dart';
import 'package:commet/config/preferences/double_preference.dart';
import 'package:commet/config/preferences/preference.dart';
import 'package:commet/config/preferences/string_preference.dart';
import 'package:commet/config/theme_config.dart';
import 'package:commet/main.dart';
import 'package:flutter/material.dart';
import 'package:hotkey_manager/hotkey_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tiamat/config/style/theme_amoled.dart';
import 'package:tiamat/config/style/theme_json_converter.dart';
import 'package:tiamat/config/style/theme_dark.dart';
import 'package:tiamat/config/style/theme_light.dart';
import 'package:tiamat/config/style/theme_you.dart';

class Preferences {
  SharedPreferences? _preferences;

  static const String registeredMatrixClients = "registered_matrix_clients";

  static const String _pushGateway = "push_gateway";

  static const String _optedInExperiments = "opted_in_experiments";

  static const String _syncedCalendarUrls = "synced_calendar_urls";

  static const String _runningDonationCheckFlow = "running_donation_check_flow";

  static const String _systemHotkey = "system_wide_hotkey";

  static final StreamController onSettingChangedController =
      StreamController.broadcast();
  Stream get onSettingChanged => onSettingChangedController.stream;
  bool isInit = false;

  Future<void> init() async {
    _preferences = await SharedPreferences.getInstance();
    Preference.preferences = _preferences;
    isInit = true;
  }

  List<String>? getRegisteredMatrixClients() {
    if (_preferences!.containsKey(registeredMatrixClients)) {
      return _preferences!.getStringList(registeredMatrixClients);
    }

    return null;
  }

  void addRegisteredMatrixClient(String name) {
    List<String> names = List.empty(growable: true);
    if (_preferences!.containsKey(registeredMatrixClients)) {
      names = List.from(_preferences!.getStringList(registeredMatrixClients)!,
          growable: true);
    }

    names.add(name);
    _preferences!.setStringList(registeredMatrixClients, names);
  }

  void removeRegisteredMatrixClient(String name) {
    List<String>? names;
    if (_preferences!.containsKey(registeredMatrixClients)) {
      names = _preferences!.getStringList(registeredMatrixClients)!;
    }

    if (names != null) {
      if (names.contains(name)) {
        names.remove(name);
      }
      _preferences!.setStringList(registeredMatrixClients, names);
    }
  }

  Future<ThemeData> resolveTheme({Brightness? overrideBrightness}) async {
    if (overrideBrightness == null && shouldFollowSystemTheme.value) {
      overrideBrightness =
          WidgetsBinding.instance.platformDispatcher.platformBrightness;
    }

    if (!PlatformUtils.isWeb) {
      var custom = await ThemeConfig.getThemeByName(preferences.theme.value);
      if (custom != null) {
        var jsonString = await custom.readAsString();
        var json = const JsonDecoder().convert(jsonString);
        var themedata = await ThemeJsonConverter.fromJson(json, custom);
        if (themedata != null) {
          return themedata;
        }
      }
    }

    if (overrideBrightness == null && shouldFollowSystemColors.value) {
      if (theme.value == "dark") {
        overrideBrightness = Brightness.dark;
      }

      if (theme.value == "light") {
        overrideBrightness = Brightness.light;
      }
    }

    if (overrideBrightness != null && shouldFollowSystemColors.value) {
      return ThemeYou.theme(overrideBrightness);
    }

    if (overrideBrightness == Brightness.dark) {
      return switch (theme.value) {
        "dark" => ThemeDark.theme,
        "amoled" => ThemeAmoled.theme,
        _ => ThemeDark.theme,
      };
    }

    if (overrideBrightness == Brightness.light) {
      return ThemeLight.theme;
    }

    return switch (theme.value) {
      "light" => ThemeLight.theme,
      "dark" => ThemeDark.theme,
      "amoled" => ThemeAmoled.theme,
      _ => ThemeDark.theme,
    };
  }

  Future<void> clear() async {
    await _preferences!.clear();
  }

  Future<void> setPushGateway(String value) async {
    await _preferences!.setString(_pushGateway, value);
  }

  String get pushGateway => BuildConfig.ENABLE_GOOGLE_SERVICES
      ? "push.commet.chat"
      : _preferences!.getString(_pushGateway) ?? "push.commet.chat";

  Future<void> setExperimentEnabled(String experiment, bool value) async {
    var experiments = _preferences?.getStringList(_optedInExperiments) ??
        List.empty(growable: true);

    if (value) {
      if (experiments.contains(experiment) == false) {
        experiments.add(experiment);
      }
    } else {
      experiments.removeWhere((e) => e == experiment);
    }

    await _preferences!.setStringList(_optedInExperiments, experiments);
  }

  bool isExperimentEnabled(String experiment) {
    return _preferences
            ?.getStringList(_optedInExperiments)
            ?.contains(experiment) ==
        true;
  }

  Map<String, dynamic> getCalendarSources(String roomId) {
    var content = _preferences!.getString(_syncedCalendarUrls + ".${roomId}");
    if (content != null) {
      return jsonDecode(content);
    } else {
      return {};
    }
  }

  Future<void> setCalendarSources(String roomId, Map<String, dynamic> sources) {
    return _preferences!
        .setString(_syncedCalendarUrls + ".${roomId}", jsonEncode(sources));
  }

  (String, DateTime)? get runningDonationCheckFlow {
    var result = _preferences!.getString(_runningDonationCheckFlow);

    if (result != null) {
      var data = jsonDecode(result);
      var user = data["user"] as String;
      var timestamp = data["time"] as int;

      var time = DateTime.fromMillisecondsSinceEpoch(timestamp);

      return (user, time);
    }

    return null;
  }

  Future<void> setRunningDonationCheckFlow(
      String value, DateTime timestamp) async {
    _preferences!.setString(
        _runningDonationCheckFlow,
        jsonEncode({
          "user": value,
          "time": timestamp.millisecondsSinceEpoch,
        }));

    onSettingChangedController.add(null);
  }

  Future<void> clearRunningDonationCheckFlow() async {
    _preferences!.remove(_runningDonationCheckFlow);

    onSettingChangedController.add(null);
  }

  String getHotkeyId(String name) {
    return _systemHotkey + ".$name";
  }

  Future<void> setSystemHotkey(String name, HotKey? key) async {
    var k = getHotkeyId(name);

    if (key == null) {
      await _preferences!.remove(k);
    } else {
      await _preferences!.setString(k, jsonEncode(key.toJson()));
    }
  }

  HotKey? getSystemHotkey(String name) {
    var item = _preferences!.getString(getHotkeyId(name));
    if (item == null) return null;

    return HotKey.fromJson(jsonDecode(item));
  }

  BoolPreference shouldFollowSystemTheme =
      BoolPreference("should_follow_system_theme", defaultValue: false);

  BoolPreference shouldFollowSystemColors =
      BoolPreference("should_follow_system_colors", defaultValue: false);

  BoolPreference minimizeOnClose =
      BoolPreference("minimize_on_close", defaultValue: false);

  BoolPreference developerMode =
      BoolPreference("developer_mode", defaultValue: false);

  BoolPreference tenorGifSearchEnabled =
      BoolPreference("enable_tenor_gif_search", defaultValue: false);

  //Workaround for: https://github.com/commetchat/commet/issues/202
  BoolPreference stickerCompatibilityMode =
      BoolPreference("sticker_compatibility_mode", defaultValue: true);

  BoolPreference useFallbackTurnServer =
      BoolPreference("use_fallback_turn_server", defaultValue: false);

  BoolPreference urlPreviewInE2EEChat =
      BoolPreference("use_url_preview_in_e2ee_chat", defaultValue: false);

  BoolPreference messageEffectsEnabled =
      BoolPreference("message_effects_enabled", defaultValue: true);

  BoolPreference showRoomAvatars =
      BoolPreference("show_room_avatars", defaultValue: true);

  BoolPreference usePlaceholderRoomAvatars =
      BoolPreference("use_placeholder_room_avatars", defaultValue: false);

  BoolPreference previewMediaInPublicRooms =
      BoolPreference("preview_media_in_public_rooms", defaultValue: false);

  BoolPreference previewMediaInPrivateRooms =
      BoolPreference("preview_media_in_private_rooms", defaultValue: true);

  BoolPreference showMediaInNotifications =
      BoolPreference("show_media_in_notifications", defaultValue: true);

  BoolPreference formatNotificationBody =
      BoolPreference("format_notification_body", defaultValue: true);

  BoolPreference previewUrlInNotifications =
      BoolPreference("preview_urls_in_notification", defaultValue: true);

  BoolPreference useLegacyNotificationHandler =
      BoolPreference("use_legacy_notification_handler", defaultValue: false);

  BoolPreference askBeforeDeletingMessageEnabled =
      BoolPreference("ask_before_deleting_message_enabled", defaultValue: true);

  BoolPreference silenceNotifications = BoolPreference(
      "silence_notifications_when_other_device_active",
      defaultValue: true);

  BoolPreference disableTextCursorManagement =
      BoolPreference("disable_text_cursor_management", defaultValue: false);

  BoolPreference hideRoomSidePanel =
      BoolPreference("hide_room_side_panel", defaultValue: false);

  BoolPreference showRoomPreviewsInSpaceSidebar =
      BoolPreference("show_room_previews_in_space_sidebar", defaultValue: true);

  BoolPreference doSimulcast =
      BoolPreference("livekit_use_simulcast", defaultValue: false);

  DoublePreference streamBitrate =
      DoublePreference("screenshare_bitrate_mbps", defaultValue: 8);

  DoublePreference streamFramerate =
      DoublePreference("screenshare_fps", defaultValue: 60);

  StringPreference streamCodec =
      StringPreference("livekit_screenshare_codec", defaultValue: "av1");

  StringPreference streamResolution = StringPreference(
      "livekit_screenshare_resolution",
      defaultValue: "1920x1080");

  DoublePreference appScale = DoublePreference("app_scale", defaultValue: 1.0);

  DoublePreference emojiPickerHeight =
      DoublePreference("emoji_picker_height", defaultValue: 300);

  StringPreference proxyUrl =
      StringPreference("proxy_url", defaultValue: "proxy.commet.chat");

  StringPreference fallbackTurnServer = StringPreference("fallback_turn_server",
      defaultValue: "stun:turn.matrix.org");

  StringPreference theme = StringPreference("app_theme", defaultValue: "dark");

  NullableBoolPreference unifiedPushEnabled =
      NullableBoolPreference("unified_push_enabled", defaultValue: null);

  NullableBoolPreference checkForUpdates =
      NullableBoolPreference("check_for_updates", defaultValue: null);

  NullableStringPreference layoutOverride =
      NullableStringPreference("layout_override", defaultValue: null);

  NullableStringPreference voipDefaultAudioInput =
      NullableStringPreference("voip_default_audio_input", defaultValue: null);

  NullableStringPreference voipDefaultAudioOutput =
      NullableStringPreference("voip_default_audio_output", defaultValue: null);

  NullableStringPreference voipDefaultVideoInput =
      NullableStringPreference("voip_default_video_input", defaultValue: null);

  NullableStringPreference filterClient =
      NullableStringPreference("filter_client_id", defaultValue: null);

  NullableStringPreference fcmKey =
      NullableStringPreference("fcm_key", defaultValue: null);

  NullableStringPreference unifiedPushEndpoint =
      NullableStringPreference("unified_push_endpoint", defaultValue: null);

  NullableStringPreference lastDownloadLocation =
      NullableStringPreference("last_download_location", defaultValue: null);
}
