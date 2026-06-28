import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:commet/client/client.dart';
import 'package:commet/client/components/widgets/widget_component.dart';
import 'package:commet/client/matrix/components/widgets/runners/android_activity/matrix_widget_android_runner.dart';
import 'package:commet/client/matrix/components/widgets/runners/in_app_web_view/matrix_widget_inappwebview_runner.dart';
import 'package:commet/client/matrix/components/widgets/runners/subprocess/matrix_widget_desktop_runner.dart';
import 'package:commet/client/matrix/components/widgets/runners/remote_http/self_signed_https_server.dart';
import 'package:commet/client/matrix/components/widgets/runners/remote_http/matrix_widget_remote_http_runner.dart';
import 'package:commet/client/matrix/matrix_client.dart';
import 'package:commet/client/matrix/matrix_mxc_image_provider.dart';
import 'package:commet/client/matrix/matrix_room.dart';
import 'package:commet/client/room.dart';
import 'package:commet/config/app_config.dart';
import 'package:commet/config/platform_utils.dart';
import 'package:commet/debug/log.dart';
import 'package:commet/main.dart';
import 'package:commet/ui/organisms/overlay_windows/overlay_window_manager.dart';
import 'package:commet/utils/color_utils.dart';
import 'package:commet/utils/error_utils.dart';
import 'package:commet/utils/image_or_icon.dart';
import 'package:dart_ipc/dart_ipc.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:matrix/matrix.dart' show StrippedStateEvent;
import 'package:matrix/matrix_api_lite/utils/try_get_map_extension.dart';
import 'package:network_info_plus/network_info_plus.dart';

class MatrixUserWidgetInfo implements UserWidgetInfo {
  late String _name;

  StrippedStateEvent event;

  String roomId;

  MatrixUserWidgetInfo({
    required this.id,
    required String name,
    required this.url,
    required this.type,
    required this.icon,
    required this.roomId,
    required this.event,
  }) {
    _name = name;
  }

  @override
  String get name => _name;

  @override
  String url;

  @override
  String type;

  String id;

  @override
  ImageOrIcon icon;

  @override
  String get namespace => "${roomId}_${id}_${event.senderId}_${url}";

  @override
  String get senderId => event.senderId;
}

abstract class MatrixWidgetRunner
    extends WidgetRunner<MatrixClient, MatrixRoom> {}

class MatrixWidgetComponent implements WidgetComponent<MatrixClient> {
  @override
  MatrixClient client;

  MatrixWidgetComponent(this.client);

  @override
  List<UserWidgetInfo> getWidgets(Room room) {
    var mx = (room as MatrixRoom).matrixRoom;
    var states = mx.states["im.vector.modular.widgets"];
    if (states == null) return List.empty();

    var result = List<MatrixUserWidgetInfo>.empty(growable: true);

    for (var s in states.entries) {
      String? id = s.value.content.tryGet("id") ?? s.key;
      String? url = s.value.content.tryGet("url");
      String? type = s.value.content.tryGet("type");
      String? name = s.value.content.tryGet("name");
      String? avatarUrl = s.value.content.tryGet("avatar_url");

      if (url == null || type == null || name == null) continue;

      var icon = ImageOrIcon(icon: Icons.widgets);

      if (avatarUrl != null) {
        var uri = Uri.tryParse(avatarUrl);
        if (uri?.scheme == "mxc") {
          icon.image = MatrixMxcImage(uri!, client.matrixClient);
        }
      }

      // https://github.com/element-hq/element-web/blob/cd8a1012c82be10178fb134ef8a791eef217b4c9/apps/web/src/components/views/avatars/WidgetAvatar.tsx#L26
      if (type.contains("jitsi")) {
        icon.icon = Icons.video_call;
      } else if (type.contains("meeting") || type.contains("calendar")) {
        icon.icon = Icons.calendar_month;
      } else if (type.contains("doc") ||
          type.contains("pad") ||
          type.contains("calc")) {
        icon.icon = Icons.edit_document;
      } else if (type.contains("clock")) {
        icon.icon = Icons.timer;
      }

      url = Uri.encodeFull(url);

      result.add(MatrixUserWidgetInfo(
          id: id,
          name: name,
          url: url,
          type: type,
          roomId: room.identifier,
          event: s.value,
          icon: icon));
    }

    return result;
  }

  void registerRunner(MatrixWidgetRunner runner) {
    Log.i("Registering Matrix Widget Runner: $runner");

    WidgetComponent.currentSessions.add(runner);

    runner.onClosed
        .listen((_) => WidgetComponent.currentSessions.remove(runner));
  }

  @override
  WidgetHostType get defaultHostType {
    if (PlatformUtils.isWindows) {
      return WidgetHostType.embedded;
    }

    if (PlatformUtils.isAndroid) {
      return WidgetHostType.androidActivity;
    }

    if (PlatformUtils.isLinux) {
      return WidgetHostType.externalBrowser;
    }

    if (PlatformUtils.isWeb) {
      return WidgetHostType.embedded;
    }

    return WidgetHostType.embedded;
  }

  @override
  List<WidgetHostType> supportedHostTypes() {
    if (PlatformUtils.isWindows) {
      return const [
        WidgetHostType.childProcess,
        WidgetHostType.embedded,
        WidgetHostType.remoteHttpClient
      ];
    }

    if (PlatformUtils.isAndroid) {
      return const [WidgetHostType.androidActivity, WidgetHostType.embedded];
    }

    if (PlatformUtils.isLinux) {
      return const [
        WidgetHostType.remoteHttpClient,
        WidgetHostType.externalBrowser,
      ];
    }

    if (PlatformUtils.isWeb) {
      return const [WidgetHostType.embedded];
    }

    throw UnimplementedError();
  }

  @override
  Future<void> openWidget(
      UserWidgetInfo widget, Room room, BuildContext context,
      {WidgetHostType? type}) async {
    ErrorUtils.tryRun(context, () async {
      var info = widget as MatrixUserWidgetInfo;
      var url = Uri.encodeFull(info.url);

      var colorScheme = JsonEncoder().convert(ColorScheme.of(context).toJson());
      var replacements = {
        "\$matrix_user_id": room.client.self!.identifier,
        "\$matrix_room_id": room.identifier,
        "\$matrix_display_name": room.client.self!.displayName,
        "\$org.matrix.msc3819.matrix_device_id":
            (room.client as MatrixClient).matrixClient.deviceID!,
        "\$org.matrix.msc4039.matrix_base_url":
            (room.client as MatrixClient).matrixClient.baseUri.toString(),
        "\$chat.commet.color_scheme": Uri.encodeComponent(colorScheme),
        "\$org.matrix.msc2873.client_theme":
            Theme.of(context).brightness == Brightness.light ? "light" : "dark",
      };

      Log.i("Replacements: ${jsonEncode(replacements)}");

      for (var pair in replacements.entries) {
        url = url.replaceAll(pair.key, pair.value);
      }

      var uri = Uri.parse(url);

      uri = Uri(
          scheme: uri.scheme,
          host: uri.host,
          port: uri.port,
          path: uri.path,
          fragment: uri.fragment.isEmpty ? null : uri.fragment,
          queryParameters: {
            ...uri.queryParameters,
            "parentUrl": "commet://widget",
            "widgetId": info.id,
          });

      url = uri.toString();

      Log.i("Launching Widget: $url");

      var runnerType = type ?? defaultHostType;

      switch (runnerType) {
        case WidgetHostType.embedded:
          uri = Uri.parse(url);

          HttpServer? server;

          // On windows, we need to serve the initial embedded page
          // from an actual http server, otherwise the browser wont
          // recognise our 'localhost' as a secure context.
          // All communication is still done through webview js handlers,
          // and the server will be killed after the initial request.
          if (PlatformUtils.isWindows) {
            server = await spawnServerWithOpenPort();
          }

          uri = Uri(
              scheme: uri.scheme,
              host: uri.host,
              port: uri.port,
              path: uri.path,
              fragment: uri.fragment.isEmpty ? null : uri.fragment,
              queryParameters: {
                ...uri.queryParameters,
                "parentUrl": server == null
                    ? "http://localhost/widget"
                    : "http://localhost:${server.port}",
                "widgetId": info.id,
              });

          url = uri.toString();

          await createEmbeddedWidget(url, info, widget, room, context,
              server: server);
          return;
        case WidgetHostType.childProcess:
          await spawnChildProcess(url, room, widget);
          return;
        case WidgetHostType.remoteHttpClient:
          await createRemoteHttpWidgetRunner(url, room, widget,
              useInsecureHttp: false, allowRemoteConnection: true);
          return;
        case WidgetHostType.externalBrowser:
          await createRemoteHttpWidgetRunner(url, room, widget,
              launchBrowser: true,
              useInsecureHttp: true,
              allowRemoteConnection: false);
          return;
        case WidgetHostType.androidActivity:
          uri = Uri(
              scheme: uri.scheme,
              host: uri.host,
              port: uri.port,
              path: uri.path,
              fragment: uri.fragment.isEmpty ? null : uri.fragment,
              queryParameters: {
                ...uri.queryParameters,
                "parentUrl": "http://localhost/widget",
                "widgetId": info.id,
              });

          url = uri.toString();
          createAndroidActivityWidget(url, widget, room, context);
          return;
      }
    });
  }

  static bool get allowLocalNetwork => false;
  
  static String get iframeAllowPermissions =>
      "accelerometer; autoplay; encrypted-media; gyroscope; picture-in-picture; fullscreen;" +
      (allowLocalNetwork ? " local-network-access;" : "");

  Future<void> createAndroidActivityWidget(String url,
      MatrixUserWidgetInfo info, Room room, BuildContext context) async {
    var receiveSocketPath = await AppConfig.getWidgetSocketPath();

    var file = File(receiveSocketPath);

    var bytes =
        (await rootBundle.load("assets/data/widget_runner_android.html"))
            .buffer
            .asUint8List();

    var text = Utf8Decoder().convert(bytes);

    var scriptBytes = (await rootBundle.load("assets/data/widgets_common.js"))
        .buffer
        .asUint8List();
    var scriptText = Utf8Decoder().convert(scriptBytes);

    text =
        text.replaceAll("\$RUNNER_PAGE_TITLE", "Commet Widget | ${info.name}");

    text = text.replaceAll("\$IFRAME_URL", url.toString());
    text = text.replaceAll("\$IFRAME_ALLOW", iframeAllowPermissions);
    text = text.replaceAll("\$WIDGET_ID", info.id);

    text = text.replaceAll("//\${WIDGETS_COMMON}", scriptText.toString());

    if (await file.exists()) {
      await file.delete();
    }

    var server = await bind(receiveSocketPath);
    Log.i("Server socket path: ${receiveSocketPath}");
    Log.i("Opened socket: ${server}");

    const platform = const MethodChannel('chat.commet.commetapp/utils');

    await platform.invokeMethod<bool>("openWidgetWindow", {
      "url": url,
      "socket": receiveSocketPath,
      "page": text,
    });

    var runner = MatrixWidgetAndroidRunner(
        room: room as MatrixRoom,
        widgetId: info.id,
        client: room.client as MatrixClient,
        info: info,
        socket: server,
        context: context);

    registerRunner(runner);
  }

  Future<void> createEmbeddedWidget(String url, MatrixUserWidgetInfo info,
      MatrixUserWidgetInfo widget, Room room, BuildContext context,
      {HttpServer? server}) async {
    var bytes =
        (await rootBundle.load("assets/data/widget_runner_embedded.html"))
            .buffer
            .asUint8List();

    var text = Utf8Decoder().convert(bytes);

    var scriptBytes = (await rootBundle.load("assets/data/widgets_common.js"))
        .buffer
        .asUint8List();
    var scriptText = Utf8Decoder().convert(scriptBytes);

    text =
        text.replaceAll("\$RUNNER_PAGE_TITLE", "Commet Widget | ${info.name}");

    text = text.replaceAll("\$IFRAME_URL", url.toString());
    text = text.replaceAll("\$IFRAME_ALLOW", iframeAllowPermissions);

    text = text.replaceAll("//\${WIDGETS_COMMON}", scriptText.toString());

    StreamController onExitController = StreamController();

    Log.i("Initial Page:");
    Log.i(text);

    server?.listen((request) async {
      if (request.connectionInfo!.remoteAddress.isLoopback == false) {
        request.response
          ..statusCode = 403
          ..close();
        return;
      }

      var responseBytes = Utf8Encoder().convert(text);
      Log.i("Handling request");
      await request.response
        ..headers.contentType = new ContentType("text", "html")
        ..headers.contentLength = responseBytes.length
        ..statusCode = 200
        ..add(responseBytes)
        ..close();

      Log.i("Handled initial request, closing server");
      server.close();
    });

    var builtWidget = MatrixWidgetInappwebviewRunnerWidget(
        info: info,
        widgetId: widget.id,
        initialPageData: text,
        onExitController: onExitController,
        room: room as MatrixRoom,
        server: server,
        component: this);

    var window = OverlayWindow(
        widget: builtWidget,
        title: info.name,
        onClose: onExitController.stream);

    OverlayWindowsManager.of(context).addWindow(window);
  }

  Future<void> spawnChildProcess(
      String url, Room room, MatrixUserWidgetInfo widget) async {
    var exe = Platform.resolvedExecutable;
    var process = await Process.start(
      exe,
      ['--widget_runner', '--title="commet | Widget Runner"', '--url=${url}'],
    );

    var runner = MatrixUserWidgetSubprocessRunner(
        process: process,
        room: room as MatrixRoom,
        context: navigator.currentContext!,
        widgetId: widget.id,
        info: widget,
        client: room.client as MatrixClient);

    registerRunner(runner);
  }

  Future<void> createRemoteHttpWidgetRunner(
      String url, Room room, MatrixUserWidgetInfo widget,
      {bool launchBrowser = false,
      bool useInsecureHttp = false,
      bool allowRemoteConnection = false}) async {
    final info = NetworkInfo();

    var ip = await info.getWifiIP();

    Log.i("Got IP: $ip");

    if (ip == null) {
      var interfaces = await NetworkInterface.list();
      var interface = interfaces.firstOrNull;
      var address = interface?.addresses.firstOrNull;

      ip = address?.address;
    }

    Log.i("Got IP: $ip");

    HttpServer? server;
    if (launchBrowser) {
      ip = "localhost";
      server = await spawnServerWithOpenPort();
    } else {
      if (useInsecureHttp) {
        server = await spawnServerWithOpenPort();
      } else {
        server = await spawnSelfSignedHttpsServer(ip!);
      }
    }

    Log.i("Hosted server: ${ip}");

    var runner = MatrixUserWidgetRemoteHttpRunner(
        room: room as MatrixRoom,
        widgetId: widget.id,
        client: client,
        url: url,
        info: widget,
        server: server,
        allowRemoteConnection: allowRemoteConnection,
        launchBrowser: launchBrowser,
        context: navigator.currentContext!,
        useInsecureHttp: useInsecureHttp,
        hostName: ip!);

    registerRunner(runner);
  }
}
