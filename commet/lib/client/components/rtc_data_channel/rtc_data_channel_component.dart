import 'package:commet/client/client.dart';
import 'package:commet/client/components/component.dart';
import 'package:commet/client/components/voip/voip_session.dart';

abstract class RTCDataChannelComponent<T extends Client>
    implements Component<T> {
  Future<DataChannel?> createDataChannel(VoipSession session,
      {required String purpose});

  Stream<DataChannel> get onDataChannelOpened;
}

abstract class DataChannel {
  void sendMessage(String data);

  Stream<String> get onMessageReceived;
}
