import 'package:commet/config/subplatforms/steamdeck.dart';
import 'package:commet/debug/log.dart';

class Subplatforms {
  static Subplatform? subplatform;

  static Future<void> init() async {
    try {
      if (await SteamdeckSubplatform.isSteamdeck()) {
        subplatform = SteamdeckSubplatform();
      }

      if (subplatform != null) {
        await subplatform!.init();
      }
    } catch (e, s) {
      Log.onError(e, s);
    }
  }
}

abstract class Subplatform {
  Future<void> init();

  String get name;
}
