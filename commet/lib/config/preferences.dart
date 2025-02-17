import 'dart:async';
import 'dart:convert';

import 'package:commet/config/build_config.dart';
import 'package:commet/config/platform_utils.dart';
import 'package:commet/config/theme_config.dart';
import 'package:commet/main.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tiamat/config/style/theme_amoled.dart';
import 'package:tiamat/config/style/theme_json_converter.dart';
import 'package:window_manager/window_manager.dart';
import 'package:tiamat/config/style/theme_dark.dart';
import 'package:tiamat/config/style/theme_light.dart';
import 'package:tiamat/config/style/theme_you.dart';

class Preferences {
  SharedPreferences? _preferences;

  static const String registeredMatrixClients = "registered_matrix_clients";
  static const String _shouldFollowSystemTheme = "should_follow_system_theme";
  static const String _shouldFollowSystemColors = "should_follow_system_colors";
  static const String themeKey = "app_theme";
  static const String appScaleKey = "app_scale";
  static const String _minimizeOnCloseKey = "minimize_on_close";
  static const String _developerMode = "developer_mode";
  static const String _tenorGifSearch = "enable_tenor_gif_search";
  static const String _proxyUrl = "proxy_url";
  static const String _fcmKey = "fcm_key";
  static const String _unifiedPushEnabled = "unified_push_enabled";
  static const String _unifiedPushEndpoint = "unified_push_endpoint";
  static const String _pushGateway = "push_gateway";
  static const String _lastDownloadLocation = "last_download_location";
  static const String _stickerCompatibilityMode = "sticker_compatibility_mode";
  static const String _urlPreviewInE2EEChat = "use_url_preview_in_e2ee_chat";
  static const String _messageEffectsEnabled = "message_effects_enabled";
  static const String _lastForegroundServiceSucceeded =
      "did_last_foreground_service_run_succeed";

  final StreamController _onSettingChanged = StreamController.broadcast();
  Stream get onSettingChanged => _onSettingChanged.stream;
  bool isInit = false;

  Future<void> init() async {
    _preferences = await SharedPreferences.getInstance();
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

  bool get shouldFollowSystemTheme =>
      _preferences!.getBool(_shouldFollowSystemTheme) ?? false;

  void setShouldFollowSystemBrightness(bool value) {
    _preferences!.setBool(_shouldFollowSystemTheme, value);
  }

  bool get shouldFollowSystemColors =>
      _preferences!.getBool(_shouldFollowSystemColors) ?? false;

  void setShouldFollowSystemColors(bool value) {
    _preferences!.setBool(_shouldFollowSystemColors, value);
  }

  void setTheme(String theme) {
    if (theme == "amoled") {
      setShouldFollowSystemColors(false);
    }
    _preferences!.setString(themeKey, theme);
  }

  Future<ThemeData> resolveTheme({Brightness? overrideBrightness}) async {
    if (overrideBrightness == null && shouldFollowSystemTheme) {
      overrideBrightness =
          WidgetsBinding.instance.platformDispatcher.platformBrightness;
    }

    if (!PlatformUtils.isWeb) {
      var custom = await ThemeConfig.getThemeByName(preferences.theme);
      if (custom != null) {
        var jsonString = await custom.readAsString();
        var json = const JsonDecoder().convert(jsonString);
        var themedata = await ThemeJsonConverter.fromJson(json, custom);
        if (themedata != null) {
          return themedata;
        }
      }
    }

    if (overrideBrightness == null && shouldFollowSystemColors) {
      if (theme == "dark") {
        overrideBrightness = Brightness.dark;
      }

      if (theme == "light") {
        overrideBrightness = Brightness.light;
      }
    }

    if (overrideBrightness != null && shouldFollowSystemColors) {
      return ThemeYou.theme(overrideBrightness);
    }

    if (overrideBrightness == Brightness.dark) {
      return switch (theme) {
        "dark" => ThemeDark.theme,
        "amoled" => ThemeAmoled.theme,
        _ => ThemeDark.theme,
      };
    }

    if (overrideBrightness == Brightness.light) {
      return ThemeLight.theme;
    }

    return switch (theme) {
      "light" => ThemeLight.theme,
      "dark" => ThemeDark.theme,
      "amoled" => ThemeAmoled.theme,
      _ => ThemeDark.theme,
    };
  }

  String get theme => _preferences!.getString(themeKey) ?? "dark";

  double get appScale => _preferences!.getDouble(appScaleKey) ?? 1;

  void setAppScale(double scale) {
    _preferences!.setDouble(appScaleKey, scale);
    _onSettingChanged.add(null);
  }

  Future<void> clear() async {
    await _preferences!.clear();
  }

  bool get minimizeOnClose =>
      _preferences!.getBool(_minimizeOnCloseKey) ?? false;

  Future<void> setMinimizeOnClose(bool value) async {
    if (BuildConfig.DESKTOP) {
      windowManager.setPreventClose(value);
    }

    _preferences!.setBool(_minimizeOnCloseKey, value);
    _onSettingChanged.add(null);
  }

  bool get developerMode => _preferences?.getBool(_developerMode) ?? false;

  String get proxyUrl =>
      _preferences?.getString(_proxyUrl) ?? "proxy.commet.chat";

  Future<void> setDeveloperMode(bool value) async {
    await _preferences!.setBool(_developerMode, value);
    _onSettingChanged.add(null);
  }

  bool get tenorGifSearchEnabled =>
      _preferences!.getBool(_tenorGifSearch) ?? false;

  Future<void> setTenorGifSearch(bool value) async {
    await _preferences!.setBool(_tenorGifSearch, value);
    _onSettingChanged.add(null);
  }

  String? get fcmKey => _preferences!.getString(_fcmKey);

  Future<void> setFcmKey(String key) async {
    await _preferences!.setString(_fcmKey, key);
    _onSettingChanged.add(null);
  }

  String? get unifiedPushEndpoint =>
      _preferences!.getString(_unifiedPushEndpoint);

  Future<void> setUnifiedPushEndpoint(String? value) async {
    if (value == null) {
      await _preferences!.remove(_unifiedPushEndpoint);
    } else {
      await _preferences!.setString(_unifiedPushEndpoint, value);
    }
  }

  Future<void> setUnifiedPushEnabled(bool value) async {
    await _preferences!.setBool(_unifiedPushEnabled, value);
  }

  bool? get unifiedPushEnabled => _preferences!.getBool(_unifiedPushEnabled);

  Future<void> setPushGateway(String value) async {
    await _preferences!.setString(_pushGateway, value);
  }

  String get pushGateway => BuildConfig.ENABLE_GOOGLE_SERVICES
      ? "push.commet.chat"
      : _preferences!.getString(_pushGateway) ?? "push.commet.chat";

  String? get lastDownloadLocation =>
      _preferences!.getString(_lastDownloadLocation);

  Future<void> setLastDownloadLocation(String value) async {
    await _preferences!.setString(_lastDownloadLocation, value);
    _onSettingChanged.add(null);
  }

  //Workaround for: https://github.com/commetchat/commet/issues/202
  bool get stickerCompatibilityMode =>
      _preferences!.getBool(_stickerCompatibilityMode) ?? true;

  Future<void> setStickerCompatibilityMode(bool value) async {
    await _preferences!.setBool(_stickerCompatibilityMode, value);
    _onSettingChanged.add(null);
  }

  Future<void> setUseUrlPreviewInE2EEChat(bool value) async {
    await _preferences!.setBool(_urlPreviewInE2EEChat, value);
  }

  bool get urlPreviewInE2EEChat =>
      _preferences!.getBool(_urlPreviewInE2EEChat) ?? false;

  bool? get didLastForegroundServiceRunSucceed =>
      _preferences!.getBool(_lastForegroundServiceSucceeded);

  Future<void> setLastForegroundServiceRunSucceeded(bool? value) async {
    if (value == null) {
      await _preferences!.remove(_lastForegroundServiceSucceeded);
    } else {
      await _preferences!.setBool(_lastForegroundServiceSucceeded, value);
    }
  }

  Future<void> setMessageEffectsEnabled(bool value) async {
    await _preferences!.setBool(_messageEffectsEnabled, value);
  }

  bool get messageEffectsEnabled =>
      _preferences!.getBool(_messageEffectsEnabled) ?? true;
}
