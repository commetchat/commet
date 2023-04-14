import 'package:shared_preferences/shared_preferences.dart';

class Preferences {
  SharedPreferences? _preferences;

  static const String registeredMatrixClients = "registered_matrix_clients";

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
    print("Attempting to add account name to list");
    List<String> names = List.empty(growable: true);
    if (_preferences!.containsKey(registeredMatrixClients)) {
      names = List.from(_preferences!.getStringList(registeredMatrixClients)!, growable: true);
    }

    names.add(name);
    _preferences!.setStringList(registeredMatrixClients, names);

    print("Name added!");
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

  Future<void> clear() async {
    await _preferences!.clear();
  }
}
