import 'dart:math';

import 'package:commet/client/client.dart';
import 'package:commet/client/simulated/simulated_peer.dart';
import 'package:commet/client/simulated/simulated_timeline.dart';
import 'package:flutter/painting.dart';

class SimulatedRoom implements Room {
  @override
  late Client client;

  @override
  late String identifier;

  @override
  ImageProvider? avatar;

  @override
  late String displayName;

  @override
  int notificationCount = 0;

  SimulatedRoom(this.displayName, this.client) {
    identifier = getRandomString(20);
    notificationCount = 1;
  }

  @override
  Future<TimelineEvent?> sendMessage(String message,
      {TimelineEvent? inReplyTo}) {
    // TODO: implement sendMessage
    throw UnimplementedError();
  }

  static const _chars =
      'AaBbCcDdEeFfGgHhIiJjKkLlMmNnOoPpQqRrSsTtUuVvWwXxYyZz1234567890';
  final Random _rnd = Random();

  String getRandomString(int length) => String.fromCharCodes(Iterable.generate(
      length, (_) => _chars.codeUnitAt(_rnd.nextInt(_chars.length))));

  @override
  Future<Timeline> getTimeline(
      {void Function(int index)? onChange,
      void Function(int index)? onRemove,
      void Function(int insertID)? onInsert,
      void Function()? onNewEvent,
      void Function()? onUpdate,
      String? eventContextId}) async {
    Timeline t = SimulatedTimeline();
    Peer p = SimulatedPeer(client, "alice@commet.chat", "alice", null);

    for (var i = 0; i < 20; i++) {
      TimelineEvent e = TimelineEvent();
      e.eventId = getRandomString(20);
      e.status = TimelineEventStatus.sent;
      e.type = EventType.message;
      e.originServerTs = DateTime.now();
      e.sender = p;
      e.body = i.toString() + "] " + getRandomString(50);
      t.events.add(e);
    }

    return t;
  }
}
