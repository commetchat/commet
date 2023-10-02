// ignore_for_file: invalid_use_of_protected_member

import 'package:commet/client/client.dart';
import 'package:commet/client/simulated/simulated_client.dart';
import 'package:commet/client/simulated/simulated_room.dart';
import 'package:commet/client/simulated/simulated_space.dart';
import 'package:commet/client/simulated/simulated_timeline_event.dart';
import 'package:test/test.dart';

void main() async {
  SimulatedClient client = SimulatedClient();
  await client.login(LoginType.loginPassword, "sim", "example.com");

  SimulatedRoom simulatedRoom = SimulatedRoom("Simulated Room", client);
  client.addRoom(simulatedRoom);

  SimulatedSpace simulatedSpace = SimulatedSpace("Simulated Space", client);
  client.addSpace(simulatedSpace);

  simulatedSpace.addRoom(simulatedRoom);

  simulatedRoom.notificationCount = 1;
  simulatedRoom.highlightedNotificationCount = 1;

  Room room = simulatedRoom;
  Space space = simulatedSpace;

  test("Display Notifications (Room): PushRule.notify", () async {
    simulatedRoom.setPushRule(PushRule.notify);
    expect(room.displayNotificationCount, equals(1));
    expect(room.displayHighlightedNotificationCount, equals(1));
  });

  test("Display Notifications (Room): PushRule.mentionsOnly", () async {
    simulatedRoom.setPushRule(PushRule.mentionsOnly);
    expect(room.displayNotificationCount, equals(0));
    expect(room.displayHighlightedNotificationCount, equals(1));
  });

  test("Display Notifications (Room): PushRule.dontNotify", () async {
    simulatedRoom.setPushRule(PushRule.dontNotify);
    expect(room.displayNotificationCount, equals(0));
    expect(room.displayHighlightedNotificationCount, equals(0));
  });

  test("Display Notifications (Space): PushRule.notify", () async {
    simulatedRoom.setPushRule(PushRule.notify);
    simulatedSpace.setPushRule(PushRule.notify);

    expect(space.displayNotificationCount, equals(1));
    expect(space.displayHighlightedNotificationCount, equals(1));
  });

  test("Display Notifications (Space): PushRule.notify (space only)", () async {
    simulatedRoom.setPushRule(PushRule.dontNotify);
    simulatedSpace.setPushRule(PushRule.notify);

    expect(space.displayNotificationCount, equals(0));
    expect(space.displayHighlightedNotificationCount, equals(0));
  });

  test("Display Notifications (Space): PushRule.notify (room only)", () async {
    simulatedRoom.setPushRule(PushRule.notify);
    simulatedSpace.setPushRule(PushRule.dontNotify);

    expect(space.displayNotificationCount, equals(0));
    expect(space.displayHighlightedNotificationCount, equals(0));
  });

  test("Display Notifications (Space): PushRule.mentionsOnly (space only)",
      () async {
    simulatedRoom.setPushRule(PushRule.dontNotify);
    simulatedSpace.setPushRule(PushRule.mentionsOnly);

    expect(space.displayNotificationCount, equals(0));
    expect(space.displayHighlightedNotificationCount, equals(0));
  });

  test("Display Notifications (Space): PushRule.mentionsOnly (room only)",
      () async {
    simulatedRoom.setPushRule(PushRule.mentionsOnly);
    simulatedSpace.setPushRule(PushRule.dontNotify);

    expect(space.displayNotificationCount, equals(0));
    expect(space.displayHighlightedNotificationCount, equals(0));
  });

  test("Display Notifications (Space): room: mentionsOnly space: notify",
      () async {
    simulatedRoom.setPushRule(PushRule.mentionsOnly);
    simulatedSpace.setPushRule(PushRule.notify);

    expect(space.displayNotificationCount, equals(0));
    expect(space.displayHighlightedNotificationCount, equals(1));
  });

  test("shouldDisplayNotification: message from self", () async {
    simulatedRoom.setPushRule(PushRule.notify);
    simulatedSpace.setPushRule(PushRule.notify);

    TimelineEvent event = SimulatedTimelineEvent(
        senderId: client.self!.identifier,
        originServerTs: DateTime.now(),
        body: "Test Message",
        eventId: "DUMMY_ID");

    expect(room.timeline!.shouldDisplayNotification(event), isFalse);
  });

  test("shouldDisplayNotification: message from other (PushRule.notify)",
      () async {
    simulatedRoom.setPushRule(PushRule.notify);
    simulatedSpace.setPushRule(PushRule.notify);

    TimelineEvent event = SimulatedTimelineEvent(
        senderId: simulatedRoom.bob.identifier,
        originServerTs: DateTime.now(),
        body: "Test Message",
        eventId: "DUMMY_ID");

    expect(room.timeline!.shouldDisplayNotification(event), isTrue);
  });

  test(
      "shouldDisplayNotification: message from other (PushRule.dontNotify) (room)",
      () async {
    simulatedRoom.setPushRule(PushRule.dontNotify);
    simulatedSpace.setPushRule(PushRule.notify);

    TimelineEvent event = SimulatedTimelineEvent(
        senderId: simulatedRoom.bob.identifier,
        originServerTs: DateTime.now(),
        body: "Test Message",
        eventId: "DUMMY_ID");
    expect(room.timeline!.shouldDisplayNotification(event), isFalse);
  });

  test(
      "shouldDisplayNotification: message from other (PushRule.dontNotify) (space)",
      () async {
    simulatedRoom.setPushRule(PushRule.notify);
    simulatedSpace.setPushRule(PushRule.dontNotify);

    TimelineEvent event = SimulatedTimelineEvent(
        senderId: simulatedRoom.bob.identifier,
        originServerTs: DateTime.now(),
        body: "Test Message",
        eventId: "DUMMY_ID");

    expect(room.timeline!.shouldDisplayNotification(event), isFalse);
  });
}
