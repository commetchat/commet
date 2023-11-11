import 'dart:async';

class NavigationSignals {
  /// First string is room id, Second string is client id
  static StreamController<(String, String?)> openRoom =
      StreamController<(String, String?)>.broadcast();
}
