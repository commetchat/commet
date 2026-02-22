import 'package:commet/config/preferences/preference.dart';

class DoublePreference extends Preference<double> {
  DoublePreference(super.key, {required super.defaultValue})
      : super(
          getter: () => Preference.preferences?.getDouble(key) ?? defaultValue,
          setter: (v) async {
            await Preference.preferences?.setDouble(key, v);
          },
        );
}
