import 'dart:async';
import 'dart:io';

import 'package:commet/client/client.dart';
import 'package:commet/client/components/widgets/widget_component.dart';
import 'package:commet/client/matrix/components/widgets/matrix_widget_capabilities_manager.dart';
import 'package:commet/client/matrix/components/widgets/runners/in_app_web_view/matrix_widget_in_app_web_view_page.dart';
import 'package:commet/client/matrix/components/widgets/runners/matrix_widget_desktop_runner.dart';
import 'package:commet/client/matrix/matrix_client.dart';
import 'package:commet/client/matrix/matrix_room.dart';
import 'package:commet/client/room.dart';
import 'package:commet/config/platform_utils.dart';
import 'package:commet/debug/log.dart';
import 'package:commet/main.dart';
import 'package:commet/ui/navigation/navigation_utils.dart';
import 'package:flutter/services.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:matrix/matrix_api_lite/utils/try_get_map_extension.dart';

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

  List<MatrixWidgetRunner> runners = List.empty(growable: true);

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
    runners.add(runner);

    Future.delayed(Duration(seconds: 2)).then((_) {
      runner.messageTransport.send(runner.eventHandler
          .generateToWidgetEvent(action: "capabilities", data: {}));

      // I can't explain why this is platform specific
      if (PlatformUtils.isAndroid || PlatformUtils.isWindows) {
        (runner.capabilities as MatrixWidgetCapabilitiesManager)
            .notifyCapabilities(["io.element.requires_client"]);
      }
    });
  }

  @override
  Future<void> openWidget(UserWidgetInfo widget, Room room) async {
    var info = widget as MatrixUserWidgetInfo;
    var url = Uri.encodeFull(info.url);

    var replacements = {
      "\$matrix_user_id": room.client.self!.identifier,
      "\$matrix_room_id": room.identifier,
      "\$matrix_display_name": room.client.self!.displayName,
    };

    for (var pair in replacements.entries) {
      url = url.replaceAll(pair.key, pair.value);
    }

    var uri = Uri.parse(url);

    uri = Uri(
        scheme: uri.scheme,
        host: uri.host,
        port: uri.port,
        path: uri.path,
        fragment: uri.fragment,
        queryParameters: {
          ...uri.queryParameters,
          "parentUrl": "commet://widget",
          "widgetId": info.id,
        });

    url = uri.toString();

    if (PlatformUtils.isLinux) {
      var exe = Platform.resolvedExecutable;
      var process = await Process.start(exe, [
        '--widget_runner',
        '--title="commet | Widget Runner"',
        '--url=${url}'
      ]);

      var runner = MatrixUserWidgetDesktopRunner(
          process: process,
          room: room as MatrixRoom,
          context: navigator.currentContext!,
          widgetId: widget.id,
          client: room.client as MatrixClient);

      registerRunner(runner);
    }

    if (PlatformUtils.isAndroid || PlatformUtils.isWindows) {
      var userScript =
          await rootBundle.loadString('assets/data/widgets_ipc.js');
      var callIpc =
          await rootBundle.loadString('assets/data/call_ipc_android.js');

      var finalScript = userScript.replaceAll("//\${SEND_IPC_CODE}", callIpc);

      Log.i("Final user script: $finalScript");

      var keepAlive = InAppWebViewKeepAlive();

      NavigationUtils.navigateTo(
          navigator.currentContext!,
          MatrixWidgetInappwebviewPage(
              keepAlive: keepAlive,
              info: info,
              creationParms: MatrixWidgetInAppWebviewCreationParms(
                url: url,
                userScript: finalScript,
                widgetId: widget.id,
                room: room as MatrixRoom,
                component: this,
              )));
    }
  }
}
