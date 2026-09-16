// Soundboard domain model.
//
// Deep module interface: callers learn SoundboardSound + SoundboardCatalog,
// implementation (Matrix state events, MXC upload, MyInstants import) stays
// behind the seam. See docs/adr decisions inline.

/// Stable identifier for a sound effect. Never the display name.
typedef SoundId = String;

/// A single soundboard effect belonging to a Space catalog.
class SoundboardSound {
  /// Stable ID (uuid v4), independent of [name].
  final SoundId soundId;

  /// Display name, sanitized, 1..64 chars.
  final String name;

  /// Single grapheme-cluster-ish emoji (may be ZWJ sequence / flag).
  final String emoji;

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
  /// Applied as: output = pcm * normalizedGain * userVolume.
  /// 1.0 means "no correction". Never boosts into clipping.
  final double normalizedGain;

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
    this.version = 1,
  });

  Map<String, dynamic> toJson() => {
        'sound_id': soundId,
        'name': name,
        'emoji': emoji,
        if (sourceUrl != null) 'source_url': sourceUrl,
        'media_uri': mediaUri,
        'mimetype': mimeType,
        'duration_ms': durationMs,
        // Event content must be canonical JSON, which has no floats
        // (homeservers answer M_BAD_JSON), so store thousandths.
        'normalized_gain_milli': (normalizedGain * 1000).round(),
        'version': version,
      };

  factory SoundboardSound.fromJson(Map<String, dynamic> json) {
    return SoundboardSound(
      soundId: json['sound_id'] as String,
      name: json['name'] as String,
      emoji: json['emoji'] as String,
      sourceUrl: json['source_url'] as String?,
      mediaUri: json['media_uri'] as String,
      mimeType: (json['mimetype'] as String?) ?? 'audio/mpeg',
      durationMs: (json['duration_ms'] as num).toInt(),
      normalizedGain: _gainFromJson(json),
      version: (json['version'] as num?)?.toInt() ?? 1,
    );
  }

  static double _gainFromJson(Map<String, dynamic> json) {
    final milli = json['normalized_gain_milli'];
    if (milli is num) return milli / 1000;
    // Float written by earlier builds; only servers not enforcing canonical
    // JSON accepted it.
    return (json['normalized_gain'] as num?)?.toDouble() ?? 1.0;
  }

  SoundboardSound copyWith({
    String? name,
    String? emoji,
    String? mediaUri,
    String? mimeType,
    int? durationMs,
    double? normalizedGain,
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
      version: version,
    );
  }
}
