import 'dart:async';

import 'package:commet/client/client.dart';
import 'package:commet/client/client_manager.dart';
import 'package:commet/client/components/profile/profile_component.dart';
import 'package:commet/client/components/activities/activities_component.dart';
import 'package:commet/client/components/component.dart';
import 'package:commet/client/components/voip/voip_session.dart';
import 'package:commet/client/components/voip/voip_stream.dart';
import 'package:commet/client/matrix/components/room_activities/matrix_activities_component.dart';
import 'package:commet/client/matrix/matrix_client.dart';
import 'package:commet/client/matrix/matrix_room.dart';
import 'package:matrix/matrix.dart' as matrix;
import 'package:test/test.dart';

// Issue #10: after joining a voice channel our own user was missing from the
// sidebar list because the sync with our call membership can arrive before
// the LiveKit session is registered with CallManager. These tests drive the
// component through its public seams: getSessions() and onSessionsChanged.

const selfUserId = "@me:example.org";
const selfDeviceId = "DEVICEA";
const otherUserId = "@other:example.org";
const roomId = "!voice:example.org";

class FakeProfile implements Profile {
  @override
  final String identifier;
  FakeProfile(this.identifier);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeSdkClient implements matrix.Client {
  @override
  final String? deviceID;
  FakeSdkClient(this.deviceID);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeMatrixClient implements MatrixClient {
  @override
  Profile? self = FakeProfile(selfUserId);

  final FakeSdkClient _sdk = FakeSdkClient(selfDeviceId);

  @override
  matrix.Client get matrixClient => _sdk;

  @override
  T? getComponent<T extends Component>() => null;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeSdkRoom implements matrix.Room {
  @override
  Map<String, Map<String, matrix.StrippedStateEvent>> states = {};

  @override
  String get id => roomId;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeMatrixRoom implements MatrixRoom {
  @override
  final String identifier;
  final FakeSdkRoom _sdk = FakeSdkRoom();

  FakeMatrixRoom(this.identifier);

  @override
  matrix.Room get matrixRoom => _sdk;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeVoipSession implements VoipSession {
  @override
  final Client client;
  @override
  final String roomId;
  @override
  final String sessionId;

  FakeVoipSession(this.client, this.roomId, this.sessionId);

  @override
  final List<VoipStream> streams = [];

  final StreamController<void> _stateChanged =
      StreamController.broadcast(sync: true);

  @override
  Stream<void> get onStateChanged => _stateChanged.stream;

  void publish(String userId, VoipStreamType type,
      {bool muted = false, bool deafened = false}) {
    streams.add(
        FakeVoipStream(userId, type, isMuted: muted, isDeafened: deafened));
    _stateChanged.add(null);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeVoipStream implements VoipStream {
  @override
  final String streamUserId;
  @override
  final VoipStreamType type;
  @override
  final bool isMuted;
  @override
  final bool isDeafened;

  FakeVoipStream(this.streamUserId, this.type,
      {this.isMuted = false, this.isDeafened = false});

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

matrix.StrippedStateEvent callMembership(String userId, String deviceId) {
  return matrix.StrippedStateEvent(
    type: MatrixActivitiesComponent.callMemberStateEvent,
    senderId: userId,
    stateKey: "_${userId}_${deviceId}_m.call",
    content: {
      "application": "m.call",
      "call_id": "",
      "device_id": deviceId,
      "scope": "m.room",
    },
  );
}

/// A membership as it arrives from sync: a full event with a timestamp.
matrix.Event callMemberEvent(
  FakeMatrixRoom room,
  String userId,
  String deviceId, {
  List<Object?>? streams,
  List<Object?>? voiceState,
  DateTime? sentAt,
  Map<String, Object?> extra = const {},
}) {
  return matrix.Event(
    type: MatrixActivitiesComponent.callMemberStateEvent,
    eventId: "\$member-$userId-$deviceId",
    senderId: userId,
    stateKey: "_${userId}_${deviceId}_m.call",
    originServerTs: sentAt ?? DateTime.now(),
    room: room.matrixRoom,
    content: {
      "application": "m.call",
      "call_id": "",
      "device_id": deviceId,
      "scope": "m.room",
      "expires": 14400000,
      if (streams != null) "chat.commet.streams": streams,
      if (voiceState != null) "chat.commet.voice_state": voiceState,
      ...extra,
    },
  );
}

RoomActivitySession callSession(MatrixActivitiesComponent component) =>
    component.getSessions().singleWhere((s) => s.application == "m.call");

Set<String> callParticipants(MatrixActivitiesComponent component) {
  final call =
      component.getSessions().where((s) => s.application == "m.call").toList();
  if (call.isEmpty) return {};
  return call.single.participants;
}

void main() {
  late FakeMatrixClient client;
  late FakeMatrixRoom room;
  late ClientManager clientManager;
  late MatrixActivitiesComponent component;

  setUp(() {
    client = FakeMatrixClient();
    room = FakeMatrixRoom(roomId);
    clientManager = ClientManager();
    component = MatrixActivitiesComponent(client, room,
        callManager: clientManager.callManager);

    // Membership sync has arrived for both users, but our LiveKit session is
    // not registered with CallManager yet.
    final selfMembership = callMembership(selfUserId, selfDeviceId);
    final otherMembership = callMembership(otherUserId, "DEVICEB");
    room.matrixRoom.states[MatrixActivitiesComponent.callMemberStateEvent] = {
      selfMembership.stateKey!: selfMembership,
      otherMembership.stateKey!: otherMembership,
    };
  });

  group("Voice channel member list", () {
    test("own membership is hidden while no call session is registered", () {
      expect(callParticipants(component), equals({otherUserId}));
    });

    test(
        "own user appears and the list refreshes once the call session is registered",
        () async {
      final changes = <void>[];
      final sub = component.onSessionsChanged.listen(changes.add);
      addTearDown(sub.cancel);

      clientManager.callManager.currentSessions
          .add(FakeVoipSession(client, roomId, "session-1"));
      await Future<void>.delayed(Duration.zero);

      expect(changes, hasLength(1));
      expect(callParticipants(component), equals({selfUserId, otherUserId}));
    });

    test("leaving the call refreshes the list and hides own stale membership",
        () async {
      final session = FakeVoipSession(client, roomId, "session-1");
      clientManager.callManager.currentSessions.add(session);

      final changes = <void>[];
      final sub = component.onSessionsChanged.listen(changes.add);
      addTearDown(sub.cancel);

      clientManager.callManager.currentSessions.remove(session);
      await Future<void>.delayed(Duration.zero);

      expect(changes, hasLength(1));
      expect(callParticipants(component), equals({otherUserId}));
    });

    test("sessions in other rooms do not refresh this room's list", () async {
      final changes = <void>[];
      final sub = component.onSessionsChanged.listen(changes.add);
      addTearDown(sub.cancel);

      clientManager.callManager.currentSessions
          .add(FakeVoipSession(client, "!elsewhere:example.org", "session-2"));
      await Future<void>.delayed(Duration.zero);

      expect(changes, isEmpty);
      expect(callParticipants(component), equals({otherUserId}));
    });
  });

  group("Live badges (issue #9)", () {
    const thirdUserId = "@third:example.org";

    void setMemberships(List<matrix.StrippedStateEvent> memberships) {
      room.matrixRoom.states[MatrixActivitiesComponent.callMemberStateEvent] = {
        for (final m in memberships) m.stateKey!: m,
      };
    }

    test("a member who reports a screen share is live", () {
      setMemberships([
        callMemberEvent(room, otherUserId, "DEVICEB", streams: ["screen"]),
      ]);

      expect(callSession(component).liveMedia[otherUserId], {LiveMedia.screen});
    });

    test("a member's devices are combined", () {
      setMemberships([
        callMemberEvent(room, otherUserId, "PHONE", streams: ["camera"]),
        callMemberEvent(room, otherUserId, "LAPTOP", streams: ["screen"]),
      ]);

      expect(callSession(component).liveMedia[otherUserId],
          {LiveMedia.screen, LiveMedia.camera});
    });

    test("streams in stripped state, which never expires, are ignored", () {
      final stripped = callMembership(otherUserId, "DEVICEB")
        ..content["chat.commet.streams"] = ["screen"];
      setMemberships([stripped]);

      expect(callParticipants(component), {otherUserId});
      expect(callSession(component).liveMedia[otherUserId], isNull);
    });

    test("an expired membership is not listed, counted from its join time", () {
      // Rewritten a minute ago, but joined five hours ago with a 4 h window.
      final joined = DateTime.now().subtract(const Duration(hours: 5));
      setMemberships([
        callMemberEvent(room, otherUserId, "DEVICEB",
            streams: ["screen"],
            sentAt: DateTime.now().subtract(const Duration(minutes: 1)),
            extra: {"created_ts": joined.millisecondsSinceEpoch}),
      ]);

      expect(callParticipants(component), isEmpty);
    });

    test("in our call, LiveKit decides who is live", () {
      setMemberships([
        callMemberEvent(room, selfUserId, selfDeviceId, streams: []),
        // Stopped sharing a moment ago; the membership hasn't caught up.
        callMemberEvent(room, otherUserId, "DEVICEB", streams: ["screen"]),
        // Not in our LiveKit room (e.g. another SFU): state is all we have.
        callMemberEvent(room, thirdUserId, "DEVICEC", streams: ["camera"]),
      ]);
      final session = FakeVoipSession(client, roomId, "session-1")
        ..publish(otherUserId, VoipStreamType.audio)
        ..publish(selfUserId, VoipStreamType.screenshare)
        ..publish(selfUserId, VoipStreamType.video);
      clientManager.callManager.currentSessions.add(session);

      final live = callSession(component).liveMedia;
      expect(live[selfUserId], {LiveMedia.screen, LiveMedia.camera});
      expect(live[otherUserId], isEmpty);
      expect(live[thirdUserId], {LiveMedia.camera});
    });

    test("the list refreshes when a stream in our call starts", () async {
      setMemberships([
        callMemberEvent(room, otherUserId, "DEVICEB", streams: []),
      ]);
      final session = FakeVoipSession(client, roomId, "session-1");
      clientManager.callManager.currentSessions.add(session);

      final changes = <void>[];
      final sub = component.onSessionsChanged.listen(changes.add);
      addTearDown(sub.cancel);

      session.publish(otherUserId, VoipStreamType.screenshare);
      await Future<void>.delayed(Duration.zero);

      expect(changes, isNotEmpty);
      expect(callSession(component).liveMedia[otherUserId], {LiveMedia.screen});
    });

    test("a membership that arrives as state refreshes the list", () async {
      // A limited sync delivers state changes outside the timeline.
      final changes = <void>[];
      final sub = component.onSessionsChanged.listen(changes.add);
      addTearDown(sub.cancel);

      component.onSync(matrix.JoinedRoomUpdate(state: [
        matrix.MatrixEvent(
          type: MatrixActivitiesComponent.callMemberStateEvent,
          content: const {},
          senderId: otherUserId,
          stateKey: "_${otherUserId}_DEVICEB_m.call",
          eventId: r"$left",
          originServerTs: DateTime.now(),
        ),
      ]));
      await Future<void>.delayed(Duration.zero);

      expect(changes, hasLength(1));
    });
  });

  group("Muted and deafened icons", () {
    const thirdUserId = "@third:example.org";

    void setMemberships(List<matrix.StrippedStateEvent> memberships) {
      room.matrixRoom.states[MatrixActivitiesComponent.callMemberStateEvent] = {
        for (final m in memberships) m.stateKey!: m,
      };
    }

    test("a member who reports being muted is muted", () {
      setMemberships([
        callMemberEvent(room, otherUserId, "DEVICEB", voiceState: ["muted"]),
      ]);

      expect(
          callSession(component).voiceState[otherUserId], {VoiceState.muted});
    });

    test("a deafened member reads as muted too", () {
      setMemberships([
        callMemberEvent(room, otherUserId, "DEVICEB", voiceState: ["deafened"]),
      ]);

      expect(callSession(component).voiceState[otherUserId],
          {VoiceState.muted, VoiceState.deafened});
    });

    test("a member who reports being unmuted has an empty state, not null", () {
      setMemberships([
        callMemberEvent(room, otherUserId, "DEVICEB", voiceState: []),
      ]);

      expect(callSession(component).voiceState[otherUserId], isEmpty);
    });

    test("a client that says nothing about it gets no icon", () {
      setMemberships([
        callMemberEvent(room, otherUserId, "DEVICEB", streams: ["screen"]),
      ]);

      expect(callSession(component).voiceState[otherUserId], isNull);
    });

    test("in our call, LiveKit decides who is muted", () {
      setMemberships([
        // Unmuted a moment ago; the membership hasn't caught up.
        callMemberEvent(room, otherUserId, "DEVICEB", voiceState: ["muted"]),
        callMemberEvent(room, selfUserId, selfDeviceId, voiceState: []),
        // Not in our LiveKit room: state is all we have.
        callMemberEvent(room, thirdUserId, "DEVICEC",
            voiceState: ["muted", "deafened"]),
      ]);
      final session = FakeVoipSession(client, roomId, "session-1")
        ..publish(otherUserId, VoipStreamType.audio)
        ..publish(selfUserId, VoipStreamType.audio,
            muted: true, deafened: true);
      clientManager.callManager.currentSessions.add(session);

      final voice = callSession(component).voiceState;
      expect(voice[otherUserId], isEmpty);
      expect(voice[selfUserId], {VoiceState.muted, VoiceState.deafened});
      expect(voice[thirdUserId], {VoiceState.muted, VoiceState.deafened});
    });

    test("only the microphone counts: a muted camera is not a muted member",
        () {
      setMemberships([
        callMemberEvent(room, otherUserId, "DEVICEB", voiceState: []),
      ]);
      final session = FakeVoipSession(client, roomId, "session-1")
        ..publish(otherUserId, VoipStreamType.audio)
        ..publish(otherUserId, VoipStreamType.video, muted: true);
      clientManager.callManager.currentSessions.add(session);

      expect(callSession(component).voiceState[otherUserId], isEmpty);
    });
  });
}
