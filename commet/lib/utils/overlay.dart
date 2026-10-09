import 'dart:io';

import 'package:commet/client/client.dart';
import 'package:commet/client/components/widgets/widget_component.dart';
import 'package:commet/client/matrix/components/widgets/matrix_widget_component.dart';
import 'package:commet/client/matrix/components/widgets/runners/subprocess/matrix_widget_desktop_runner.dart';
import 'package:commet/client/matrix/matrix_client.dart';
import 'package:commet/client/matrix/matrix_room.dart';
import 'package:commet/debug/log.dart';
import 'package:commet/utils/image_or_icon.dart';
import 'package:flutter/material.dart';
import 'package:matrix/matrix_api_lite.dart';

class VoipOverlay {
  static void spawn(Client client, Room room, BuildContext context) async {
    var component = client.getComponent<WidgetComponent>();

    var exe = Platform.resolvedExecutable;

    var process = await Process.start(exe, [
      '--overlay',
    ]);

    var runner = MatrixUserWidgetSubprocessRunner(
        process: process,
        room: room as MatrixRoom,
        context: context,
        widgetId: "chat.commet.voip_overlay",
        info: MatrixUserWidgetInfo(
            id: "chat.commet.voip_overlay",
            name: "Overlay",
            stateKey: "",
            url: "",
            type: "chat.commet.voip_overlay",
            icon: ImageOrIcon(icon: Icons.screen_share),
            roomId: room.identifier,
            event: StrippedStateEvent(type: "", content: {}, senderId: "")),
        client: room.client as MatrixClient);

    (component as MatrixWidgetComponent).registerRunner(runner);

    process.exitCode.then((i) {
      Log.i("Subprocess exited: $i");
    });
  }
}
