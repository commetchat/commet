import 'dart:math';

import 'package:commet/client/client.dart';
import 'package:commet/client/simulated/simulated_peer.dart';
import 'package:commet/client/simulated/simulated_timeline.dart';
import 'package:commet/utils/rng.dart';
import 'package:flutter/material.dart';
import 'package:flutter/painting.dart';

class SimulatedRoom extends Room {
  SimulatedRoom(displayName, client) : super(RandomUtils.getRandomString(20), client) {
    identifier = RandomUtils.getRandomString(20);
    notificationCount = 1;
  }

  @override
  Future<TimelineEvent?> sendMessage(String message, {TimelineEvent? inReplyTo}) {
    // TODO: implement sendMessage
    throw UnimplementedError();
  }

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
      e.eventId = RandomUtils.getRandomString(20);
      e.status = TimelineEventStatus.sent;
      e.type = EventType.message;
      e.originServerTs = DateTime.now();
      e.sender = p;
      e.body = i.toString() + "] " + RandomUtils.getRandomString(50);
      t.events.add(e);
    }

    return t;
  }
}
