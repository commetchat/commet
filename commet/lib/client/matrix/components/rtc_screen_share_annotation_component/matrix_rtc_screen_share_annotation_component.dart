import 'dart:convert';

import 'package:commet/client/components/rtc_data_channel/rtc_data_channel_component.dart';
import 'package:commet/client/components/rtc_screen_share_annotation/rtc_screen_share_annotation_component.dart';
import 'package:commet/client/components/voip/voip_session.dart';
import 'package:commet/client/components/voip/voip_stream.dart';
import 'package:commet/client/matrix/components/voip/matrix_voip_session.dart';
import 'package:commet/client/matrix/matrix_client.dart';

import 'package:constellation_dart/constellation_dart.dart'
    as constellation_dart;
import 'package:flutter_webrtc/src/desktop_capturer.dart';

// ignore: implementation_imports
import 'package:flutter_webrtc/src/native/desktop_capturer_impl.dart';

class MatrixRtcScreenShareAnnotationComponent
    implements RTCScreenShareAnnotationComponent<MatrixClient> {
  @override
  MatrixClient client;

  MatrixRtcScreenShareAnnotationComponent(this.client);

  static const String rtcChannelPurpose = "chat.commet.screenshare_annotation";

  @override
  Future<RTCScreenShareAnnotationSession> createSession(
      VoipSession session) async {
    var annotationSession =
        MatrixRTCScreenShareAnnotationSession(session as MatrixVoipSession);

    await annotationSession.create();
    return annotationSession;
  }
}

class MatrixRTCScreenShareAnnotationSession
    implements RTCScreenShareAnnotationSession {
  MatrixVoipSession session;
  DataChannel? channel;

  bool createdCursor = false;
  String? lastSetTargetId;

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
    constellation_dart.main();
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
    if (session.currentScreenshare == null) return;

    final userId = session.remoteUserId ?? "unknown_user_id";

    if (!createdCursor) {
      final room = session.client.getRoom(session.roomId);
      final member = room?.getMemberOrFallback(userId);

      constellation_dart.createCursor(
          userId, session.remoteUserName ?? "Unknown User");

      if (member != null) {
        constellation_dart.setCursorColor(userId, member.defaultColor);
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
      print(
          "We own this stream, and we are screensharing: ${session.currentScreenshare?.name} ${session.currentScreenshare?.id}");

      if (session.currentScreenshare != null) {
        final share = session.currentScreenshare as DesktopCapturerSourceNative;
        final id = share.type == SourceType.Window ? share.id : share.name;
        if (id != lastSetTargetId) {
          lastSetTargetId = session.currentScreenshare?.id;
          switch (share.type) {
            case SourceType.Screen:
              constellation_dart.setDisplay(id);
              break;

            case SourceType.Window:
              constellation_dart.setWindow(id);
              break;
          }
        }
      }

      constellation_dart.setCursorPosition(userId, x.toDouble(), y.toDouble());
    }
  }
}
