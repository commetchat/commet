import 'dart:async';

import 'package:commet/client/client.dart';
import 'package:commet/client/client_manager.dart';
import 'package:commet/client/components/profile/profile_component.dart';
import 'package:commet/client/components/component.dart';
import 'package:commet/client/components/voip/voip_session.dart';
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
}
