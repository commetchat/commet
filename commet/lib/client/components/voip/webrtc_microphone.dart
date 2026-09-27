// What WebRTC can tell about a microphone capture and the sender carrying
// it, and the cheapest way to restart its recording. Shared by the calls'
// microphone watch (MicrophoneHealthMonitor) and the native loop test that
// kills a capture on purpose (integration_test/voice_dsp).
import 'package:commet/client/components/voip/capture_track_state.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart' as rtc;

/// A microphone sender's running counters, null where the statistics do
/// not have them.
typedef SenderCounters = ({double? capturedSeconds, int? packetsSent});

/// Reads [sender]'s statistics: how much audio its source has handed it
/// (`media-source` `totalSamplesDuration`, which only grows while the
/// capture delivers audio) and how many RTP packets it sent
/// (`outbound-rtp`). Anything that fails reads as unknown.
Future<SenderCounters> readSenderCounters(rtc.RTCRtpSender? sender) async {
  if (sender == null) return (capturedSeconds: null, packetsSent: null);
  final List<rtc.StatsReport> reports;
  try {
    reports = await sender.getStats().timeout(const Duration(seconds: 2));
  } catch (_) {
    return (capturedSeconds: null, packetsSent: null);
  }
  double? captured;
  int? packets;
  for (final report in reports) {
    final values = report.values;
    if (values['kind'] != null && values['kind'] != 'audio') continue;
    switch (report.type) {
      case 'media-source':
        final v = values['totalSamplesDuration'];
        if (v is num) captured = (captured ?? 0) + v.toDouble();
      case 'outbound-rtp':
        final v = values['packetsSent'];
        if (v is num) packets = (packets ?? 0) + v.toInt();
    }
  }
  return (capturedSeconds: captured, packetsSent: packets);
}

/// Whether [track] was ended by the browser or the platform (the device
/// went away, the permission was revoked). A capture that ended delivers
/// nothing ever again.
bool captureEnded(rtc.MediaStreamTrack track) => captureTrackEnded(track);

/// Whether this platform can restart a capture's recording by turning the
/// track off and on ([reopenCapture]).
bool get canReopenCapture => !kIsWeb;

/// Turns a local microphone track off and on again. On desktop WebRTC
/// stops recording when every sender of the microphone is disabled and
/// starts it again when one is enabled, which also brings back a capture
/// whose recording died while WebRTC still believed it running (Windows
/// ends its capture thread on any audio device error). A track the user
/// muted in the meantime is left off. Returns whether it reopened it.
///
/// The platform calls are made directly, not through the track's
/// `enabled` setter, so [rtc.MediaStreamTrack.enabled] keeps saying what
/// the user (through LiveKit) last asked for, and is what is checked.
Future<bool> reopenCapture(rtc.MediaStreamTrack track) async {
  if (!canReopenCapture || !track.enabled) return false;
  await _setEnabled(track, false);
  if (!track.enabled) return false;
  await _setEnabled(track, true);
  // Muted while the platform was busy: the mute wins.
  if (!track.enabled) await _setEnabled(track, false);
  return true;
}

Future<void> _setEnabled(rtc.MediaStreamTrack track, bool enabled) =>
    rtc.WebRTC.invokeMethod('mediaStreamTrackSetEnable', <String, dynamic>{
      'trackId': track.id,
      'enabled': enabled,
      // Unused by the handler, which finds local tracks first.
      'peerConnectionId': 'local',
    });
