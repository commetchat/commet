import 'package:commet/client/components/widgets/widget_component.dart';
import 'package:commet/client/matrix/components/widgets/matrix_inappwebview_widget_transceiver.dart';
import 'package:commet/client/matrix/components/widgets/matrix_widget_capabilities_manager.dart';
import 'package:commet/client/matrix/components/widgets/matrix_widget_component.dart';
import 'package:commet/client/matrix/components/widgets/matrix_widget_message_handler.dart';
import 'package:commet/client/matrix/components/widgets/matrix_widget_transport.dart';
import 'package:commet/client/matrix/matrix_client.dart';
import 'package:commet/client/matrix/matrix_room.dart';
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

  InAppWebViewKeepAlive keepAlive;

  UserWidgetInfo info;

  @override
  NotifyingList<LogEntry> logs = NotifyingList.empty(growable: true);

  MatrixUserWidgetInAppWebviewRunner(
      {required InAppWebViewController webViewController,
      required this.room,
      required this.widgetId,
      required this.info,
      required BuildContext context,
      required this.keepAlive,
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
    controller.platform.disposeKeepAlive(keepAlive);
    controller.dispose(isKeepAlive: false);
  }
}

class MatrixWidgetInappwebviewRunnerWidget extends StatelessWidget {
  const MatrixWidgetInappwebviewRunnerWidget(
      {this.url,
      this.widgetId,
      this.userScript,
      this.room,
      this.component,
      required this.keepAlive,
      this.initialize = false,
      required this.info,
      this.onRunnerCreated,
      this.initialRunner,
      super.key});
  final String? userScript;
  final String? url;
  final String? widgetId;
  final MatrixRoom? room;
  final MatrixWidgetComponent? component;
  final UserWidgetInfo info;
  final bool initialize;
  final InAppWebViewKeepAlive keepAlive;
  final MatrixUserWidgetInAppWebviewRunner? initialRunner;
  final void Function(MatrixUserWidgetInAppWebviewRunner)? onRunnerCreated;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      child: InAppWebView(
        keepAlive: keepAlive,
        initialUrlRequest: initialize ? URLRequest(url: WebUri(url!)) : null,
        onConsoleMessage: (controller, consoleMessage) {
          Log.i("InAppWebView] $consoleMessage");
        },
        onWebViewCreated: (controller) {
          if (userScript != null) {
            controller.addUserScript(
                userScript: UserScript(
                    source: userScript!,
                    injectionTime: UserScriptInjectionTime.AT_DOCUMENT_START));
          }

          if (!initialize) return;

          var runner = MatrixUserWidgetInAppWebviewRunner(
              webViewController: controller,
              info: info,
              room: room,
              context: context,
              keepAlive: keepAlive,
              widgetId: widgetId!,
              client: room!.client as MatrixClient);

          component!.registerRunner(runner);
          onRunnerCreated?.call(runner);
        },
      ),
    );
  }
}
