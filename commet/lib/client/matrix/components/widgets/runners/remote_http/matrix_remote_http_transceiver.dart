import 'dart:async';
import 'dart:collection';
import 'dart:convert';
import 'dart:io';

import 'package:commet/client/components/widgets/widget_component.dart';
import 'package:commet/client/matrix/components/widgets/matrix_widget_component.dart';
import 'package:commet/debug/log.dart';
import 'package:flutter/services.dart';

class MatrixRemoteHttpWidgetTransceiver implements WidgetTransceiver {
  HttpServer server;

  UserWidgetInfo info;
  StreamController<Uint8List> controller = StreamController();

  Queue<Uint8List> responseQueue = Queue();

  late String secret;
  late String widgetUrl;
  bool useHttps;
  bool allowRemoteConnection;
  String hostIp;

  Function()? onClientConnected;

  MatrixRemoteHttpWidgetTransceiver(
      {required this.server,
      required this.hostIp,
      required this.secret,
      required this.widgetUrl,
      required this.info,
      this.onClientConnected,
      required this.allowRemoteConnection,
      required this.useHttps}) {
    server.listen(onRequest);
  }

  @override
  Stream<Uint8List> get onReceived => controller.stream;

  @override
  void send(Uint8List data) {
    responseQueue.add(data);
  }

  void onRequest(HttpRequest event) {
    final path = event.requestedUri.path;

    if (event.connectionInfo!.remoteAddress.isLoopback == false) {
      if (allowRemoteConnection == false) {
        return forbidden(event);
      }
    }

    if (path == "/favicon.png") {
      return handleIconRequest(event);
    }

    if (event.requestedUri.queryParameters["token"] != secret) {
      return forbidden(event);
    }

    if (path == "/" || path == "/index.html") {
      return handlePageRequest(event);
    }

    if (path == "/transceiver/send") {
      return handleReceivedMessage(event);
    }

    if (path == "/transceiver/receive") {
      return handleSlowPoll(event);
    }
  }

  void handlePageRequest(HttpRequest request) async {
    var editedUrl = Uri.parse(widgetUrl);

    editedUrl = editedUrl.replace(queryParameters: {
      ...editedUrl.queryParameters,
      "parentUrl":
          (useHttps ? "https://" : "http://") + hostIp + ":${server.port}",
    });

    Log.i("Handling favicon");
    var bytes = (await rootBundle.load("assets/data/widget_runner_remote.html"))
        .buffer
        .asUint8List();
    var text = Utf8Decoder().convert(bytes);

    var scriptBytes = (await rootBundle.load("assets/data/widgets_common.js"))
        .buffer
        .asUint8List();
    var scriptText = Utf8Decoder().convert(scriptBytes);

    text =
        text.replaceAll("\$RUNNER_PAGE_TITLE", "Commet Widget | ${info.name}");

    text = text.replaceAll("\$IFRAME_URL", editedUrl.toString());
    text = text.replaceAll("\$IFRAME_ALLOW", MatrixWidgetComponent.iframeAllowPermissions);

    text = text.replaceAll("\$AUTH_SECRET", secret.toString());

    text = text.replaceAll("//\${WIDGETS_COMMON}", scriptText.toString());

    bytes = Utf8Encoder().convert(text);

    request.response
      ..headers.contentType = new ContentType("text", "html")
      ..headers.contentLength = bytes.length
      ..statusCode = 200
      ..add(bytes)
      ..close();

    onClientConnected?.call();
  }

  void handleIconRequest(HttpRequest request) async {
    var bytes =
        (await rootBundle.load("assets/images/app_icon/app_icon_rounded.png"))
            .buffer
            .asUint8List();

    request.response
      ..headers.contentType = new ContentType("image", "png")
      ..headers.contentLength = bytes.length
      ..statusCode = 200
      ..add(bytes)
      ..close();
  }

  void forbidden(HttpRequest request) {
    request.response
      ..statusCode = 403
      ..close();
  }

  void handleReceivedMessage(HttpRequest request) async {
    if (request.method != "POST") return;

    String content = await utf8.decoder.bind(request).join();

    controller.add(Utf8Encoder().convert(content));

    request.response
      ..statusCode = 200
      ..close();
  }

  void handleSlowPoll(HttpRequest request) async {
    Uint8List? response;
    for (int i = 0; i < 100; i++) {
      if (responseQueue.isEmpty) {
        await Future.delayed(Duration(milliseconds: 100));
        continue;
      }

      response = responseQueue.removeFirst();
      break;
    }

    if (response == null) {
      request.response
        ..statusCode = 204
        ..close();

      return;
    }

    request.response
      ..headers.contentType = new ContentType("text", "json")
      ..headers.contentLength = response.length
      ..statusCode = 200
      ..add(response)
      ..close();
  }
}
