import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:commet/client/client.dart';
import 'package:commet/client/components/widgets/widget_component.dart';
import 'package:commet/client/matrix/components/widgets/runners/in_app_web_view/matrix_widget_inappwebview_runner.dart';
import 'package:commet/client/matrix/components/widgets/runners/subprocess/matrix_widget_desktop_runner.dart';
import 'package:commet/client/matrix/components/widgets/runners/remote_http/self_signed_https_server.dart';
import 'package:commet/client/matrix/components/widgets/runners/remote_http/matrix_widget_remote_http_runner.dart';
import 'package:commet/client/matrix/matrix_client.dart';
import 'package:commet/client/matrix/matrix_room.dart';
import 'package:commet/client/room.dart';
import 'package:commet/config/platform_utils.dart';
import 'package:commet/debug/log.dart';
import 'package:commet/main.dart';
import 'package:commet/ui/organisms/overlay_windows/overlay_window_manager.dart';
import 'package:commet/utils/color_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:matrix/matrix_api_lite/utils/try_get_map_extension.dart';
import 'package:network_info_plus/network_info_plus.dart';

class MatrixUserWidgetInfo implements UserWidgetInfo {
  late String _name;

  MatrixUserWidgetInfo({
    required this.id,
    required String name,
    required this.url,
    required this.type,
  }) {
    _name = name;
  }

  @override
  String get name => _name;

  String url;

  String type;

  String id;
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

      if (url == null || type == null || name == null) continue;

      url = Uri.encodeFull(url);

      result
          .add(MatrixUserWidgetInfo(id: id, name: name, url: url, type: type));
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
  List<WidgetHostType> supportedHostTypes() {
    if (PlatformUtils.isWindows) {
      return const [
        WidgetHostType.childProcess,
        WidgetHostType.embedded,
        WidgetHostType.remoteHttpClient
      ];
    }

    if (PlatformUtils.isAndroid) {
      return const [WidgetHostType.embedded];
    }

    if (PlatformUtils.isLinux) {
      return const [
        WidgetHostType.childProcess,
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
  Future<void> openWidget(UserWidgetInfo widget, Room room,
      BuildContext context, WidgetHostType type) async {
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

    switch (type) {
      case WidgetHostType.embedded:
        await createEmbeddedWidget(url, info, widget, room, context);
        return;
      case WidgetHostType.childProcess:
        await spawnChildProcess(url, room, widget);
        return;
      case WidgetHostType.remoteHttpClient:
        await createRemoteHttpWidgetRunner(url, room, widget);
        return;
      case WidgetHostType.externalBrowser:
        await createRemoteHttpWidgetRunner(url, room, widget,
            launchBrowser: true);
        return;
    }
  }

  Future<void> createEmbeddedWidget(String url, MatrixUserWidgetInfo info,
      MatrixUserWidgetInfo widget, Room room, BuildContext context) async {
    var userScript = await rootBundle.loadString('assets/data/widgets_ipc.js');

    var common = await rootBundle.loadString('assets/data/widgets_common.js');

    var callIpc =
        await rootBundle.loadString('assets/data/call_ipc_android.js');

    var finalScript = userScript.replaceAll("//\${SEND_IPC_CODE}", callIpc);
    finalScript =
        userScript.replaceAll("//\${WIDGETS_COMMON_SCRIPT}", common.toString());

    Log.i("Final user script: $finalScript");

    var builtWidget = MatrixWidgetInappwebviewRunnerWidget(
      url: url,
      info: info,
      widgetId: widget.id,
      userScript: finalScript,
      room: room as MatrixRoom,
      component: this,
      onRunnerCreated: (p0) {
        registerRunner(p0);
      },
    );

    OverlayWindowsManager.of(context)
        .addWindow(OverlayWindow(widget: builtWidget, title: "Widget"));
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
      {bool launchBrowser = false}) async {
    final info = NetworkInfo();

    var ip = await info.getWifiIP();

    HttpServer? server;
    if (launchBrowser) {
      ip = "localhost";
      server = await HttpServer.bind(InternetAddress.anyIPv4, 4185);
    } else {
      server = await spawnSelfSignedHttpsServer(ip!);
    }

    Log.i("Hosted server: ${ip}");

    var runner = MatrixUserWidgetRemoteHttpRunner(
        room: room as MatrixRoom,
        widgetId: widget.id,
        client: client,
        url: url,
        info: widget,
        server: server,
        launchBrowser: launchBrowser,
        context: navigator.currentContext!,
        hostName: ip);

    registerRunner(runner);
  }
}
