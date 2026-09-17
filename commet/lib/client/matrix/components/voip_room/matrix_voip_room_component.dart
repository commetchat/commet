import 'dart:async';

import 'package:commet/client/matrix/components/voip_room/matrix_call_membership.dart';
import 'package:commet/client/components/voip/voip_session.dart';
import 'package:commet/client/components/voip_room/voip_room_component.dart';
import 'package:commet/client/matrix/components/matrix_sync_listener.dart';
import 'package:commet/client/matrix/components/voip_room/matrix_livekit_backend.dart';
import 'package:commet/client/matrix/matrix_client.dart';
import 'package:commet/client/matrix/matrix_room.dart';
import 'package:commet/debug/log.dart';
import 'package:matrix/matrix.dart';

class MatrixVoipRoomComponent
    implements
        VoipRoomComponent<MatrixClient, MatrixRoom>,
        MatrixRoomSyncListener {
  static const callMemberStateEvent = "org.matrix.msc3401.call.member";

  @override
  MatrixClient client;

  @override
  MatrixRoom room;

  late MatrixLivekitBackend backend;

  VoipSession? currentSession;

  MatrixVoipRoomComponent(this.client, this.room) {
    backend = MatrixLivekitBackend(room);
  }

  static bool isVoipRoom(MatrixRoom room) {
    return room.matrixRoom.getState(EventTypes.RoomCreate)?.content['type'] ==
        "org.matrix.msc3417.call";
  }

  StreamController _onParticipantsChanged = StreamController.broadcast();

  @override
  onSync(JoinedRoomUpdate update) {
    if (update.timeline?.events == null) {
      return;
    }

    for (var event in update.timeline!.events!) {
      if (event.type == callMemberStateEvent) {
        _onParticipantsChanged.add(());
      }
    }
  }

  bool get _hasActiveSession =>
      currentSession != null && currentSession!.state != VoipState.ended;

  /// True when [entry] is a call membership written by this very device.
  bool _isOwnDeviceMembership(StrippedStateEvent entry) {
    if (entry.senderId != client.matrixClient.userID) return false;
    final deviceId = entry.content.tryGet<String>("device_id");
    return deviceId == client.matrixClient.deviceID;
  }

  /// A membership whose `expires` window, counted from its join time, has
  /// already elapsed. Only full [Event]s carry a timestamp; stripped state is
  /// assumed live.
  static bool isMembershipExpired(StrippedStateEvent entry) =>
      MatrixCallMembership.isExpired(entry.content,
          entry is Event ? entry.originServerTs : null, DateTime.now());

  @override
  List<String> getCurrentParticipants() {
    final state = room.matrixRoom.states[callMemberStateEvent];
    if (state == null) {
      return [];
    }

    List<String> participants = List.empty(growable: true);
    for (var pair in state.entries) {
      if (pair.value.content.isEmpty) {
        continue;
      }

      if (isMembershipExpired(pair.value)) {
        continue;
      }

      // A membership left behind by this device (the app was closed or
      // crashed mid-call) is stale: we are only in the call if we hold a live
      // session right now.
      if (_isOwnDeviceMembership(pair.value) && !_hasActiveSession) {
        continue;
      }

      final sender = pair.value.senderId;
      if (participants.contains(sender)) {
        continue;
      }

      participants.add(sender);
    }

    return participants;
  }

  @override
  Future<void> clearStaleOwnMembership() async {
    if (_hasActiveSession) return;

    final state = room.matrixRoom.states[callMemberStateEvent];
    if (state == null) return;

    final stale = [
      for (var entry in state.entries)
        if (entry.value.content.isNotEmpty &&
            _isOwnDeviceMembership(entry.value))
          entry.key,
    ];

    if (stale.isEmpty) return;

    if (!canJoinCall) {
      // Without permission to write the state event we can't clean up, the
      // local filter in getCurrentParticipants still hides it for us.
      return;
    }

    Log.i(
        "Clearing ${stale.length} stale call membership(s) in ${room.identifier}");

    await Future.wait([
      for (var stateKey in stale)
        client.matrixClient.setRoomStateWithKey(
          room.identifier,
          callMemberStateEvent,
          stateKey,
          {},
        ),
    ]);
  }

  @override
  Stream<void> get onParticipantsChanged => _onParticipantsChanged.stream;

  @override
  Future<VoipSession?> joinCall() async {
    currentSession = await backend.join();
    currentSession?.onStateChanged.listen(onStateChanged);
    return currentSession;
  }

  @override
  Future<String?> getCallServerUrl() async {
    final url = await backend.getFociUrl();
    return url.firstOrNull?.authority.toString();
  }

  void onStateChanged(void event) {
    final state = currentSession?.state;
    print("Got call state: ${state}");

    if (state == VoipState.ended) {
      currentSession = null;
    }
  }

  @override
  bool get canJoinCall => room.matrixRoom.canChangeStateEvent(
        MatrixVoipRoomComponent.callMemberStateEvent,
      );

  @override
  Future<void> clearAllCallMembershipStatus() async {
    final state = room.matrixRoom.states[callMemberStateEvent];
    if (state == null) {
      return;
    }

    var futures = [
      for (var entry in state.entries)
        if (entry.value.senderId == client.matrixClient.userID)
          client.matrixClient.setRoomStateWithKey(
            room.identifier,
            MatrixVoipRoomComponent.callMemberStateEvent,
            entry.key,
            {},
          ),
    ];

    await Future.wait(futures);
  }
}
