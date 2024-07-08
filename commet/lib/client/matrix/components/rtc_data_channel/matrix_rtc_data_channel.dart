import 'package:commet/client/components/rtc_data_channel/rtc_data_channel_component.dart';
import 'package:commet/client/matrix/components/voip/matrix_voip_session.dart';
import 'package:commet/debug/log.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';

class MatrixRtcDataChannel implements DataChannel {
  RTCDataChannel channel;
  MatrixVoipSession session;
  String? purpose;

  MatrixRtcDataChannel(this.session, this.channel, {this.purpose}) {
    channel.onMessage = onMessageReceived;

    if (purpose == null) {
      var metadata = session
          .session.remoteSDPStreamMetadata?.sdpStreamMetadatas[channel.label];
      purpose = metadata?.purpose;
    }

    if (purpose == null) {
      Log.w("Data stream opened with unknown purpose");
    }
  }

  onMessageReceived(RTCDataChannelMessage data) {
    Log.d("[$purpose] > ${data.text}");
  }

  @override
  void sendMessage(String data) {
    channel.send(RTCDataChannelMessage(data));
  }
}
