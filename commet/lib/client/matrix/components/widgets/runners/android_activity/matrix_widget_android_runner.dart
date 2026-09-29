import 'dart:async';
import 'dart:io';

import 'package:commet/client/components/widgets/widget_component.dart';
import 'package:commet/client/matrix/components/widgets/matrix_widget_capabilities_manager.dart';
import 'package:commet/client/matrix/components/widgets/matrix_widget_component.dart';
import 'package:commet/client/matrix/components/widgets/matrix_widget_message_handler.dart';
import 'package:commet/client/matrix/components/widgets/matrix_widget_transport.dart';
import 'package:commet/client/matrix/components/widgets/runners/android_activity/matrix_android_ipc_transceiver.dart';
import 'package:commet/client/matrix/matrix_client.dart';
import 'package:commet/client/matrix/matrix_room.dart';
import 'package:commet/debug/log.dart';
import 'package:commet/utils/notifying_list.dart';
import 'package:flutter/material.dart';

class MatrixWidgetAndroidRunner implements MatrixWidgetRunner {
  @override
  MatrixRoom? room;

  @override
  MatrixClient client;

  @override
  late String widgetId;

  @override
  NotifyingList<LogEntry> logs = NotifyingList.empty(growable: true);

  @override
  late WidgetMessageTransport messageTransport;

  @override
  late WidgetEventHandler eventHandler;

  @override
  late WidgetCapabilityManager capabilities;

  StreamController _onClosed = StreamController.broadcast();

  @override
  Stream<void> get onClosed => _onClosed.stream;

  @override
  UserWidgetInfo info;

  late MatrixAndroidIpcTransceiver tx;

  MatrixWidgetAndroidRunner({
    required this.room,
    required this.widgetId,
    required this.client,
    required this.info,
    required ServerSocket socket,
    required BuildContext context,
  }) {
    tx = MatrixAndroidIpcTransceiver(socket);
    messageTransport = MatrixWidgetTransport(tx);
    eventHandler = MatrixWidgetMessageHandler(runner: this);
    capabilities =
        MatrixWidgetCapabilitiesManager(runner: this, context: context);
  }

  @override
  Future<void> dispose() async {
    Log.i("Disposing of android runner");
    await tx.dispose();
    _onClosed.add(());
  }
}
