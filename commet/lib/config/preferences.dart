import 'package:shared_preferences/shared_preferences.dart';

enum AppTheme {
  light,
  dark,
}

class Preferences {
  SharedPreferences? _preferences;

  static const String registeredMatrixClients = "registered_matrix_clients";
  static const String themeKey = "app_theme";
  static const String appScaleKey = "app_scale";

  Future<void> init() async {
    _preferences = await SharedPreferences.getInstance();
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

  AppTheme getTheme() {
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

  double getAppScale() {
    return _preferences!.getDouble(appScaleKey) ?? 1;
  }

  void setAppScale(double scale) {
    _preferences!.setDouble(appScaleKey, scale);
  }

  Future<void> clear() async {
    await _preferences!.clear();
  }
}
