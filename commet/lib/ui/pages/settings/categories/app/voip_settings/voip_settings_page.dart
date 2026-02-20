import 'dart:async';

import 'package:collection/collection.dart';
import 'package:commet/client/components/voip/webrtc_default_devices.dart';
import 'package:commet/config/platform_utils.dart';
import 'package:commet/debug/log.dart';
import 'package:commet/main.dart';
import 'package:commet/ui/pages/settings/categories/app/boolean_toggle.dart';
import 'package:commet/ui/pages/settings/categories/app/double_preference_slider.dart';
import 'package:commet/ui/pages/settings/categories/app/string_preference_options.dart';
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
                "Calls cannot be connected without a TURN server. If your homeserver does not provide a TURN server, fall back to using '${preferences.fallbackTurnServer}'. Your IP address will be revealed to this server when establishing calls",
          ),
        ),
        tiamat.Panel(
          header: "Devices",
          mode: tiamat.TileType.surfaceContainerLow,
          child: devicePicker(),
        ),
        tiamat.Panel(
            header: "Stream Settings",
            mode: tiamat.TileType.surfaceContainerLow,
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: 12,
                children: [
                  BooleanPreferenceToggle(
                      preference: preferences.doSimulcast,
                      title: "Use simulcast",
                      description:
                          "Uploads your streams at multiple different levels of quality, so other users can decide which to use. This will use more bandwidth and system resources."),
                  DoublePreferenceSlider(
                    preference: preferences.streamBitrate,
                    min: 1,
                    max: 32,
                    units: "Mbps",
                    title: "Stream Maximum Bitrate",
                    description:
                        "Determines the overall quality of your stream. Higher is better, but also uses more resources",
                  ),
                  DoublePreferenceSlider(
                    preference: preferences.streamFramerate,
                    min: 5,
                    max: 60,
                    numDecimals: 0,
                    units: "FPS",
                    title: "Stream Framerate",
                    description:
                        "Target frames per second for screen sharing. Higher has smoother motion, but maybe reduce visual clarity.",
                  ),
                  StringPreferenceOptionsPicker(
                      preference: preferences.streamCodec,
                      title: "Stream Codec",
                      description:
                          "Choose which format to encode your stream in. Different codecs may run faster on certain devices, and may be unsupported on others. Most devices should support vp8 and h264.",
                      options: [
                        "h264",
                        "h265",
                        "vp9",
                        "vp8",
                        "av1",
                      ]),
                  StringPreferenceOptionsPicker(
                      preference: preferences.streamResolution,
                      title: "Stream Resolution",
                      description:
                          "The resolution of your stream, higher is better",
                      options: [
                        "640x360",
                        "960x540",
                        "1280x720",
                        "1920x1080",
                        "2560x1440",
                      ])
                ])),
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
