import 'dart:async';
import 'package:desktop_drop/desktop_drop.dart';

class EventBus {
  /// First string is room id, Second string is client id
  static StreamController<(String, String?)> openRoom =
      StreamController<(String, String?)>.broadcast();

  static StreamController<DropDoneDetails> onFileDropped =
      StreamController<DropDoneDetails>.broadcast();
}
