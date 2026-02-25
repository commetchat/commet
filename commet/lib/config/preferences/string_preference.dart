import 'package:commet/config/preferences/preference.dart';

class StringPreference extends Preference<String> {
  StringPreference(super.key, {required super.defaultValue})
      : super(
          getter: () => Preference.preferences?.getString(key),
          setter: (v) async {
            await Preference.preferences?.setString(key, v);
          },
        );
}

class NullableStringPreference extends Preference<String?> {
  NullableStringPreference(super.key, {required super.defaultValue})
      : super(
          getter: () => Preference.preferences?.getString(key),
          setter: (v) async {
            if (v == null) {
              await Preference.preferences?.remove(key);
            } else {
              await Preference.preferences?.setString(key, v);
            }
          },
        );
}
