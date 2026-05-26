import 'dart:typed_data';

import 'package:commet/client/client.dart';
import 'package:commet/client/components/component.dart';
import 'package:commet/debug/log.dart';
import 'package:commet/utils/notifying_list.dart';
import 'package:flutter/widgets.dart';

abstract class UserWidgetInfo {
  String get name;
}

enum WidgetHostType {
  embedded,
  childProcess,
  remoteHttpClient,
}

abstract class WidgetCapabilityManager<T> {
  Future<List<String>> requestCapabilities(List<String> capabilities);

  NotifyingList<String> get grantedCapabilityNames;

  void handleEvent(T event);

  void dispose();
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
  Future<Map<String, dynamic>> send(Map<String, dynamic> msg);

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

  Stream<void> get onClosed;

  void dispose();
}

abstract class WidgetComponent<T extends Client> implements Component<T> {
  List<UserWidgetInfo> getWidgets(Room room);

  List<WidgetHostType> supportedHostTypes();

  static NotifyingList<WidgetRunner> currentSessions = NotifyingList.empty(growable: true);

  Future<void> openWidget(
      UserWidgetInfo widget, Room room, BuildContext context, WidgetHostType type);
}
