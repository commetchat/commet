import 'dart:convert';

import 'package:commet/client/components/rtc_data_channel/rtc_data_channel_component.dart';
import 'package:commet/client/components/rtc_screen_share_annotation/rtc_screen_share_annotation_component.dart';
import 'package:commet/client/components/voip/voip_session.dart';
import 'package:commet/client/components/voip/voip_stream.dart';
import 'package:commet/client/matrix/components/voip/matrix_voip_session.dart';
import 'package:commet/client/matrix/matrix_client.dart';

// import 'package:constellation_dart/constellation_dart.dart'
//     as constellation_dart;

// ignore: implementation_imports
import 'package:flutter_webrtc/src/desktop_capturer.dart';

// ignore: implementation_imports
import 'package:flutter_webrtc/src/native/desktop_capturer_impl.dart';

dynamic constellation;

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

  bool createdCursor = false;
  String? lastSetTargetId;
  DateTime lastSetCursorTime = DateTime.fromMicrosecondsSinceEpoch(0);

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
    constellation.main();
  }

  @override
  void setCursorPosition(
      {required String streamId, required double x, required double y}) {
    var now = DateTime.now();
    var diff = now.difference(lastSetCursorTime);

    if (diff.inMilliseconds < 25) {
      return;
    }

    lastSetCursorTime = now;

    var msg = const JsonEncoder().convert({
      "stream": streamId,
      "x": x,
      "y": y,
    });

    channel?.sendMessage(msg);
  }

  void onMessageReceived(String event) {
    print("Annotation received message: $event");
    if (session.currentScreenshare == null) return;

    final userId = session.remoteUserId ?? "unknown_user_id";

    if (!createdCursor) {
      final room = session.client.getRoom(session.roomId);
      final member = room?.getMemberOrFallback(userId);

      constellation.createCursor(
          userId, session.remoteUserName ?? "Unknown User");

      if (member != null) {
        constellation.setCursorColor(userId, member.defaultColor);
      }

      createdCursor = true;
    }

    var obj = const JsonDecoder().convert(event) as Map<String, dynamic>;
    var streamId = obj["stream"] as String;
    var x = obj["x"] as num;
    var y = obj["y"] as num;

    var stream =
        session.streams.where((e) => e.streamId == streamId).firstOrNull;
    if (stream != null && stream.direction == VoipStreamDirection.outgoing) {
      if (session.currentScreenshare != null) {
        final share = session.currentScreenshare as DesktopCapturerSourceNative;
        final id = share.id;
        if (id != lastSetTargetId) {
          lastSetTargetId = session.currentScreenshare?.id;

          switch (share.type) {
            case SourceType.Screen:
              constellation.setDisplay(id);
              break;

            case SourceType.Window:
              constellation.setWindow(id);
              break;
          }
        }
      }

      constellation.setCursorPosition(userId, x.toDouble(), y.toDouble());
    }
  }
}
