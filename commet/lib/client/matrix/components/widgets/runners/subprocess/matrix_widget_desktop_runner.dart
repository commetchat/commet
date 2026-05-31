import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:commet/client/components/widgets/widget_component.dart';
import 'package:commet/client/matrix/components/widgets/runners/subprocess/matrix_subprocess_widget_transceiver.dart';
import 'package:commet/client/matrix/components/widgets/matrix_widget_capabilities_manager.dart';
import 'package:commet/client/matrix/components/widgets/matrix_widget_component.dart';
import 'package:commet/client/matrix/components/widgets/matrix_widget_message_handler.dart';
import 'package:commet/client/matrix/components/widgets/matrix_widget_transport.dart';
import 'package:commet/client/matrix/matrix_client.dart';
import 'package:commet/client/matrix/matrix_room.dart';
import 'package:commet/debug/log.dart';
import 'package:commet/utils/notifying_list.dart';
import 'package:flutter/material.dart';

class MatrixUserWidgetSubprocessRunner implements MatrixWidgetRunner {
  @override
  MatrixRoom? room;

  @override
  MatrixClient client;

  @override
  late String widgetId;

  @override
  late WidgetMessageTransport messageTransport;

  @override
  late WidgetEventHandler eventHandler;

  @override
  late WidgetCapabilityManager capabilities;

  late Process process;

  @override
  NotifyingList<LogEntry> logs = NotifyingList.empty(growable: true);

  StreamController _onClosed = StreamController.broadcast();

  @override
  Stream<void> get onClosed => _onClosed.stream;

  @override
  UserWidgetInfo info;

  MatrixUserWidgetSubprocessRunner(
      {required Process process,
      required this.room,
      required this.widgetId,
      required BuildContext context,
      required this.info,
      required this.client}) {
    var tx = MatrixSubprocessWidgetTransceiver(process: process);
    this.process = process;

    messageTransport = MatrixWidgetTransport(tx);
    eventHandler = MatrixWidgetMessageHandler(runner: this);

    capabilities =
        MatrixWidgetCapabilitiesManager(runner: this, context: context);

    process.stderr.map((i) => Utf8Decoder().convert(i)).listen((i) =>
        i.split("\n").forEach((i) => logs.add(LogEntry(LogType.info, i))));

    process.exitCode.then((i) {
      Log.i("Subprocess exited with code: $i");
      dispose();
    });
  }

  @override
  void dispose() {
    process.kill();
    _onClosed.add(null);
  }
}
