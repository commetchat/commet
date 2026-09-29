import 'package:commet/config/preferences/preference.dart';

class StringListPreference extends Preference<List<String>> {
  StringListPreference(super.key, {required super.defaultValue})
      : super(
            getter: () =>
                Preference.preferences?.getStringList(key) ?? List.empty(),
            setter: (v) async {
              await Preference.preferences?.setStringList(key, v);
            });

  void add(String value) {
    var values = Preference.preferences?.getStringList(key);

    var newValues = values == null
        ? List<String>.empty(growable: true)
        : List<String>.from(values, growable: true);

    if (!newValues.contains(value)) {
      newValues.add(value);
    }

    Preference.preferences?.setStringList(key, newValues);
  }

  void remove(String value) {
    var values = Preference.preferences?.getStringList(key);

    var newValues = values == null
        ? List<String>.empty(growable: true)
        : List<String>.from(values, growable: true);

    newValues.remove(value);

    Preference.preferences?.setStringList(key, newValues);
  }
}
