import 'dart:async';

class NavigationSignals {
  static StreamController<String> openRoom =
      StreamController<String>.broadcast();
}
