// Whether we still receive the people we are meant to hear.
//
// A voice room subscribes to remote tracks itself (auto-subscribe is off so
// screen shares are opt-in, issue #50), from LiveKit's events. When one of
// those went missing, or a subscription quietly stopped delivering, nothing
// asked again: we never heard that person until they left and rejoined,
// which to everyone else in the room looked like "they can't talk any
// more". Remote video had a stall detector (video_stall_detector.dart);
// remote audio had none.
//
// [RemoteAudioWatch] looks once a second at every remote audio track we
// want: one that never arrives, or a microphone that stays silent (no
// packets at all) while the server says its owner is speaking, is
// subscribed to again, spaced out while it does not help.
import 'dart:math';

import 'package:commet/debug/log.dart';

/// What we can see of one remote audio track at one moment.
class RemoteAudioVitals {
  const RemoteAudioVitals({
    required this.id,
    required this.wanted,
    required this.hasTrack,
    this.muted = false,
    this.speaking = false,
    this.packetsReceived,
    this.isMicrophone = true,
  });

  /// The publication's sid.
  final String id;

  /// We mean to hear it: subscribing to it is wanted and allowed.
  final bool wanted;

  /// The subscription delivered a track.
  final bool hasTrack;

  /// Its owner muted it: nothing is expected.
  final bool muted;

  /// The server hears its owner speaking (active speakers), which it
  /// judges on what the owner sends, whoever receives it.
  final bool speaking;

  /// RTP packets we received for it so far, null when unknown.
  final int? packetsReceived;

  /// Speaking is only a reason to expect packets on a microphone.
  final bool isMicrophone;
}

enum RemoteAudioFault {
  /// Wanted, and no track arrived.
  neverArrived,

  /// Its owner speaks and we receive nothing.
  silent,
}

class RemoteAudioWatch {
  RemoteAudioWatch({DateTime Function()? now}) : _now = now ?? DateTime.now;

  final DateTime Function() _now;

  /// A wanted track still missing after this long is asked for again.
  static const arrivalLimit = Duration(seconds: 6);

  /// Its owner speaking for this long with no packet arriving.
  static const speakingWithoutPackets = Duration(seconds: 3);

  /// Spacing of the repeated attempts for one track.
  static const retryBackoff = [
    Duration(seconds: 5),
    Duration(seconds: 10),
    Duration(seconds: 20),
    Duration(seconds: 40),
    Duration(seconds: 60),
  ];

  final Map<String, _Track> _tracks = {};

  /// Repairs asked for one track since it last worked.
  int attemptsFor(String id) => _tracks[id]?.attempts ?? 0;

  /// Looks at every remote audio track once, and returns those to
  /// subscribe to again, with why.
  Map<String, RemoteAudioFault> check(Iterable<RemoteAudioVitals> tracks) {
    final now = _now();
    final seen = <String>{};
    final repairs = <String, RemoteAudioFault>{};

    for (final v in tracks) {
      seen.add(v.id);
      if (!v.wanted) {
        _tracks.remove(v.id);
        continue;
      }
      final t = _tracks.putIfAbsent(v.id, () => _Track(now));
      final sinceLast = now.difference(t.lastCheck);
      t.lastCheck = now;

      RemoteAudioFault? fault;
      if (!v.hasTrack) {
        t.packets = null;
        t.speakingWithoutPackets = Duration.zero;
        final since = t.missingSince ??= now;
        if (now.difference(since) >= arrivalLimit) {
          fault = RemoteAudioFault.neverArrived;
        }
      } else {
        t.missingSince = null;
        final packets = v.packetsReceived;
        if (packets == null || packets != t.packets) {
          if (packets != null && t.packets != null && t.attempts > 0) {
            Log.i("Voice: remote audio ${v.id} arrives again "
                "(after ${t.attempts} resubscription(s))");
            t.attempts = 0;
            t.nextAt = null;
          }
          t.packets = packets;
          t.speakingWithoutPackets = Duration.zero;
        } else if (v.isMicrophone && v.speaking && !v.muted) {
          t.speakingWithoutPackets += sinceLast;
        }
        if (t.speakingWithoutPackets >= speakingWithoutPackets) {
          fault = RemoteAudioFault.silent;
        }
      }

      if (fault == null) continue;
      final next = t.nextAt;
      if (next != null && now.isBefore(next)) continue;

      t.attempts++;
      t.nextAt =
          now.add(retryBackoff[min(t.attempts, retryBackoff.length) - 1]);
      t.missingSince = null;
      t.speakingWithoutPackets = Duration.zero;
      Log.w("Voice: remote audio ${v.id} ${fault.name}, subscribing to it "
          "again (attempt ${t.attempts})");
      repairs[v.id] = fault;
    }

    _tracks.removeWhere((id, _) => !seen.contains(id));
    return repairs;
  }
}

class _Track {
  _Track(this.lastCheck);

  DateTime lastCheck;
  DateTime? missingSince;
  int? packets;
  Duration speakingWithoutPackets = Duration.zero;
  int attempts = 0;
  DateTime? nextAt;
}
