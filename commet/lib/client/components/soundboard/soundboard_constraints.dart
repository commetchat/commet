// Centralized limits for Soundboard import/playback.
//
// Rationale:
// - Soundboard = short SFX, not music. 15s cap keeps preload/memory sane
//   (15s stereo 48kHz f32 ~= 5.7MB decoded; 1MB encoded is generous for SFX).
// - 1MB encoded cap protects bandwidth/storage/preload on mobile.
// - 3 redirects + 15s timeout + strict allowlist mitigate SSRF/open-redirect.
class SoundboardConstraints {
  static const int maxDurationMs = 15000;
  static const int maxFileBytes = 1024 * 1024; // 1 MiB
  static const int maxRedirects = 3;
  static const Duration httpTimeout = Duration(seconds: 15);

  /// Upper bound of the per-sound admin volume (200 %).
  static const double maxSoundVolume = 2.0;

  static double clampSoundVolume(double volume) =>
      volume.clamp(0.0, maxSoundVolume);

  static const int maxNameLength = 64;
  static const int minNameLength = 1;

  static const List<String> allowedMimeTypes = [
    'audio/mpeg',
    'audio/mp3',
    'audio/ogg',
    'audio/vorbis',
    'audio/opus',
    'audio/wav',
    'audio/x-wav',
    'audio/wave',
    'audio/webm',
    'audio/mp4',
    'audio/aac',
    'audio/flac',
    'audio/x-m4a',
  ];

  static const List<String> allowedExtensions = [
    '.mp3',
    '.ogg',
    '.oga',
    '.opus',
    '.wav',
    '.webm',
    '.m4a',
    '.aac',
    '.flac',
  ];

  /// Hosts explicitly supported for import. No sub-domain wildcards beyond
  /// what is listed; `myinstants.com.attacker.com` must NOT match.
  static const List<String> allowedHosts = [
    'myinstants.com',
    'www.myinstants.com',
  ];

  /// Event TTL: triggers older than this are dropped (reconnect safety).
  static const Duration eventTtl = Duration(milliseconds: 2500);

  /// Max clock skew into the future before an event is considered invalid.
  static const Duration maxFutureSkew = Duration(seconds: 30);

  /// Max entries in dedup LRU (bounded memory).
  static const int maxDedupEntries = 200;

  /// Max decoded sounds held in session LRU.
  static const int maxCachedSounds = 20;

  /// Visual overlay duration bounds (ms). Real duration is clamped into this.
  static const int minOverlayMs = 1200;
  static const int maxOverlayMs = 3500;
}
