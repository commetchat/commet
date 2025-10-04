import 'dart:async';

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

  @override
  bool get isVoipRoom =>
      room.matrixRoom.getState(EventTypes.RoomCreate)?.content['type'] ==
      "org.matrix.msc3417.call";

  StreamController _onParticipantsChanged = StreamController.broadcast();

  @override
  onSync(JoinedRoomUpdate update) {
    Log.d("Got update");
    if (update.timeline?.events == null) {
      return;
    }

    for (var event in update.timeline!.events!) {
      if (event.type == callMemberStateEvent) {
        _onParticipantsChanged.add(());
      }
    }
  }

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

      final sender = pair.value.senderId;
      if (participants.contains(sender)) {
        continue;
      }

      participants.add(sender);
    }

    return participants;
  }

  @override
  Stream<void> get onParticipantsChanged => _onParticipantsChanged.stream;

  @override
  Future<VoipSession?> joinCall() async {
    currentSession = await backend.join();
    currentSession!.onStateChanged.listen(onStateChanged);
    return currentSession;
  }

  @override
  Future<String?> getCallServerUrl() async {
    final url = await backend.getFociUrl();
    return url.firstOrNull?.authority.toString();
  }

  void onStateChanged(void event) {
    final state = currentSession?.state;
    print(
      "Got call state: ${state}",
    );

    if (state == VoipState.ended) {
      currentSession = null;
    }
  }
}
