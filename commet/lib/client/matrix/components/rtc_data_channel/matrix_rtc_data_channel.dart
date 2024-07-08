import 'package:commet/client/components/rtc_data_channel/rtc_data_channel_component.dart';
import 'package:commet/debug/log.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';

class MatrixRtcDataChannel implements DataChannel {
  RTCDataChannel channel;

  MatrixRtcDataChannel(this.channel) {
    channel.onMessage = onMessageReceived;
  }

  onMessageReceived(RTCDataChannelMessage data) {
    Log.d("Received message: ${data.text}");
  }

  @override
  void sendMessage(String data) {
    channel.send(RTCDataChannelMessage(data));
  }
}
