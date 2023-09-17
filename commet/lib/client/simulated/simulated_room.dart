import 'dart:async';
import 'dart:math';

import 'package:commet/client/client.dart';
import 'package:commet/client/components/emoticon/emoticon.dart';
import 'package:commet/client/components/room_component.dart';
import 'package:commet/client/permissions.dart';
import 'package:commet/client/simulated/simulated_client.dart';
import 'package:commet/client/simulated/simulated_peer.dart';
import 'package:commet/client/simulated/simulated_room_permissions.dart';
import 'package:commet/client/simulated/simulated_timeline.dart';
import 'package:commet/utils/rng.dart';
import 'package:flutter/material.dart';

import '../attachment.dart';

class SimulatedRoom extends Room {
  late SimulatedPeer alice = SimulatedPeer(client, "alice@commet.chat", "alice",
      const AssetImage("assets/images/placeholder/generic/checker_green.png"));

  late SimulatedPeer bob = SimulatedPeer(client, "bob@commet.chat", "bob",
      const AssetImage("assets/images/placeholder/generic/checker_orange.png"));

  late String _identifier;
  late SimulatedRoomPermissions _permissions;
  late String _displayName;
  late bool _isDirectMessage;
  late String? _directMessagePartnerId;
  late SimulatedClient _client;
  late SimulatedTimeline _timeline;
  final StreamController<void> _onUpdate = StreamController.broadcast();

  @override
  ImageProvider<Object>? get avatar => null;

  @override
  Client get client => _client;

  @override
  String get identifier => _identifier;

  @override
  Timeline? get timeline => _timeline;

  @override
  bool get isE2EE => false;

  final List<Peer> _participants = List.empty(growable: true);

  @override
  Iterable<String> get memberIds => _participants.map((e) => e.identifier);

  @override
  int highlightedNotificationCount = 0;

  @override
  int notificationCount = 0;

  @override
  PushRule pushRule = PushRule.notify;

  @override
  List<Peer> get typingPeers => List.from([alice, bob]);

  @override
  String get developerInfo => "";

  @override
  String? get directMessagePartnerID => _directMessagePartnerId;

  @override
  String get displayName => _displayName;

  @override
  bool get isDirectMessage => _isDirectMessage;

  @override
  Stream<void> get onUpdate => _onUpdate.stream;

  @override
  Permissions get permissions => _permissions;

  @override
  Color get defaultColor => Colors.redAccent;

  @override
  TimelineEvent? get lastEvent =>
      timeline!.events.isEmpty ? null : timeline!.events.first;

  @override
  DateTime get lastEventTimestamp => DateTime.fromMicrosecondsSinceEpoch(0);

  SimulatedRoom(String displayName, SimulatedClient client,
      {bool isDm = false}) {
    _identifier = RandomUtils.getRandomString(20);
    _client = client;
    _permissions = SimulatedRoomPermissions();

    if (isDm) {
      _isDirectMessage = true;
      _directMessagePartnerId = bob.identifier;
      _participants.add(bob);
      client.addPeer(bob);
      _displayName = bob.displayName;
    } else {
      _participants.add(alice);
      _participants.add(bob);
      _participants.add(client.self!);
      client.addPeer(bob);
      client.addPeer(alice);
      _displayName = displayName;
      _isDirectMessage = false;
    }

    if (Random().nextInt(10) > 5) {
      highlightedNotificationCount = 1;
    }

    if (Random().nextInt(10) > 5) {
      notificationCount++;
    }

    _timeline = SimulatedTimeline(this.client, this);
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
    e.senderId = client.self!.identifier;
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
    e.senderId = sender.identifier;
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
  Future<void> enableE2EE() {
    throw UnimplementedError();
  }

  @override
  Future<void> setPushRule(PushRule rule) async {
    pushRule = rule;
    _onUpdate.add(null);
  }

  @override
  Future<List<ProcessedAttachment>> processAttachments(
      List<PendingFileAttachment> attachments) async {
    return List.empty();
  }

  @override
  Future<void> setTypingStatus(bool typing) async {}

  @override
  Color getColorOfUser(String userId) {
    return Colors.red;
  }

  @override
  Future<TimelineEvent?> addReaction(
      TimelineEvent reactingTo, Emoticon reaction) {
    throw UnimplementedError();
  }

  @override
  Future<void> removeReaction(TimelineEvent reactingTo, Emoticon reaction) {
    throw UnimplementedError();
  }

  @override
  Future<void> setDisplayName(String newName) async {
    _displayName = newName;
  }

  @override
  T? getComponent<T extends RoomComponent>() {
    return null;
  }
}
