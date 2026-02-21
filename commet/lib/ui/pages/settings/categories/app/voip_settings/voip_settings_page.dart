import 'dart:async';

import 'package:collection/collection.dart';
import 'package:commet/client/components/voip/webrtc_default_devices.dart';
import 'package:commet/config/platform_utils.dart';
import 'package:commet/debug/log.dart';
import 'package:commet/main.dart';
import 'package:commet/ui/pages/settings/categories/app/boolean_toggle.dart';
import 'package:commet/ui/pages/settings/categories/app/voip_settings/voip_debug_settings.dart';
import 'package:flutter/widgets.dart';

import 'package:flutter_webrtc/flutter_webrtc.dart' as webrtc;
import 'package:tiamat/tiamat.dart' as tiamat;

class VoipSettingsPage extends StatefulWidget {
  const VoipSettingsPage({super.key});

  @override
  State<VoipSettingsPage> createState() => _VoipSettingsPage();
}

class _VoipSettingsPage extends State<VoipSettingsPage> {
  StreamSubscription? sub;

  List<webrtc.MediaDeviceInfo>? devices;

  List<webrtc.MediaDeviceInfo>? microphones = [];
  List<webrtc.MediaDeviceInfo>? speakers = [];
  List<webrtc.MediaDeviceInfo>? cameras = [];

  @override
  void initState() {
    super.initState();
    sub = preferences.onSettingChanged.listen((event) => setState(() {}));

    webrtc.navigator.mediaDevices.enumerateDevices().then((v) => setState(() {
          Log.i(v);
          devices = v;

          microphones = v.where((i) => i.kind == "audioinput").toList();
          speakers = v.where((i) => i.kind == "audiooutput").toList();
          cameras = v.where((i) => i.kind == "videoinput").toList();
        }));
  }

  @override
  void dispose() {
    sub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      spacing: 8,
      children: [
        tiamat.Panel(
          mode: tiamat.TileType.surfaceContainerLow,
          header: "Call Connection",
          child: BooleanPreferenceToggle(
            preference: preferences.useFallbackTurnServer,
            title: "Use TURN Fallback",
            description:
                "Calls cannot be connected without a TURN server. If your homeserver does not provide a TURN server, fall back to using '${preferences.fallbackTurnServer.value}'. Your IP address will be revealed to this server when establishing calls",
          ),
        ),
        tiamat.Panel(
          header: "Devices",
          mode: tiamat.TileType.surfaceContainerLow,
          child: devicePicker(),
        ),
        if (preferences.developerMode.value)
          const Padding(
            padding: EdgeInsets.fromLTRB(0, 8, 0, 0),
            child: tiamat.Panel(
              header: "WebRTC Debug Menu",
              mode: tiamat.TileType.surfaceContainerLow,
              child: VoipDebugSettings(),
            ),
          ),
      ],
    );
  }

  Widget devicePicker() {
    return Column(spacing: 8, children: [
      if (microphones != null && !PlatformUtils.isAndroid)
        buildPicker(
          "Default Audio Input",
          preferences.voipDefaultAudioInput.value,
          microphones!,
          onSelected: (device) async {
            await preferences.voipDefaultAudioInput.set(device?.label);

            WebrtcDefaultDevices.selectInputDevice();

            setState(() {});
          },
        ),
      if (speakers != null)
        buildPicker(
          "Audio Output",
          preferences.voipDefaultAudioOutput.value,
          speakers!,
          onSelected: (device) async {
            await preferences.voipDefaultAudioOutput.set(device?.label);

            WebrtcDefaultDevices.selectOutputDevice();
            setState(() {});
          },
        ),
      // if (cameras != null)
      //   buildPicker(
      //     "Video Input",
      //     preferences.voipDefaultVideoInput,
      //     cameras!,
      //     onSelected: (device) {
      //       setState(() {
      //         preferences.setVoipDefaultVideoInput(device?.label);
      //       });
      //     },
      //   ),
    ]);
  }

  Widget buildPicker(
      String label, String? selected, List<webrtc.MediaDeviceInfo> microphones,
      {Function(webrtc.MediaDeviceInfo? device)? onSelected}) {
    var selectedDevice =
        microphones.firstWhereOrNull((i) => i.label == selected);

    List<webrtc.MediaDeviceInfo?> items = [null, ...microphones];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        tiamat.Text.labelLow(label),
        tiamat.DropdownSelector<webrtc.MediaDeviceInfo?>(
            items: items,
            onItemSelected: onSelected,
            itemBuilder: (item) {
              if (item == null) {
                return tiamat.Text.labelLow("No Default Selected");
              } else {
                return tiamat.Text(item.label);
              }
            },
            value: selectedDevice),
      ],
    );
  }
}
