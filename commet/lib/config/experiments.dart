import 'package:commet/main.dart';

class Experiments {
  static bool get voip => preferences.isExperimentEnabled("voip");

  static Future<void> setVoip(bool value) =>
      preferences.setExperimentEnabled("voip", value);
}
