import 'package:commet/client/client.dart';
import 'package:commet/client/components/room_component.dart';
import 'package:commet/client/components/voip/voip_session.dart';

abstract class VoipRoomComponent<R extends Client, T extends Room>
    implements RoomComponent<R, T> {
  List<String> getCurrentParticipants();

  Stream<void> get onParticipantsChanged;

  VoipSession? get currentSession;

  bool get canJoinCall;

  Future<VoipSession?> joinCall();

  Future<String?> getCallServerUrl();

  Future<void> clearAllCallMembershipStatus();
}
