import 'dart:math';

import 'package:commet/client/client.dart';
import 'package:commet/client/simulated/simulated_peer.dart';
import 'package:commet/client/simulated/simulated_room_permissions.dart';
import 'package:commet/client/simulated/simulated_timeline.dart';
import 'package:commet/utils/rng.dart';
import 'package:flutter/material.dart';
import 'package:flutter/painting.dart';

import '../attachment.dart';

class SimulatedRoom extends Room {
  late Peer alice = SimulatedPeer(client, "alice@commet.chat", "alice",
      const AssetImage("assets/images/placeholder/generic/checker_green.png"));
  late Peer bob = SimulatedPeer(client, "bob@commet.chat", "bob",
      const AssetImage("assets/images/placeholder/generic/checker_orange.png"));

  @override
  bool get isMember => true;

  @override
  bool get isE2EE => false;

  final List<Peer> _participants = List.empty(growable: true);

  @override
  Iterable<Peer> get members => _participants;

  @override
  int highlightedNotificationCount = 0;

  @override
  int notificationCount = 0;

  @override
  PushRule pushRule = PushRule.notify;

  @override
  List<Peer> get typingPeers => List.from([alice, bob]);

  SimulatedRoom(displayName, client, {bool isDm = false})
      : super(RandomUtils.getRandomString(20), client) {
    identifier = RandomUtils.getRandomString(20);

    permissions = SimulatedRoomPermissions();

    if (isDm) {
      isDirectMessage = true;
      directMessagePartnerID = bob.identifier;
      _participants.add(bob);
      this.displayName = bob.displayName;
    } else {
      _participants.add(alice);
      _participants.add(bob);
      _participants.add((client as Client).user!);
      this.displayName = displayName;
    }

    if (Random().nextInt(10) > 5) {
      highlightedNotificationCount = 1;
    }

    if (Random().nextInt(10) > 5) {
      notificationCount++;
    }

    timeline = SimulatedTimeline(this.client, this);
    addMessage();
  }

  @override
  Future<TimelineEvent?> sendMessage({
    String? message,
    TimelineEvent? inReplyTo,
    TimelineEvent? replaceEvent,
    List<PendingFileAttachment>? attachments,
    dynamic processedAttachments,
  }) async {
    TimelineEvent e = TimelineEvent();
    e.eventId = RandomUtils.getRandomString(20);
    e.status = TimelineEventStatus.sent;
    e.type = EventType.message;
    e.originServerTs = DateTime.now();
    e.sender = client.user!;
    e.body = message;
    timeline!.insertEvent(0, e);
    return e;
  }

  TimelineEvent generateRandomEvent() {
    Peer sender = Random().nextDouble() > 0.5 ? alice : bob;

    if (isDirectMessage) sender = bob;
    TimelineEvent e = TimelineEvent();
    e.eventId = RandomUtils.getRandomString(20);
    e.status = TimelineEventStatus.synced;
    e.type = EventType.message;
    e.originServerTs = DateTime.now();
    e.sender = sender;
    e.body = RandomUtils.getRandomSentence(Random().nextInt(10) + 10);
    return e;
  }

  void addRandomEvent(int index) {
    var e = generateRandomEvent();
    timeline!.insertEvent(index, e);
  }

  Future<void> addMessage() async {
    await Future.delayed(const Duration(seconds: 1), () {
      addRandomEvent(0);
    });

    addMessage();
  }

  @override
  Future<void> setDisplayNameInternal(String name) async {
    displayName = name;
  }

  @override
  Future<void> enableE2EE() {
    throw UnimplementedError();
  }

  @override
  Future<void> setPushRule(PushRule rule) async {
    pushRule = rule;
    onUpdate.add(null);
  }

  @override
  Future<List<ProcessedAttachment>> processAttachments(
      List<PendingFileAttachment> attachments) async {
    return List.empty();
  }

  @override
  Future<void> setTypingStatus(bool typing) async {}
}
