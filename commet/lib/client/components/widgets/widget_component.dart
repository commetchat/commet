import 'dart:typed_data';

import 'package:commet/client/client.dart';
import 'package:commet/client/components/component.dart';
import 'package:commet/debug/log.dart';
import 'package:commet/main.dart';
import 'package:commet/ui/navigation/adaptive_dialog.dart';
import 'package:commet/utils/image_or_icon.dart';
import 'package:commet/utils/notifying_list.dart';
import 'package:flutter/widgets.dart';

abstract class UserWidgetInfo {
  String get name;

  String get type;

  String get namespace;

  String get senderId;

  String get url;

  ImageOrIcon get icon;
}

enum WidgetHostType {
  embedded,
  childProcess,
  remoteHttpClient,
  externalBrowser,
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

  UserWidgetInfo get info;

  WidgetCapabilityManager get capabilities;
  WidgetEventHandler get eventHandler;
  WidgetMessageTransport get messageTransport;
  T get client;
  R? get room;

  NotifyingList<LogEntry> get logs;

  Stream<void> get onClosed;

  Future<void> dispose();
}

abstract class WidgetComponent<T extends Client> implements Component<T> {
  List<UserWidgetInfo> getWidgets(Room room);

  List<WidgetHostType> supportedHostTypes();

  WidgetHostType get defaultHostType;

  static NotifyingList<WidgetRunner> currentSessions =
      NotifyingList.empty(growable: true);

  static void runWidget(Room room, BuildContext context, UserWidgetInfo data,
      {WidgetHostType? type}) async {
    var widgetComponent = room.client.getComponent<WidgetComponent>();

    for (var session in WidgetComponent.currentSessions) {
      await session.dispose();
    }

    if (!preferences.getWidgetAllowed(room.client.identifier, data.namespace)) {
      var confirmed = await AdaptiveDialog.confirmationWithOptions(context,
          title: "Widget",
          showRememberChoice: true,
          defaultRememberSetting: true,
          prompt:
              """Open `${Uri.parse(data.url).authority}`?\n\n'**${data.name}**' was added by `${data.senderId}`""",
          confirmationText: "Open Widget");

      if (confirmed?.value != true) {
        return;
      }

      if (confirmed?.remember == true) {
        preferences.setWidgetAllowed(
            room.client.identifier, data.namespace, true);
      }
    }
    widgetComponent?.openWidget(data, room, context, type: type);
  }

  Future<void> openWidget(
      UserWidgetInfo widget, Room room, BuildContext context,
      {WidgetHostType? type});
}
