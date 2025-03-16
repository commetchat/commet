import 'dart:async';

import 'package:commet/client/components/rtc_data_channel/rtc_data_channel_component.dart';
import 'package:commet/client/components/voip/voip_session.dart';
import 'package:commet/client/matrix/components/rtc_data_channel/matrix_rtc_data_channel.dart';
import 'package:commet/client/matrix/components/rtc_data_channel/matrix_rtc_data_media_stream.dart';
import 'package:commet/client/matrix/components/rtc_screen_share_annotation/matrix_rtc_screen_share_annotation_component.dart';
import 'package:commet/client/matrix/components/voip/matrix_voip_session.dart';
import 'package:commet/client/matrix/matrix_client.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:uuid/uuid.dart';

class MatrixRTCDataChannelComponent
    implements RTCDataChannelComponent<MatrixClient> {
  @override
  MatrixClient client;

  MatrixRTCDataChannelComponent(this.client);

  final StreamController<DataChannel> _onDataChannelOpened =
      StreamController.broadcast();

  @override
  Future<DataChannel?> createDataChannel(VoipSession session,
      {required String purpose}) async {
    var uuid = const Uuid();
    var label = uuid.v4();

    var sesh = session as MatrixVoipSession;
    var channel = await sesh.session.pc
        ?.createDataChannel(label, RTCDataChannelInit()..id = 1337);

    sesh.session.addLocalStream(RTCDataMediaStream(channel!), purpose);

    return MatrixRtcDataChannel(sesh, channel, purpose: purpose);
  }

  dataChannelOpenedCallback(MatrixVoipSession session, RTCDataChannel channel) {
    var newChannel = MatrixRtcDataChannel(session, channel);

    if (newChannel.purpose ==
        MatrixRtcScreenShareAnnotationComponent.rtcChannelPurpose) {
      var annotationSession = MatrixRTCScreenShareAnnotationSession(session);
      annotationSession.listen(newChannel);
    }
    _onDataChannelOpened.add(newChannel);
  }

  @override
  Stream<DataChannel> get onDataChannelOpened => _onDataChannelOpened.stream;
}
