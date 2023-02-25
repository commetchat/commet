import 'dart:math';

import 'package:commet/client/attachment.dart';
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
    this.displayName = displayName;
    timeline = SimulatedTimeline();
    addMessage();
  }

  @override
  Future<TimelineEvent?> sendMessage(String message, {TimelineEvent? inReplyTo}) {
    // TODO: implement sendMessage
    throw UnimplementedError();
  }

  void addMessage() async {
    Peer p = SimulatedPeer(client, "alice@commet.chat", "alice", null);
    print("Adding message");

    await Future.delayed(const Duration(seconds: 1), () {
      TimelineEvent e = TimelineEvent();
      e.eventId = RandomUtils.getRandomString(20);
      e.status = TimelineEventStatus.sent;
      e.type = EventType.message;
      e.originServerTs = DateTime.now();
      e.sender = p;
      e.body = RandomUtils.getRandomSentence(Random().nextInt(10) + 10);
      if (Random().nextInt(10) > 7) {
        e.attachments = List.empty(growable: true);
        for (int i = 0; i < Random().nextInt(3) + 1; i++) {
          e.attachments!.add(Attachment("https://picsum.photos/200/300", "image"));
        }
      }
      timeline!.insertEvent(0, e);
    });

    addMessage();
  }
}
