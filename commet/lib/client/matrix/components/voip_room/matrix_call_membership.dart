// Our call membership content (org.matrix.msc3401.call.member) beyond what the
// MatrixRTC proposals define: which streams a member publishes and whether
// they have silenced themselves, so the voice channel list can show who is
// live, muted or deafened to people outside the call (issue #9).
// Pure Dart. See docs/research/issue-9-live-badge-voice-list.md.
import 'package:commet/client/components/activities/activities_component.dart';

class MatrixCallMembership {
  /// Lists what the member publishes, e.g. `["screen", "camera"]`. Other
  /// clients ignore keys they don't know.
  static const liveMediaKey = 'chat.commet.streams';

  /// Lists how the member has silenced themselves, e.g. `["muted"]` or
  /// `["muted", "deafened"]`. An absent key means the member's client does
  /// not report it, which is not the same as being unmuted.
  static const voiceStateKey = 'chat.commet.voice_state';

  /// How long a membership lasts from its join time, the MatrixRTC default.
  static const lifetime = Duration(hours: 4);

  /// What [content] reports the member publishing. Unknown values and
  /// malformed content are ignored.
  static Set<LiveMedia> liveMediaOf(Map<String, Object?> content) {
    final value = content[liveMediaKey];
    if (value is! List) return const {};
    return {
      for (final media in LiveMedia.values)
        if (value.contains(media.name)) media,
    };
  }

  /// How [content] reports the member having silenced themselves. Unknown
  /// values and malformed content are ignored, and `deafened` on its own is
  /// read as muted too, since deafening turns the microphone off.
  static Set<VoiceState> voiceStateOf(Map<String, Object?> content) {
    final value = content[voiceStateKey];
    if (value is! List) return const {};
    final state = {
      for (final flag in VoiceState.values)
        if (value.contains(flag.name)) flag,
    };
    if (state.contains(VoiceState.deafened)) state.add(VoiceState.muted);
    return state;
  }

  /// When the member joined: `created_ts` once the membership has been
  /// rewritten, otherwise when it was sent ([sentAt]).
  static DateTime? joinedAt(Map<String, Object?> content, DateTime? sentAt) {
    final created = content['created_ts'];
    if (created is int) return DateTime.fromMillisecondsSinceEpoch(created);
    return sentAt;
  }

  /// Whether the membership's `expires` window, counted from its join time
  /// like MatrixRTC clients do, has passed at [now]. Stripped state carries
  /// no [sentAt] and is assumed live.
  static bool isExpired(
      Map<String, Object?> content, DateTime? sentAt, DateTime now) {
    final expires = content['expires'];
    if (expires is! int || sentAt == null) return false;
    final joined = joinedAt(content, sentAt)!;
    return now.isAfter(joined.add(Duration(milliseconds: expires)));
  }

  /// [current] rewritten to list [media] and [voiceState]. Every other key is
  /// kept, the join time is recorded in `created_ts` (without it other
  /// clients take the rewrite for a new join, re-key, and reorder the
  /// oldest_membership focus choice), and the expiry moves [lifetime] past
  /// [now].
  static Map<String, Object?> withPublishedState(Map<String, Object?> current,
      {required Set<LiveMedia> media,
      required Set<VoiceState> voiceState,
      required DateTime joinedAt,
      required DateTime now}) {
    return {
      ...current,
      'created_ts': joinedAt.millisecondsSinceEpoch,
      'expires':
          now.difference(joinedAt).inMilliseconds + lifetime.inMilliseconds,
      liveMediaKey: [
        for (final m in LiveMedia.values)
          if (media.contains(m)) m.name,
      ],
      voiceStateKey: [
        for (final flag in VoiceState.values)
          if (voiceState.contains(flag)) flag.name,
      ],
    };
  }
}
