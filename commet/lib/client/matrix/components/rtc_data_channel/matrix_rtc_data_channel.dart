import 'dart:async';

import 'package:commet/client/components/rtc_data_channel/rtc_data_channel_component.dart';
import 'package:commet/client/matrix/components/voip/matrix_voip_session.dart';
import 'package:commet/debug/log.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';

class MatrixRtcDataChannel implements DataChannel {
  RTCDataChannel channel;
  MatrixVoipSession session;
  String? purpose;

  final StreamController<String> _onMessageReceived =
      StreamController.broadcast();

  @override
  Stream<String> get onMessageReceived => _onMessageReceived.stream;

  MatrixRtcDataChannel(this.session, this.channel, {this.purpose}) {
    channel.onMessage = receivedMessageCallback;

    if (purpose == null && channel.label != null) {
      var metadata = session.session.getRemoteSDPStreamMetadata(channel.label!);
      purpose = metadata?.purpose;
    }

    if (purpose == null) {
      Log.w("Data stream opened with unknown purpose");
    }
  }

  void receivedMessageCallback(RTCDataChannelMessage data) {
    _onMessageReceived.add(data.text);
  }

  @override
  void sendMessage(String data) {
    channel.send(RTCDataChannelMessage(data));
  }
}
