import 'dart:convert';

import 'package:commet/client/components/rtc_data_channel/rtc_data_channel_component.dart';
import 'package:commet/client/components/rtc_screen_share_annotation/rtc_screen_share_annotation_component.dart';
import 'package:commet/client/components/voip/voip_session.dart';
import 'package:commet/client/matrix/components/voip/matrix_voip_session.dart';
import 'package:commet/client/matrix/matrix_client.dart';
import 'package:commet/service/background_service.dart';

class MatrixRtcScreenShareAnnotationComponent
    implements RTCScreenShareAnnotationComponent<MatrixClient> {
  @override
  MatrixClient client;

  MatrixRtcScreenShareAnnotationComponent(this.client);

  final Map<String, RTCScreenShareAnnotationSession> _sessions = {};

  static const String rtcChannelPurpose = "chat.commet.screenshare_annotation";

  @override
  Future<RTCScreenShareAnnotationSession> createSession(
      VoipSession session) async {
    var annotationSession =
        MatrixRTCScreenShareAnnotationSession(session as MatrixVoipSession);

    await annotationSession.create();
    _sessions[session.sessionId] = annotationSession;
    return annotationSession;
  }

  @override
  Future<RTCScreenShareAnnotationSession> getOrCreateSession(
      VoipSession session) async {
    var existing = _sessions[session.sessionId];
    if (existing != null) {
      return existing;
    }

    return createSession(session);
  }

  @override
  RTCScreenShareAnnotationSession? getExistingSession(VoipSession session) {
    return _sessions[session.sessionId];
  }
}

class MatrixRTCScreenShareAnnotationSession
    implements RTCScreenShareAnnotationSession {
  MatrixVoipSession session;
  DataChannel? channel;

  MatrixRTCScreenShareAnnotationSession(this.session);

  Future<void> create() async {
    var dataChannelComp =
        session.client.getComponent<RTCDataChannelComponent>()!;

    channel = await dataChannelComp.createDataChannel(session,
        purpose: MatrixRtcScreenShareAnnotationComponent.rtcChannelPurpose);
  }

  void listen(DataChannel? remoteChannel) {
    channel = remoteChannel;
    channel!.onMessageReceived.listen(onMessageReceived);
  }

  @override
  void setCursorPosition(
      {required String streamId, required double x, required double y}) {
    var msg = const JsonEncoder().convert({
      "stream": streamId,
      "x": x,
      "y": y,
    });

    channel?.sendMessage(msg);
  }

  void onMessageReceived(String event) {
    print("Annotation received message: $event");
  }
}
