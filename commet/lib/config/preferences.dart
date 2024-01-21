import 'dart:async';

import 'package:commet/config/build_config.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:window_manager/window_manager.dart';

enum AppTheme { light, dark, amoled }

class Preferences {
  SharedPreferences? _preferences;

  static const String registeredMatrixClients = "registered_matrix_clients";
  static const String themeKey = "app_theme";
  static const String appScaleKey = "app_scale";
  static const String _minimizeOnCloseKey = "minimize_on_close";
  static const String _developerMode = "developer_mode";
  static const String _tenorGifSearch = "enable_tenor_gif_search";
  static const String _gifSearchProxyUrl = "gif_search_proxy_url";
  static const String _fcmKey = "fcm_key";
  static const String _unifiedPushEnabled = "unified_push_enabled";
  static const String _unifiedPushEndpoint = "unified_push_endpoint";
  static const String _pushGateway = "push_gateway";
  static const String _lastDownloadLocation = "last_download_location";
  static const String _urlPreviewInE2EEChat = "use_url_preview_in_e2ee_chat";
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

  AppTheme _getTheme() {
    var name = _preferences!.getString(themeKey);
    if (name == null) return AppTheme.dark;
    try {
      return AppTheme.values.byName(name);
    } catch (e) {
      return AppTheme.dark;
    }
  }

  void setTheme(AppTheme theme) {
    _preferences!.setString(themeKey, theme.name);
  }

  AppTheme get theme => _getTheme();

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

  String get gifProxyUrl =>
      _preferences?.getString(_gifSearchProxyUrl) ?? "proxy.commet.chat";

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

  String get pushGateway =>
      _preferences!.getString(_pushGateway) ?? "push.commet.chat";

  String? get lastDownloadLocation =>
      _preferences!.getString(_lastDownloadLocation);

  Future<void> setLastDownloadLocation(String value) async {
    await _preferences!.setString(_lastDownloadLocation, value);
    _onSettingChanged.add(null);
  }

  Future<void> setUseUrlPreviewInE2EEChat(bool value) async {
    await _preferences!.setBool(_urlPreviewInE2EEChat, value);
  }

  bool get urlPreviewInE2EEChat =>
      _preferences!.getBool(_urlPreviewInE2EEChat) ?? false;
}
