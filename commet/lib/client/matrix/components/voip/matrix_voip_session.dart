import 'package:commet/client/client.dart';
import 'package:commet/client/components/voip/voip_session.dart';
import 'package:commet/client/matrix/matrix_client.dart';
import 'package:matrix/matrix.dart' as matrix;

class MatrixVoipSession implements VoipSession {
  matrix.CallSession session;

  @override
  late Client client;

  MatrixVoipSession(this.session, MatrixClient this.client);

  @override
  String? get remoteUserId => session.remotePartyId;

  @override
  String get roomId => session.room.id;

  @override
  String get sessionId => session.callId;
}
