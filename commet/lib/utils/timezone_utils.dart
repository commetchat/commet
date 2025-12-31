import 'package:timezone/data/latest.dart' as tzData;

class TimezoneUtils {
  TimezoneUtils._();

  bool isInit = false;
  Future<void>? loading;

  static final instance = TimezoneUtils._();

  Future<void> init() async {
    if (isInit == false) {
      isInit = true;
      print("Initializing timezone database");
      tzData.initializeTimeZones();
    }

    return;
  }
}
