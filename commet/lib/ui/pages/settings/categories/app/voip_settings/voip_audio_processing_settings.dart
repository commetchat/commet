import 'dart:async';

import 'package:commet/client/components/voip/audio_processing/audio_dsp_settings.dart';
import 'package:commet/client/components/voip/audio_processing/audio_processing_manager.dart';
import 'package:commet/main.dart';
import 'package:commet/ui/pages/settings/categories/app/boolean_preference_toggle.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:tiamat/tiamat.dart' as tiamat;

/// Noise suppression, input sensitivity and far-end ducking controls.
/// Lives inside the Audio Settings panel of the VoIP settings page.
class VoipAudioProcessingSettings extends StatefulWidget {
  const VoipAudioProcessingSettings({super.key});

  @override
  State<VoipAudioProcessingSettings> createState() =>
      _VoipAudioProcessingSettingsState();
}

class _VoipAudioProcessingSettingsState
    extends State<VoipAudioProcessingSettings> {
  StreamSubscription? _sub;

  String get labelVoipNoiseSuppression => Intl.message("Noise suppression",
      name: "labelVoipNoiseSuppression",
      desc: "Label for the toggle that enables microphone noise suppression");

  String get labelVoipNoiseSuppressionDescription => Intl.message(
      "Removes background noise, keyboard clicks and clapping from your microphone before it is sent to others. Runs on your device.",
      name: "labelVoipNoiseSuppressionDescription",
      desc: "Describes the microphone noise suppression toggle");

  String get labelVoipInputSensitivityAuto => Intl.message(
      "Automatic input sensitivity",
      name: "labelVoipInputSensitivityAuto",
      desc:
          "Label for the toggle that lets voice detection decide when the microphone transmits");

  String get labelVoipInputSensitivityAutoDescription => Intl.message(
      "Only transmit when speech is detected. Turn off to set the threshold yourself.",
      name: "labelVoipInputSensitivityAutoDescription",
      desc: "Describes the automatic input sensitivity toggle");

  String get labelVoipInputSensitivity => Intl.message("Input sensitivity",
      name: "labelVoipInputSensitivity",
      desc: "Label for the manual microphone threshold slider");

  String get labelVoipInputSensitivityDescription => Intl.message(
      "Audio below the marker is not transmitted. Drag it just above your room's background level.",
      name: "labelVoipInputSensitivityDescription",
      desc: "Describes the manual microphone threshold slider and meter");

  String get labelVoipFarEndDucking => Intl.message(
      "Reduce echo from other participants",
      name: "labelVoipFarEndDucking",
      desc:
          "Label for the toggle that lowers the microphone while others are loud and the user is silent");

  String get labelVoipFarEndDuckingDescription => Intl.message(
      "Lowers your microphone while others are speaking loudly and you are not, so their voice does not feed back through your speakers.",
      name: "labelVoipFarEndDuckingDescription",
      desc: "Describes the far-end ducking toggle");

  String get labelVoipAudioProcessingUnavailable => Intl.message(
      "Noise suppression is not available on this platform yet.",
      name: "labelVoipAudioProcessingUnavailable",
      desc:
          "Shown instead of the audio processing settings on platforms without the voice DSP");

  String get labelVoipInputMeterIdle => Intl.message(
      "Join a voice call to see your live input level.",
      name: "labelVoipInputMeterIdle",
      desc: "Shown under the microphone level meter when not in a call");

  AudioDspReport? _report;

  @override
  void initState() {
    super.initState();
    _sub = AudioProcessingManager.instance.onReport.listen((r) {
      if (!mounted) return;
      setState(() => _report = r);
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final manager = AudioProcessingManager.instance;
    if (!manager.isSupported) {
      return Padding(
        padding: const EdgeInsets.all(8),
        child: tiamat.Text.labelLow(labelVoipAudioProcessingUnavailable),
      );
    }

    final auto = preferences.voipInputSensitivityAuto.value;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 12,
      children: [
        BooleanPreferenceToggle(
          preference: preferences.voipNoiseSuppression,
          title: labelVoipNoiseSuppression,
          description: labelVoipNoiseSuppressionDescription,
        ),
        BooleanPreferenceToggle(
          preference: preferences.voipInputSensitivityAuto,
          title: labelVoipInputSensitivityAuto,
          description: labelVoipInputSensitivityAutoDescription,
          onChanged: (_) => setState(() {}),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(8, 0, 8, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: 6,
            children: [
              tiamat.Text.labelEmphasised(labelVoipInputSensitivity),
              if (!auto)
                tiamat.Text.labelLow(labelVoipInputSensitivityDescription),
              InputLevelMeter(
                report: manager.isActive ? _report : null,
                thresholdDb: auto ? null : preferences.voipInputSensitivityDb.value,
              ),
              if (!auto)
                Row(
                  children: [
                    SizedBox(
                      width: 64,
                      child: tiamat.Text.labelLow(
                          "${preferences.voipInputSensitivityDb.value.toStringAsFixed(0)} dB"),
                    ),
                    Expanded(
                      child: tiamat.Slider(
                        min: InputLevelMeter.minDb,
                        max: InputLevelMeter.maxDb,
                        value: preferences.voipInputSensitivityDb.value
                            .clamp(InputLevelMeter.minDb, InputLevelMeter.maxDb),
                        onChanged: (value) {
                          preferences.voipInputSensitivityDb.set(value);
                          setState(() {});
                        },
                      ),
                    ),
                  ],
                ),
              if (!manager.isActive)
                tiamat.Text.labelLow(labelVoipInputMeterIdle),
            ],
          ),
        ),
        BooleanPreferenceToggle(
          preference: preferences.voipFarEndDucking,
          title: labelVoipFarEndDucking,
          description: labelVoipFarEndDuckingDescription,
        ),
      ],
    );
  }
}

/// Horizontal dBFS meter with an optional threshold marker.
class InputLevelMeter extends StatelessWidget {
  const InputLevelMeter({required this.report, this.thresholdDb, super.key});

  static const double minDb = -90;
  static const double maxDb = 0;

  final AudioDspReport? report;
  final double? thresholdDb;

  static double fraction(double db) =>
      ((db - minDb) / (maxDb - minDb)).clamp(0.0, 1.0);

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final level = report?.levelDb;
    final open = report?.gateOpen ?? false;

    return SizedBox(
      height: 14,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(7),
        child: Stack(
          fit: StackFit.expand,
          children: [
            ColoredBox(color: scheme.surfaceContainerHighest),
            if (level != null)
              Align(
                alignment: Alignment.centerLeft,
                child: FractionallySizedBox(
                  widthFactor: fraction(level),
                  child: ColoredBox(
                    color: open ? scheme.primary : scheme.outline,
                  ),
                ),
              ),
            if (thresholdDb != null)
              Align(
                alignment: Alignment(fraction(thresholdDb!) * 2 - 1, 0),
                child: Container(
                  width: 3,
                  color: scheme.onSurface,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
