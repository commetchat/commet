import 'dart:async';

import 'package:commet/client/components/widgets/widget_component.dart';
import 'package:commet/client/matrix/components/widgets/runners/in_app_web_view/matrix_inappwebview_widget_transceiver.dart';
import 'package:commet/client/matrix/components/widgets/matrix_widget_capabilities_manager.dart';
import 'package:commet/client/matrix/components/widgets/matrix_widget_component.dart';
import 'package:commet/client/matrix/components/widgets/matrix_widget_message_handler.dart';
import 'package:commet/client/matrix/components/widgets/matrix_widget_transport.dart';
import 'package:commet/client/matrix/matrix_client.dart';
import 'package:commet/client/matrix/matrix_room.dart';
import 'package:commet/config/platform_utils.dart';
import 'package:commet/debug/log.dart';
import 'package:commet/utils/notifying_list.dart';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

class MatrixUserWidgetInAppWebviewRunner implements MatrixWidgetRunner {
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

  late InAppWebViewController controller;

  UserWidgetInfo info;

  final StreamController onExitController;

  @override
  NotifyingList<LogEntry> logs = NotifyingList.empty(growable: true);

  StreamController _onClosed = StreamController.broadcast();

  @override
  Stream<void> get onClosed => _onClosed.stream;

  MatrixUserWidgetInAppWebviewRunner(
      {required InAppWebViewController webViewController,
      required this.room,
      required this.widgetId,
      required this.info,
      required this.onExitController,
      required BuildContext context,
      required this.client}) {
    var tx = MatrixInAppWebViewWidgetTransceiver(webViewController);

    this.controller = webViewController;

    messageTransport = MatrixWidgetTransport(tx);
    eventHandler = MatrixWidgetMessageHandler(runner: this);
    capabilities =
        MatrixWidgetCapabilitiesManager(runner: this, context: context);
  }

  @override
  void dispose() {
    Log.w("Disposing widget runner!");
    try {
      controller.dispose(isKeepAlive: false);
    } catch (_) {}
    onExitController.add(null);
    _onClosed.add(());
  }
}

class MatrixWidgetInappwebviewRunnerWidget extends StatefulWidget {
  const MatrixWidgetInappwebviewRunnerWidget(
      {this.url,
      this.widgetId,
      this.initialPageData,
      this.room,
      this.component,
      required this.info,
      this.initialRunner,
      required this.onExitController,
      super.key});
  final String? initialPageData;
  final String? url;
  final String? widgetId;
  final MatrixRoom? room;
  final MatrixWidgetComponent? component;
  final UserWidgetInfo info;
  final MatrixUserWidgetInAppWebviewRunner? initialRunner;
  final StreamController onExitController;

  @override
  State<MatrixWidgetInappwebviewRunnerWidget> createState() =>
      _MatrixWidgetInappwebviewRunnerWidgetState();
}

class _MatrixWidgetInappwebviewRunnerWidgetState
    extends State<MatrixWidgetInappwebviewRunnerWidget> {
  MatrixUserWidgetInAppWebviewRunner? runner;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      child: InAppWebView(
        initialSettings: InAppWebViewSettings(transparentBackground: true),
        initialData: InAppWebViewInitialData(
            data: widget.initialPageData!, baseUrl: WebUri("commet://widget")),
        onConsoleMessage: (controller, consoleMessage) {
          Log.i("InAppWebView] $consoleMessage");

          runner?.logs.add(LogEntry(LogType.info, consoleMessage.message));
        },
        onWebViewCreated: (controller) {
          Log.i("On web view created");

          runner = MatrixUserWidgetInAppWebviewRunner(
              webViewController: controller,
              info: widget.info,
              room: widget.room,
              context: context,
              widgetId: widget.widgetId!,
              onExitController: widget.onExitController,
              client: widget.room!.client as MatrixClient);

          widget.component!.registerRunner(runner!);
        },
      ),
    );
  }

  @override
  void dispose() {
    Log.i("Matrix InappWebViewWidget disposed");
    runner!.dispose();
    super.dispose();
  }
}
