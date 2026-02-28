import 'dart:async';
import 'dart:convert';

import 'package:commet/client/components/command/command_component.dart';
import 'package:commet/client/components/emoticon_recent/recent_emoticon_component.dart';
import 'package:commet/client/components/profile/profile_component.dart';
import 'package:commet/client/matrix/components/profile/matrix_profile_component.dart';
import 'package:commet/client/matrix/matrix_client.dart';
import 'package:commet/client/matrix/matrix_room.dart';
import 'package:commet/client/matrix/timeline_events/matrix_timeline_event.dart';
import 'package:commet/client/room.dart';
import 'package:commet/client/timeline_events/timeline_event.dart';
import 'package:commet/debug/log.dart';
import 'package:commet/ui/organisms/chat/chat.dart';
import 'package:commet/utils/color_utils.dart';
import 'package:flutter/widgets.dart';
import 'package:matrix/matrix.dart' as matrix;
import 'package:matrix/matrix_api_lite/generated/model.dart';
import 'package:uuid/uuid.dart';

class MatrixCommandComponent extends CommandComponent<MatrixClient> {
  @override
  MatrixClient client;

  MatrixCommandComponent(this.client) {
    client.getMatrixClient().addCommand("sendjson", sendJson);
    client.getMatrixClient().addCommand("status", setStatus);
    client.getMatrixClient().addCommand("clearemojistats", clearEmojiStats);
    client.getMatrixClient().addCommand("setprofile", setProfile);
    client.getMatrixClient().addCommand("addwidget", addWidget);
    client.getMatrixClient().addCommand("rainbow", sendRainbow);
  }

  @override
  List<String> getCommands() {
    return client.getMatrixClient().commands.keys.toList();
  }

  @override
  Future<void> executeCommand(String string, Room room,
      {TimelineEvent? interactingEvent, EventInteractionType? type}) async {
    var mxRoom = (room as MatrixRoom).matrixRoom;
    matrix.Event? event;
    if (interactingEvent != null) {
      event = (interactingEvent as MatrixTimelineEvent).event;
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

  FutureOr<String?> sendJson(matrix.CommandArgs args, StringBuffer? out) {
    var json = const JsonDecoder().convert(args.msg) as Map<String, dynamic>;

    var tx = client.getMatrixClient().generateUniqueTransactionId();
    client
        .getMatrixClient()
        .sendMessage(args.room!.id, json["type"], tx, json['content']);

    return null;
  }

  @override
  bool isPossiblyCommand(String string) {
    return string.startsWith("/");
  }

  FutureOr<String?> setStatus(
      matrix.CommandArgs args, StringBuffer? out) async {
    client.getComponent<UserProfileComponent>()?.setStatus(args.msg);

    await client.getMatrixClient().setPresence(
        client.getMatrixClient().userID!, PresenceType.online,
        statusMsg: args.msg);

    return null;
  }

  FutureOr<String?> clearEmojiStats(
      matrix.CommandArgs args, StringBuffer? out) async {
    var c = client.getComponent<RecentEmoticonComponent>();
    c?.clear();
    return null;
  }

  FutureOr<String?> setProfile(
      matrix.CommandArgs args, StringBuffer? stdout) async {
    final parts = args.msg.split(" ");
    final field = parts[0];
    final content = parts.sublist(1).join(" ");
    dynamic result = content;
    try {
      result = jsonDecode(content);
    } catch (e, s) {
      Log.onError(e, s);
    }

    var comp = client.getComponent<MatrixProfileComponent>();
    comp?.setField(field, result);

    return null;
  }

  FutureOr<String?> addWidget(
      matrix.CommandArgs args, StringBuffer? out) async {
    if (args.room == null) return null;

    var url = Uri.parse(args.msg);
    var uuid = const Uuid();
    var id = uuid.v4();

    var content = {
      "type": "m.custom",
      "url": url.toString(),
      "name": "Custom",
      "id": id,
      "creatorUserId": client.self!.identifier,
      "roomId": args.room!.id,
    };

    if (url.host == "calendar-widget.commet.chat") {
      content["type"] = "chat.commet.widgets.calendar";
      content["name"] = "Calendar";
    }

    await client.matrixClient.setRoomStateWithKey(
        args.room!.id, "im.vector.modular.widgets", id, content);

    return null;
  }

  FutureOr<String?> sendRainbow(
      matrix.CommandArgs args, StringBuffer? out) async {
    if (args.room == null) return null;
    if (args.msg.isEmpty) return null;

    String formatted = "";

    double hue = 0;
    var characters = args.msg.characters;
    for (var char in args.msg.characters) {
      var color = HSVColor.fromAHSV(1.0, hue, 1.0, 1.0);
      var c = color.toColor().toHexCode();

      hue += 360.0 / characters.length.toDouble();
      formatted += '<span data-mx-color=\"$c\">${char}</span>';
    }

    final content = {
      "msgtype": "m.text",
      "body": "test",
      "formatted_body": formatted,
      "format": "org.matrix.custom.html",
    };

    return await args.room!.sendEvent(
      content,
      inReplyTo: args.inReplyTo,
      editEventId: args.editEventId,
      txid: args.txid,
    );
  }
}
