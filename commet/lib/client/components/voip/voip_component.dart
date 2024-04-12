import 'package:commet/client/client.dart';
import 'package:commet/client/components/component.dart';
import 'package:commet/client/components/voip/voip_session.dart';

abstract class VoipComponent<T extends Client> implements Component<T> {
  Stream<VoipSession> get onSessionStarted;
  Stream<VoipSession> get onSessionEnded;

  List<VoipSession> getSessionsInRoom(String roomId);
}
