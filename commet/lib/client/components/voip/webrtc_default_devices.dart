import 'package:collection/collection.dart';
import 'package:commet/config/platform_utils.dart';
import 'package:commet/debug/log.dart';
import 'package:commet/main.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart' as webrtc;

class WebrtcDefaultDevices {
  static Future<webrtc.MediaStream?> getDefaultMicrophone() async {
    if (PlatformUtils.isAndroid || PlatformUtils.isWeb) return null;

    await initDummyConnection();

    var devices = (await getDevices())
        .where((i) => i.kind == "audioinput");

    Map<String, dynamic> constraints = {
      'echoCancellation': true,
      'noiseSuppression': true,
      'autoGainControl': false,
    };

    if (preferences.voipDefaultAudioInput.value != null) {
      var pickedDevice = devices.firstWhereOrNull(
          (i) => i.label == preferences.voipDefaultAudioInput.value);

      if (pickedDevice != null) {
        print(
            "Picked device id: ${pickedDevice.deviceId} (${pickedDevice.label})");
        constraints["deviceId"] = {'exact': pickedDevice.deviceId};

        webrtc.Helper.selectAudioInput(pickedDevice.deviceId);
      } else {
        print("Preferred audio device not found!");
      }
    } else {
      print("No default device set picking first");
    }

    return await webrtc.navigator.mediaDevices
        .getUserMedia({"audio": constraints});
  }

  static Future<List<webrtc.MediaDeviceInfo>> getDevices() async {
    await initDummyConnection();

    return webrtc.navigator.mediaDevices.enumerateDevices();
  }

  // See: https://github.com/flutter-webrtc/flutter-webrtc/issues/2018#issuecomment-4225654871
  static bool _hasCreatedDummyConnection = false;
  static Future<void> initDummyConnection() async {
    if (!_hasCreatedDummyConnection) {
      _hasCreatedDummyConnection = true;
      final _ = await webrtc.createPeerConnection(Map());
    }
  }

  static Future<String?> getDefaultMicrophoneId() async {
    if (PlatformUtils.isAndroid || PlatformUtils.isWeb) return null;

    var devices = (await getDevices())
        .where((i) => i.kind == "audioinput");

    if (preferences.voipDefaultAudioInput.value == null) return null;

    return devices
        .firstWhereOrNull(
            (i) => i.label == preferences.voipDefaultAudioInput.value)
        ?.deviceId;
  }

  static Future<void> selectInputDevice() async {
    var devices = (await getDevices())
        .where((i) => i.kind == "audioinput");

    if (preferences.voipDefaultAudioInput.value != null) {
      var pickedDevice = devices.firstWhereOrNull(
          (i) => i.label == preferences.voipDefaultAudioInput.value);

      if (pickedDevice != null) {
        print(
            "Picked device id: ${pickedDevice.deviceId} (${pickedDevice.label})");

        webrtc.Helper.selectAudioInput(pickedDevice.deviceId);
      } else {
        print("Preferred audio device not found!");
      }
    }
  }

  static Future<void> selectOutputDevice() async {
    if (preferences.voipDefaultAudioOutput.value == null) return;

    var devices = (await getDevices())
        .where((i) => i.kind == "audiooutput");

    var device = devices.firstWhereOrNull(
        (i) => i.label == preferences.voipDefaultAudioOutput.value);

    if (device != null) {
      Log.i("Setting webrtc output to: ${device.label}  (${device.deviceId})");
      webrtc.Helper.selectAudioOutput(device.deviceId);
    }
  }
}
