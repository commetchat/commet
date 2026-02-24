import 'package:commet/config/preferences/preference.dart';

class BoolPreference extends Preference<bool> {
  BoolPreference(super.key, {required super.defaultValue})
      : super(
          getter: () => Preference.preferences?.getBool(key) ?? defaultValue,
          setter: (v) async {
            await Preference.preferences?.setBool(key, v);
          },
        );
}

class NullableBoolPreference extends Preference<bool?> {
  NullableBoolPreference(super.key, {required super.defaultValue})
      : super(
          getter: () => Preference.preferences?.getBool(key) ?? defaultValue,
          setter: (v) async {
            if (v == null) {
              await Preference.preferences?.remove(key);
            } else {
              await Preference.preferences?.setBool(key, v);
            }
          },
        );
}
