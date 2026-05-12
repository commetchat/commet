import 'dart:typed_data';

import 'package:commet/client/client.dart';
import 'package:commet/client/components/component.dart';
import 'package:commet/debug/log.dart';
import 'package:commet/utils/notifying_list.dart';

abstract class UserWidgetInfo {
  String get name;
}

abstract class WidgetCapabilityManager<T> {
  Future<List<String>> requestCapabilities(List<String> capabilities);

  NotifyingList<String> get grantedCapabilityNames;

  void handleEvent(T event);
}

abstract class WidgetTransceiver {
  void send(Uint8List data);

  Stream<Uint8List> get onReceived;
}

enum WidgetMessageDirection {
  incoming,
  outgoing,
}

abstract class WidgetMessageTransport {
  void send(Map<String, dynamic> msg);

  NotifyingList<(WidgetMessageDirection, Map<String, dynamic>)> get messageLogs;

  Stream<Map<String, dynamic>> get onReceived;
}

abstract class WidgetEventHandler {
  String generateRequestId();

  Map<String, dynamic> generateToWidgetEvent(
      {required String action, required Map<String, dynamic> data});
}

abstract class WidgetRunner<T, R> {
  String get widgetId;
  WidgetCapabilityManager get capabilities;
  WidgetEventHandler get eventHandler;
  WidgetMessageTransport get messageTransport;
  T get client;
  R? get room;

  NotifyingList<LogEntry> get logs;

  void dispose();
}

abstract class WidgetComponent<T extends Client> implements Component<T> {
  List<UserWidgetInfo> getWidgets(Room room);

  Future<void> openWidget(UserWidgetInfo widget, Room room);
}
