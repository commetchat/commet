import 'dart:async';

import 'package:commet/client/components/voip/audio_processing/audio_dsp_settings.dart';
import 'package:commet/client/components/voip/audio_processing/audio_processing_manager.dart';
import 'package:commet/config/platform_utils.dart';
import 'package:commet/main.dart';
import 'package:commet/ui/pages/settings/categories/app/boolean_preference_toggle.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:tiamat/tiamat.dart' as tiamat;

/// Noise suppression, input sensitivity and far-end ducking controls.
/// Lives inside the Audio Settings panel of the VoIP settings page.
///
/// The level meter is live during a call. Outside a call the user can start
/// a microphone test, which captures the microphone through the DSP (and
/// optionally plays it back) so the meter and the noise suppression can be
/// checked without anyone else on the line. Leaving this page stops the
/// test.
class VoipAudioProcessingSettings extends StatefulWidget {
  const VoipAudioProcessingSettings({super.key});

  @override
  State<VoipAudioProcessingSettings> createState() =>
      _VoipAudioProcessingSettingsState();
}

class _VoipAudioProcessingSettingsState
    extends State<VoipAudioProcessingSettings> {
  StreamSubscription? _sub;
  StreamSubscription? _stateSub;
  bool _starting = false;
  bool _startFailed = false;

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

  String get labelVoipInputSensitivityAutoFloorDescription => Intl.message(
      "Speech is transmitted only when it is also louder than the marker. Leave it low unless sound from your speakers gets through; then drag it between that and your voice.",
      name: "labelVoipInputSensitivityAutoFloorDescription",
      desc:
          "Describes the microphone threshold slider while automatic input sensitivity is on, where it acts as a minimum level");

  String get labelVoipSpeakerBleed => Intl.message(
      "Filter out sound from your speakers",
      name: "labelVoipSpeakerBleed",
      desc:
          "Label for the toggle that keeps audio playing on the user's speakers out of their microphone");

  String get labelVoipSpeakerBleedDescription => Intl.message(
      "If you use speakers instead of a headset, keeps what your computer is playing (videos, music, other people in the call) out of your microphone while you are not talking. Takes a second or two to adjust when something starts playing.",
      name: "labelVoipSpeakerBleedDescription",
      desc: "Describes the speaker bleed filter toggle on desktop");

  String get labelVoipSpeakerBleedDescriptionWeb => Intl.message(
      "If you use speakers instead of a headset, keeps other people in the call from coming back through your microphone. The browser cannot see other sound playing on your computer; if a video gets through, raise the input sensitivity marker above it.",
      name: "labelVoipSpeakerBleedDescriptionWeb",
      desc:
          "Describes the speaker bleed filter toggle in the browser, where only call audio can be filtered");

  String get labelVoipDspSpeakerBleed => Intl.message(
      "Holding back sound from your speakers.",
      name: "labelVoipDspSpeakerBleed",
      desc:
          "Gate state in the status line when the microphone only hears the user's speakers");

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
      "Start a microphone test or join a voice call to see your live input level.",
      name: "labelVoipInputMeterIdle",
      desc: "Shown under the microphone level meter when nothing is captured");

  String get labelVoipInputMeterInCall =>
      Intl.message("Live from your current call.",
          name: "labelVoipInputMeterInCall",
          desc: "Shown under the microphone level meter during a call");

  String get labelVoipMicTestStart => Intl.message("Test microphone",
      name: "labelVoipMicTestStart",
      desc: "Button that starts capturing the microphone for a test");

  String get labelVoipMicTestStop => Intl.message("Stop test",
      name: "labelVoipMicTestStop",
      desc: "Button that stops the microphone test");

  String get labelVoipMicTestFailed => Intl.message(
      "Could not start the microphone test. Check that a microphone is connected and allowed.",
      name: "labelVoipMicTestFailed",
      desc: "Shown when the microphone test could not start");

  String get labelVoipMicTestMonitor => Intl.message("Hear myself",
      name: "labelVoipMicTestMonitor",
      desc:
          "Toggle that plays the processed microphone back during the microphone test");

  String get labelVoipMicTestMonitorDescription => Intl.message(
      "Plays your microphone back through your speakers, exactly as others would hear it, so you can compare noise suppression on and off. Use headphones.",
      name: "labelVoipMicTestMonitorDescription",
      desc: "Describes the hear myself toggle of the microphone test");

  String get labelVoipDspNoAudio => Intl.message(
      "The audio processor is attached but no microphone audio is reaching it.",
      name: "labelVoipDspNoAudio",
      desc:
          "Diagnostic shown when the voice DSP is installed but not receiving frames");

  String labelVoipDspStatus(String rate, String suppression, String gate) =>
      Intl.message(
          "Processing $rate audio. Noise suppression $suppression. $gate",
          args: [rate, suppression, gate],
          name: "labelVoipDspStatus",
          desc:
              "Diagnostic line under the level meter: sample rate, whether noise suppression is running, gate state");

  String get labelVoipDspOn => Intl.message("on",
      name: "labelVoipDspOn",
      desc: "Noise suppression state in the status line");

  String get labelVoipDspOff => Intl.message("off",
      name: "labelVoipDspOff",
      desc: "Noise suppression state in the status line");

  String get labelVoipDspGateOpen => Intl.message("Transmitting.",
      name: "labelVoipDspGateOpen",
      desc: "Gate state in the status line when the microphone is being sent");

  String get labelVoipDspGateClosed => Intl.message("Muted by the input gate.",
      name: "labelVoipDspGateClosed",
      desc: "Gate state in the status line when the input gate is closed");

  AudioDspReport? _report;

  @override
  void initState() {
    super.initState();
    final manager = AudioProcessingManager.instance;
    _report = manager.lastReport;
    _sub = manager.onReport.listen((r) {
      if (!mounted) return;
      setState(() => _report = r);
    });
    _stateSub = manager.onStateChanged.listen((_) {
      if (!mounted) return;
      setState(() {});
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    _stateSub?.cancel();
    final manager = AudioProcessingManager.instance;
    if (manager.isTesting) manager.stopMicTest();
    super.dispose();
  }

  Future<void> _toggleTest() async {
    final manager = AudioProcessingManager.instance;
    if (manager.isTesting) {
      await manager.stopMicTest();
      if (mounted) setState(() {});
      return;
    }
    setState(() {
      _starting = true;
      _startFailed = false;
    });
    final ok = await manager.startMicTest();
    if (!mounted) return;
    setState(() {
      _starting = false;
      _startFailed = !ok;
    });
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
    final active = manager.isActive;
    final report = active ? _report : null;

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
              // A floor in automatic mode too (the VAD alone cannot tell a
              // voice from a loudspeaker), so the marker is always shown.
              tiamat.Text.labelLow(auto
                  ? labelVoipInputSensitivityAutoFloorDescription
                  : labelVoipInputSensitivityDescription),
              InputLevelMeter(
                report: report,
                thresholdDb: preferences.voipInputSensitivityDb.value,
              ),
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
              _statusLine(manager, report),
              if (!manager.isInCall) _testControls(manager),
            ],
          ),
        ),
        BooleanPreferenceToggle(
          preference: preferences.voipSpeakerBleed,
          title: labelVoipSpeakerBleed,
          description: PlatformUtils.isWeb
              ? labelVoipSpeakerBleedDescriptionWeb
              : labelVoipSpeakerBleedDescription,
        ),
        BooleanPreferenceToggle(
          preference: preferences.voipFarEndDucking,
          title: labelVoipFarEndDucking,
          description: labelVoipFarEndDuckingDescription,
        ),
      ],
    );
  }

  Widget _statusLine(AudioProcessingManager manager, AudioDspReport? report) {
    if (!manager.isActive) {
      return tiamat.Text.labelLow(labelVoipInputMeterIdle);
    }
    if (!manager.isProcessing || report == null) {
      // Installed, but the frame counter is not moving: nothing is being
      // captured, or the hook is not wired. Say so instead of a dead bar.
      return tiamat.Text.error(labelVoipDspNoAudio);
    }
    final rate = "${(report.sampleRate / 1000).toStringAsFixed(0)} kHz";
    final status = labelVoipDspStatus(
      rate,
      report.noiseSuppressionActive ? labelVoipDspOn : labelVoipDspOff,
      report.speakerBleed
          ? labelVoipDspSpeakerBleed
          : report.gateOpen
              ? labelVoipDspGateOpen
              : labelVoipDspGateClosed,
    );
    return tiamat.Text.labelLow(
        manager.isInCall ? "$labelVoipInputMeterInCall $status" : status);
  }

  Widget _testControls(AudioProcessingManager manager) {
    final testing = manager.isTesting;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 8,
      children: [
        Row(
          spacing: 12,
          children: [
            testing
                ? tiamat.Button.secondary(
                    text: labelVoipMicTestStop,
                    onTap: _starting ? null : _toggleTest,
                  )
                : tiamat.Button(
                    text: labelVoipMicTestStart,
                    isLoading: _starting,
                    onTap: _starting ? null : _toggleTest,
                  ),
            if (_startFailed)
              Expanded(child: tiamat.Text.error(labelVoipMicTestFailed)),
          ],
        ),
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  tiamat.Text.labelEmphasised(labelVoipMicTestMonitor),
                  tiamat.Text.labelLow(labelVoipMicTestMonitorDescription),
                ],
              ),
            ),
            tiamat.Switch(
              state: manager.micTestMonitor,
              onChanged: (v) => manager.setMicTestMonitor(v),
            ),
          ],
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
                  // Align hands down loose constraints; a childless ColoredBox
                  // would otherwise take zero height and never be visible.
                  heightFactor: 1,
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
