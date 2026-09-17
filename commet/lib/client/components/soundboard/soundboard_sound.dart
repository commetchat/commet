// Soundboard domain model.
//
// Deep module interface: callers learn SoundboardSound + SoundboardCatalog,
// implementation (Matrix state events, MXC upload, MyInstants import) stays
// behind the seam. See docs/adr decisions inline.
import 'package:commet/client/components/soundboard/soundboard_normalizer.dart';

import 'package:commet/client/components/soundboard/soundboard_constraints.dart';

import 'soundboard_emoji.dart';

/// Stable identifier for a sound effect. Never the display name.
typedef SoundId = String;

/// A single soundboard effect belonging to a Space catalog.
class SoundboardSound {
  /// Stable ID (uuid v4), independent of [name].
  final SoundId soundId;

  /// Display name, sanitized, 1..64 chars.
  final String name;

  /// Unicode emoji (may be ZWJ sequence / flag) or custom Space emoticon.
  final SoundboardEmoji emoji;

  /// Original MyInstants page URL used at import time (for provenance).
  final String? sourceUrl;

  /// Matrix Content Repository URI (mxc://...) after import/normalization.
  /// After import, clients play from this URI — never hotlink MyInstants.
  final String mediaUri;

  /// MIME type of the stored audio (audio/mpeg, audio/ogg, audio/wav, ...).
  final String mimeType;

  /// Duration in milliseconds, validated <= [SoundboardConstraints.maxDurationMs].
  final int durationMs;

  /// Linear gain computed once at import to normalize perceived loudness.
  /// Applied as: output = pcm * normalizedGain * volume * userVolume.
  /// 1.0 means "no correction". Never boosts into clipping.
  final double normalizedGain;

  /// Per-sound volume set by a space admin, 0..[SoundboardConstraints
  /// .maxSoundVolume]. A human fallback for sounds normalization gets wrong;
  /// applies to every listener. 1.0 means "as normalized".
  final double volume;

  /// Schema version for forward-compatible evolution.
  final int version;

  const SoundboardSound({
    required this.soundId,
    required this.name,
    required this.emoji,
    this.sourceUrl,
    required this.mediaUri,
    required this.mimeType,
    required this.durationMs,
    required this.normalizedGain,
    this.volume = 1.0,
    this.version = 1,
  });

  /// Linear gain of this sound before the listener's own volume.
  double get gain => normalizedGain * volume;

  Map<String, dynamic> toJson() => {
        'sound_id': soundId,
        'name': name,
        ...emoji.toJson(),
        if (sourceUrl != null) 'source_url': sourceUrl,
        'media_uri': mediaUri,
        'mimetype': mimeType,
        'duration_ms': durationMs,
        // Event content must be canonical JSON, which has no floats
        // (homeservers answer M_BAD_JSON), so store thousandths.
        'normalized_gain_milli': (normalizedGain * 1000).round(),
        'volume_milli': (volume * 1000).round(),
        'version': version,
      };

  factory SoundboardSound.fromJson(Map<String, dynamic> json) {
    return SoundboardSound(
      soundId: json['sound_id'] as String,
      name: json['name'] as String,
      emoji: SoundboardEmoji.fromJson(json),
      sourceUrl: json['source_url'] as String?,
      mediaUri: json['media_uri'] as String,
      mimeType: (json['mimetype'] as String?) ?? 'audio/mpeg',
      durationMs: (json['duration_ms'] as num).toInt(),
      normalizedGain: _gainFromJson(json),
      volume: _volumeFromJson(json),
      version: (json['version'] as num?)?.toInt() ?? 1,
    );
  }

  /// Held to the normalizer's range: anyone who can send the state event
  /// controls this number, and playback would amplify it as is.
  static double _gainFromJson(Map<String, dynamic> json) {
    final milli = json['normalized_gain_milli'];
    // Float written by earlier builds; only servers not enforcing canonical
    // JSON accepted it.
    final gain = milli is num
        ? milli / 1000
        : (json['normalized_gain'] as num?)?.toDouble() ?? 1.0;
    return gain.clamp(
        SoundboardNormalizer.minGain, SoundboardNormalizer.maxGain);
  }

  static double _volumeFromJson(Map<String, dynamic> json) {
    final milli = json['volume_milli'];
    // Absent in sounds from earlier builds; ignore junk instead of throwing,
    // since one bad event must not hide the whole catalog.
    if (milli is! num) return 1.0;
    return SoundboardConstraints.clampSoundVolume(milli / 1000);
  }

  SoundboardSound copyWith({
    String? name,
    SoundboardEmoji? emoji,
    String? mediaUri,
    String? mimeType,
    int? durationMs,
    double? normalizedGain,
    double? volume,
  }) {
    return SoundboardSound(
      soundId: soundId,
      name: name ?? this.name,
      emoji: emoji ?? this.emoji,
      sourceUrl: sourceUrl,
      mediaUri: mediaUri ?? this.mediaUri,
      mimeType: mimeType ?? this.mimeType,
      durationMs: durationMs ?? this.durationMs,
      normalizedGain: normalizedGain ?? this.normalizedGain,
      volume: volume ?? this.volume,
      version: version,
    );
  }
}
