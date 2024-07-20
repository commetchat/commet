import 'dart:async';
import 'dart:convert';

import 'package:commet/client/components/command/command_component.dart';
import 'package:commet/client/matrix/matrix_client.dart';
import 'package:commet/client/matrix/matrix_room.dart';
import 'package:commet/client/matrix/timeline_events/matrix_timeline_event_base.dart';
import 'package:commet/client/room.dart';
import 'package:commet/client/timeline_events/timeline_event_base.dart';
import 'package:commet/ui/organisms/chat/chat.dart';
import 'package:matrix/matrix.dart' as matrix;

class MatrixCommandComponent extends CommandComponent<MatrixClient> {
  @override
  MatrixClient client;

  MatrixCommandComponent(this.client) {
    client.getMatrixClient().addCommand("sendjson", sendJson);
  }

  @override
  List<String> getCommands() {
    return client.getMatrixClient().commands.keys.toList();
  }

  @override
  Future<void> executeCommand(String string, Room room,
      {TimelineEventBase? interactingEvent, EventInteractionType? type}) async {
    var mxRoom = (room as MatrixRoom).matrixRoom;
    matrix.Event? event;
    if (interactingEvent != null) {
      event = (interactingEvent as MatrixTimelineEventBase).event;
    }

    await client.getMatrixClient().parseAndRunCommand(
          mxRoom,
          string,
          inReplyTo: type == EventInteractionType.reply ? event : null,
          editEventId:
              type == EventInteractionType.edit ? event?.eventId : null,
        );
  }

  @override
  bool isExecutable(String string) {
    if (string.startsWith("/")) {
      var command = string.substring(1).split(" ").first;
      return client.getMatrixClient().commands.containsKey(command);
    }

    return false;
  }

  FutureOr<String?> sendJson(matrix.CommandArgs args) {
    var json = const JsonDecoder().convert(args.msg) as Map<String, dynamic>;

    var tx = client.getMatrixClient().generateUniqueTransactionId();
    client
        .getMatrixClient()
        .sendMessage(args.room.id, json["type"], tx, json['content']);

    return null;
  }
}
