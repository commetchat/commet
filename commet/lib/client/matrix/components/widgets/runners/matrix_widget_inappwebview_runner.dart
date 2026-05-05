import 'package:commet/client/components/widgets/widget_component.dart';
import 'package:commet/client/matrix/components/widgets/matrix_inappwebview_widget_transceiver.dart';
import 'package:commet/client/matrix/components/widgets/matrix_widget_capabilities_manager.dart';
import 'package:commet/client/matrix/components/widgets/matrix_widget_component.dart';
import 'package:commet/client/matrix/components/widgets/matrix_widget_message_handler.dart';
import 'package:commet/client/matrix/components/widgets/matrix_widget_transport.dart';
import 'package:commet/client/matrix/matrix_client.dart';
import 'package:commet/client/matrix/matrix_room.dart';
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

  MatrixUserWidgetInAppWebviewRunner(
      {required InAppWebViewController webViewController,
      required this.room,
      required this.widgetId,
      required BuildContext context,
      required this.client}) {
    var tx = MatrixInAppWebViewWidgetTransceiver(webViewController);
    messageTransport = MatrixWidgetTransport(tx);
    eventHandler = MatrixWidgetMessageHandler(runner: this);
    capabilities =
        MatrixWidgetCapabilitiesManager(runner: this, context: context);
  }
}

class MatrixWidgetInappwebviewRunnerWidget extends StatefulWidget {
  const MatrixWidgetInappwebviewRunnerWidget(
      {required this.url,
      required this.widgetId,
      required this.userScript,
      required this.room,
      required this.component,
      super.key});
  final String userScript;
  final String url;
  final String widgetId;
  final MatrixRoom room;
  final MatrixWidgetComponent component;

  @override
  State<MatrixWidgetInappwebviewRunnerWidget> createState() =>
      _MatrixWidgetInappwebviewRunnerWidgetState();
}

class _MatrixWidgetInappwebviewRunnerWidgetState
    extends State<MatrixWidgetInappwebviewRunnerWidget> {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      child: InAppWebView(
        initialUrlRequest: URLRequest(url: WebUri(widget.url)),
        onWebViewCreated: (controller) {
          controller.addUserScript(
              userScript: UserScript(
                  source: widget.userScript,
                  injectionTime: UserScriptInjectionTime.AT_DOCUMENT_START));

          var runner = MatrixUserWidgetInAppWebviewRunner(
              webViewController: controller,
              room: widget.room,
              context: context,
              widgetId: widget.widgetId,
              client: widget.room.client as MatrixClient);

          widget.component.registerRunner(runner);
        },
      ),
    );
  }
}
