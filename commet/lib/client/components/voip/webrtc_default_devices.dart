import 'package:collection/collection.dart';
import 'package:commet/debug/log.dart';
import 'package:commet/main.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart' as webrtc;

class WebrtcDefaultDevices {
  static Future<webrtc.MediaStream> getDefaultMicrophone() async {
    var devices = (await webrtc.navigator.mediaDevices.enumerateDevices())
        .where((i) => i.kind == "audioinput");

    Map<String, dynamic> constraints = {
      'echoCancellation': true,
      'noiseSuppression': true,
      'autoGainControl': false,
    };

    if (preferences.voipDefaultAudioInput != null) {
      var pickedDevice = devices.firstWhereOrNull(
          (i) => i.label == preferences.voipDefaultAudioInput);

      if (pickedDevice != null) {
        print(
            "Picked device id: ${pickedDevice.deviceId} (${pickedDevice.label})");
        constraints["deviceId"] = {'exact': pickedDevice.deviceId};
      } else {
        print("Preferred audio device not found!");
      }
    } else {
      print("No default device set picking first");
    }

    return await webrtc.navigator.mediaDevices
        .getUserMedia({"audio": constraints});
  }

  static Future<void> selectOutputDevice() async {
    if (preferences.voipDefaultAudioOutput == null) return;

    var devices = (await webrtc.navigator.mediaDevices.enumerateDevices())
        .where((i) => i.kind == "audiooutput");

    var device = devices
        .firstWhereOrNull((i) => i.label == preferences.voipDefaultAudioOutput);

    if (device != null) {
      Log.i("Setting webrtc output to: ${device.label}  (${device.deviceId})");
      webrtc.Helper.selectAudioOutput(device.deviceId);
    }
  }
}
