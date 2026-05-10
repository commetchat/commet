import 'dart:convert';
import 'dart:io';

import 'package:commet/client/components/widgets/widget_component.dart';
import 'package:commet/client/matrix/components/widgets/matrix_io_widget_transceiver.dart';
import 'package:commet/client/matrix/components/widgets/matrix_widget_capabilities_manager.dart';
import 'package:commet/client/matrix/components/widgets/matrix_widget_component.dart';
import 'package:commet/client/matrix/components/widgets/matrix_widget_message_handler.dart';
import 'package:commet/client/matrix/components/widgets/matrix_widget_transport.dart';
import 'package:commet/client/matrix/matrix_client.dart';
import 'package:commet/client/matrix/matrix_room.dart';
import 'package:commet/debug/log.dart';
import 'package:flutter/material.dart';

class MatrixUserWidgetDesktopRunner implements MatrixWidgetRunner {
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

  MatrixUserWidgetDesktopRunner(
      {required Process process,
      required this.room,
      required this.widgetId,
      required BuildContext context,
      required this.client}) {
    var tx = MatrixIoWidgetTransceiver(process: process);
    this.process = process;
    messageTransport = MatrixWidgetTransport(tx);
    eventHandler = MatrixWidgetMessageHandler(runner: this);
    capabilities =
        MatrixWidgetCapabilitiesManager(runner: this, context: context);

    process.stderr
        .map((i) => Utf8Decoder().convert(i))
        .listen((i) => i.split("\n").forEach((i) => Log.d("Widget: ${i}")));

    Future.delayed(Duration(seconds: 1)).then((_) {
      messageTransport.send(
          eventHandler.generateToWidgetEvent(action: "capabilities", data: {}));

      Future.delayed(Duration(seconds: 1)).then((_) {
        messageTransport.send(eventHandler
            .generateToWidgetEvent(action: "notify_capabilities", data: {
          "requested": ["io.element.requires_client"],
          "approved": ["io.element.requires_client"]
        }));
      });
    });
  }

  @override
  void dispose() {
    process.kill();
  }
}
