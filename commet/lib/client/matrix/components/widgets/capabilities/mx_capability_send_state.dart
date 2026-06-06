import 'dart:convert';

import 'package:commet/client/matrix/components/room_activities/matrix_activities_component.dart';
import 'package:commet/client/matrix/components/widgets/capabilities/matrix_widget_capability.dart';
import 'package:commet/client/matrix/components/widgets/matrix_widget_capabilities_manager.dart';
import 'package:commet/client/matrix/components/widgets/matrix_widget_component.dart';
import 'package:commet/client/matrix/components/widgets/matrix_widget_message_handler.dart';
import 'package:commet/debug/log.dart';
import 'package:commet/main.dart';
import 'package:commet/ui/atoms/code_block.dart';
import 'package:commet/ui/navigation/adaptive_dialog.dart';
import 'package:flutter/cupertino.dart';
import 'package:matrix/matrix_api_lite/utils/try_get_map_extension.dart';

class MatrixCapabilitySendStateEvent implements MatrixWidgetCapability {
  @override
  MatrixWidgetRunner runner;

  String eventType;
  String? eventKey;

  MatrixCapabilitySendStateEvent(
      {required this.runner, required this.eventType, this.eventKey});

  static String name = "org.matrix.msc2762.send.state_event";

  static MatrixWidgetCapabilityConstructorEntry entry = MapEntry(
      name,
      (runner, type, key) => MatrixCapabilitySendStateEvent(
          runner: runner, eventType: type!, eventKey: key));

  static String getNameForType(String eventType, String? key) =>
      key == null ? "$name:$eventType" : "$name:$eventType#$key";

  List<(String, String?)> widgetSetCallMemberships = List.empty(growable: true);

  @override
  String toString() {
    return "Send State event: $eventType";
  }

  @override
  bool canHandleRequest(MatrixWidgetMessage message) {
    if (message.action != "send_event") return false;

    var type = message.data.tryGet<String>("type");
    if (type != eventType) return false;

    if (message.data.containsKey("state_key") == false) return false;

    if (eventKey != null && message.data["state_key"] != eventKey) return false;

    return true;
  }

  @override
  Future<MatrixWidgetMessage> handleRequest(MatrixWidgetMessage message) async {
    var key = message.data.tryGet<String>("state_key");
    var content = message.data.tryGetMap<String, dynamic>("content");

    if (eventType == "m.room.power_levels") {
      if (await AdaptiveDialog.confirmation(
            navigator.currentContext!,
            prompt:
                "'${runner.info.name}' wants to change the room power levels:",
            customBuilder: (p0) {
              return SizedBox(
                child: Codeblock(
                  text: JsonEncoder.withIndent("  ").convert(content),
                  language: "json",
                ),
              );
            },
          ) !=
          true) {
        throw Exception("Request denied");
      }
    }

    if (content == null)
      return message.createResponseError(message: "Invalid message");

    if (eventType == MatrixActivitiesComponent.callMemberStateEvent) {
      if (content.isNotEmpty == true) {
        Log.i("Widget set call membership state: ${key}");
        widgetSetCallMemberships.add((eventType, key));
      }
    }

    var result = await runner.room!.matrixRoom.client
        .setRoomStateWithKey(runner.room!.identifier, eventType, key!, content);

    runner.messageTransport.send(
        runner.eventHandler.generateToWidgetEvent(action: "send_event", data: {
      "content": content,
      "sender": runner.client.self!.identifier,
      "state_key": key,
      "type": eventType,
      "event_id": result,
      "origin_server_ts": DateTime.now().millisecondsSinceEpoch,
      "room_id": runner.room!.identifier
    }));

    return message.createResponseObject(
        response: {"room_id": runner.room!.identifier, "event_id": result});
  }

  @override
  void dispose() {
    WidgetsBinding.instance.addPostFrameCallback(
      (timeStamp) {
        cleanUpCallMemberships();
      },
    );
  }

  Future<void> cleanUpCallMemberships() async {
    Log.d("Cleaning up widget's call membership state");
    for (var entry in widgetSetCallMemberships) {
      var type = entry.$1;
      var key = entry.$2;

      Log.d(("Type: ${type}, key: ${key}"));
      if (key != null) {
        var currentState = runner.room!.matrixRoom.states[type];

        if (currentState == null) continue;

        var current = currentState[key];
        if (current == null) return;

        if (current.content.isNotEmpty) {
          await runner.client.matrixClient
              .setRoomStateWithKey(runner.room!.identifier, type, key, {});
        }
      }
    }
  }
}
