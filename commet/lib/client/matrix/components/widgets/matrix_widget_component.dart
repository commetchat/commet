import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:commet/client/client.dart';
import 'package:commet/client/components/widgets/widget_component.dart';
import 'package:commet/client/matrix/components/widgets/matrix_io_widget_transceiver.dart';
import 'package:commet/client/matrix/components/widgets/matrix_widget_capabilities_manager.dart';
import 'package:commet/client/matrix/components/widgets/matrix_widget_message_handler.dart';
import 'package:commet/client/matrix/components/widgets/matrix_widget_transport.dart';
import 'package:commet/client/matrix/matrix_client.dart';
import 'package:commet/client/matrix/matrix_room.dart';
import 'package:commet/client/room.dart';
import 'package:commet/config/platform_utils.dart';
import 'package:commet/debug/log.dart';
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

  MatrixUserWidgetDesktopRunner(
      {required Process process,
      required this.room,
      required this.widgetId,
      required this.client}) {
    var tx = MatrixIoWidgetTransceiver(process: process);
    messageTransport = MatrixWidgetTransport(tx);
    eventHandler = MatrixWidgetMessageHandler(runner: this);
    capabilities = MatrixWidgetCapabilitiesManager(runner: this);

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
}

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
      String? id = s.value.content.tryGet("id");
      String? url = s.value.content.tryGet("url");
      String? type = s.value.content.tryGet("type");
      String? name = s.value.content.tryGet("name");

      if (id == null || url == null || type == null || name == null) continue;

      url = Uri.encodeFull(url);

      result
          .add(MatrixUserWidgetInfo(id: id, name: name, url: url, type: type));
    }

    return result;
  }

  @override
  Future<void> openWidget(UserWidgetInfo widget, Room room) async {
    if (PlatformUtils.isLinux || PlatformUtils.isWindows) {
      var exe = Platform.resolvedExecutable;

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

      var process = await Process.start(exe, [
        '--widget_runner',
        '--title="commet | Widget Runner"',
        '--url=${url}'
      ]);

      var runner = MatrixUserWidgetDesktopRunner(
          process: process,
          room: room as MatrixRoom,
          widgetId: widget.id,
          client: room.client as MatrixClient);

      runners.add(runner);
    }
  }
}
