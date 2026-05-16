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
import 'package:intl/intl.dart';
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

  String get headerVoipSettingsCallConnection => Intl.message("Call Connection",
      name: "headerVoipSettingsCallConnection",
      desc:
          "Header for the settings tile containing configuration relating to the initial connection of a call");

  String get labelVoipSettingsStunFallback => Intl.message("Use STUN Fallback",
      name: "labelVoipSettingsStunFallback",
      desc:
          "label for the setting to enable STUN callback for connecting calls");

  String labelVoipSettingsStunFallbackDescription(String stunServer) =>
      Intl.message(
          "Calls cannot be connected without a STUN server. If your homeserver does not provide a STUN server, fall back to using '${stunServer}'. Your IP address will be revealed to this server when establishing calls",
          args: [stunServer],
          name: "labelVoipSettingsStunFallbackDescription");

  String get headerVoipSettingsDevices => Intl.message("Devices",
      name: "headerVoipSettingsDevices",
      desc:
          "Header for settings tile containing device configuration, for default audio / video inputs");

  String get headerVoipSettingsStreamSettings => Intl.message("Stream Settings",
      name: "headerVoipSettingsStreamSettings",
      desc: "Header for settings tile containing stream quality configuration");

  String get labelVoipUseSimulcast => Intl.message("Use Simulcast",
      name: "labelVoipUseSimulcast",
      desc: "label for setting toggle to enable use of Simulcast");

  String get labelVoipUseSimulcastDescription => Intl.message(
      "Uploads your streams at multiple different levels of quality, so other users can decide which to use. This will use more bandwidth and system resources.",
      name: "labelVoipUseSimulcastDescription",
      desc: "description for setting toggle to enable use of Simulcast");

  String get labelVoipStreamMaximumBitrate => Intl.message(
      "Stream Maximum Bitrate",
      name: "labelVoipStreamMaximumBitrate",
      desc:
          "label for setting slider to set the maximum bitrate that can be used when streaming");

  String get labelVoipStreamMaximumBitrateDescription => Intl.message(
        "Determines the overall quality of your stream. Higher is better, but also uses more resources",
        name: "labelVoipStreamMaximumBitrateDescription",
      );

  String get labelVoipStreamFramerate => Intl.message("Stream Framerate",
      name: "labelVoipStreamFramerate",
      desc:
          "label for setting slider to set the framerate at which the screen should be captured when streaming");

  String get labelVoipStreamFramerateDescription => Intl.message(
        "Target frames per second for screen sharing. Higher has smoother motion, but maybe reduce visual clarity.",
        name: "labelVoipStreamFramerateDescription",
      );

  String get labelVoipStreamPreferredCodec => Intl.message(
        "Preferred Stream Codec",
        name: "labelVoipStreamPreferredCodec",
      );

  String get labelVoipStreamPreferredCodecDescription => Intl.message(
      "Choose which format to encode your stream in. Different codecs may run faster on certain devices, and may be unsupported on others. Most devices should support vp8 and h264.",
      name: "labelVoipStreamPreferredCodecDescription",
      desc:
          "Explains the preferred stream codec setting. This is just a preference, and the picked codec may not be used if the user's device does not support it");

  String get labelVoipStreamResolution => Intl.message(
        "Stream Resolution",
        name: "labelVoipStreamResolution",
      );

  String get labelVoipStreamResolutionDescription => Intl.message(
        "The resolution of your stream, higher is better",
        name: "labelVoipStreamResolutionDescription",
      );

  String get headerVoipSettingsAudioSettings => Intl.message("Audio Settings",
      name: "headerVoipSettingsAudioSettings",
      desc:
          "Header for settings tile containing stream audio quality configuration");

  String get labelVoipAudioBitrateSettings => Intl.message("Audio Bitrate",
      name: "labelVoipAudioBitrateSettings",
      desc:
          "label for the slider to adjust the bitrate of outgoing audio on a call");

  String get labelVoipAudioBitrateSettingsDescription => Intl.message(
      "Adjust the bitrate of your outgoing audio. Higher is better",
      name: "labelVoipAudioBitrateSettingsDescription",
      desc:
          "describes the behavior for the slider to adjust the bitrate of outgoing audio on a call");

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
          header: headerVoipSettingsCallConnection,
          child: BooleanPreferenceToggle(
            preference: preferences.useFallbackTurnServer,
            title: labelVoipSettingsStunFallback,
            description: labelVoipSettingsStunFallbackDescription(
                preferences.fallbackTurnServer.value),
          ),
        ),
        tiamat.Panel(
          header: headerVoipSettingsDevices,
          mode: tiamat.TileType.surfaceContainerLow,
          child: devicePicker(),
        ),
        tiamat.Panel(
            header: headerVoipSettingsAudioSettings,
            mode: tiamat.TileType.surfaceContainerLow,
            child: Column(children: [
              DoublePreferenceSlider(
                preference: preferences.streamAudioBitrate,
                title: labelVoipAudioBitrateSettings,
                description: labelVoipAudioBitrateSettingsDescription,
                numDecimals: 0,
                min: 8,
                max: 128,
                units: "Kbps",
              ),
            ])),
        tiamat.Panel(
            header: headerVoipSettingsStreamSettings,
            mode: tiamat.TileType.surfaceContainerLow,
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: 12,
                children: [
                  BooleanPreferenceToggle(
                      preference: preferences.doSimulcast,
                      title: labelVoipUseSimulcast,
                      description: labelVoipUseSimulcastDescription),
                  DoublePreferenceSlider(
                    preference: preferences.streamBitrate,
                    min: 1,
                    max: 32,
                    units: "Mbps",
                    title: labelVoipStreamMaximumBitrate,
                    description: labelVoipStreamMaximumBitrateDescription,
                  ),
                  DoublePreferenceSlider(
                    preference: preferences.streamFramerate,
                    min: 5,
                    max: 60,
                    numDecimals: 0,
                    units: "FPS",
                    title: labelVoipStreamFramerate,
                    description: labelVoipStreamFramerateDescription,
                  ),
                  StringPreferenceOptionsPicker(
                      preference: preferences.streamCodec,
                      title: labelVoipStreamPreferredCodec,
                      description: labelVoipStreamPreferredCodecDescription,
                      options: [
                        "h264",
                        "h265",
                        "vp9",
                        "vp8",
                        "av1",
                      ]),
                  if (preferences.developerMode.value)
                    StringPreferenceOptionsPicker(
                        preference: preferences.streamResolution,
                        title: labelVoipStreamResolution,
                        description: labelVoipStreamResolutionDescription,
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
