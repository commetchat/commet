// The DJ booth's data: the tracks in the queue and the room-wide state the DJ
// broadcasts. Everything here is plain data with a compact JSON form, sent
// over the LiveKit data channel (see dj_protocol.dart), so it has no Flutter
// or Matrix dependency.

/// Where a track came from. Decides the badge in the queue and how the DJ's
/// client fetches it.
enum DjSource {
  youtube,
  soundcloud,
  spotify,
  other;

  static DjSource fromName(String? name) =>
      DjSource.values.where((s) => s.name == name).firstOrNull ?? other;
}

/// One song in the queue (or playing).
class DjTrack {
  /// Stable id of this queue entry, so the same song queued twice is two
  /// entries.
  final String id;

  /// What the DJ's client hands yt-dlp: the YouTube or SoundCloud link, or a
  /// `ytsearch1:` query for a Spotify track (Spotify audio is DRM protected,
  /// so its songs are played from YouTube).
  final String source;

  /// The link the DJ pasted, when it is not [source] (Spotify).
  final String? link;

  final DjSource kind;
  final String title;
  final String? artist;
  final int? durationMs;
  final String? thumbnail;

  /// Matrix user id of whoever queued it.
  final String addedBy;

  const DjTrack({
    required this.id,
    required this.source,
    required this.kind,
    required this.title,
    required this.addedBy,
    this.link,
    this.artist,
    this.durationMs,
    this.thumbnail,
  });

  /// The page to open for this track.
  String get pageUrl => link ?? source;

  DjTrack copyWith({
    String? id,
    String? source,
    String? title,
    String? artist,
    int? durationMs,
    String? thumbnail,
    bool clearLink = false,
    String? link,
    DjSource? kind,
  }) =>
      DjTrack(
        id: id ?? this.id,
        source: source ?? this.source,
        link: clearLink ? link : (link ?? this.link),
        kind: kind ?? this.kind,
        title: title ?? this.title,
        artist: artist ?? this.artist,
        durationMs: durationMs ?? this.durationMs,
        thumbnail: thumbnail ?? this.thumbnail,
        addedBy: addedBy,
      );

  Map<String, Object?> toJson() => {
        'i': id,
        'u': source,
        if (link != null) 'l': link,
        'k': kind.name,
        't': title,
        if (artist != null) 'a': artist,
        if (durationMs != null) 'd': durationMs,
        if (thumbnail != null) 'th': thumbnail,
        'by': addedBy,
      };

  /// Longest title and artist kept: they travel in every state.
  static const maxText = 200;

  /// Longest link kept.
  static const maxUrl = 1000;

  static DjTrack? fromJson(Object? json) {
    if (json is! Map) return null;
    final id = djString(json['i'], 64);
    final source = djString(json['u'], maxUrl);
    final title = djString(json['t'], maxText);
    if (id == null || source == null || title == null) return null;
    return DjTrack(
      id: id,
      source: source,
      link: djString(json['l'], maxUrl),
      kind: DjSource.fromName(djString(json['k'], 16)),
      title: title,
      artist: djString(json['a'], maxText),
      durationMs: djInt(json['d']),
      thumbnail: djString(json['th'], maxUrl),
      addedBy: djString(json['by'], 256) ?? '',
    );
  }

  @override
  bool operator ==(Object other) =>
      other is DjTrack &&
      other.id == id &&
      other.source == source &&
      other.link == link &&
      other.kind == kind &&
      other.title == title &&
      other.artist == artist &&
      other.durationMs == durationMs &&
      other.thumbnail == thumbnail &&
      other.addedBy == addedBy;

  @override
  int get hashCode => Object.hash(
      id, source, link, kind, title, artist, durationMs, thumbnail, addedBy);

  @override
  String toString() => 'DjTrack($id, $title)';
}

/// The booth as the DJ last announced it.
///
/// [epoch] counts DJ changes: every claim, handoff and release bumps it, so a
/// stale state from a former DJ can be told apart from the current one.
/// [seq] counts the DJ's own updates within an epoch.
class DjSnapshot {
  final int epoch;
  final int seq;

  /// LiveKit identity of the DJ, null while nobody is.
  final String? dj;

  final DjTrack? current;
  final List<DjTrack> queue;

  /// False while paused, and when nothing plays.
  final bool playing;

  /// The DJ is still fetching [current]: the position is not moving.
  final bool buffering;

  /// Position in [current] when this was sent.
  final int positionMs;

  /// Identities who asked to become the DJ, oldest first.
  final List<String> requests;

  /// Identity the DJ is handing the booth to, while it gets ready.
  final String? passTo;

  /// Tells one pass from the next, so a failure or a retry answers the
  /// right one.
  final String? passId;

  const DjSnapshot({
    this.epoch = 0,
    this.seq = 0,
    this.dj,
    this.current,
    this.queue = const [],
    this.playing = false,
    this.buffering = false,
    this.positionMs = 0,
    this.requests = const [],
    this.passTo,
    this.passId,
  });

  static const empty = DjSnapshot();

  DjSnapshot copyWith({
    int? epoch,
    int? seq,
    String? dj,
    bool clearDj = false,
    DjTrack? current,
    bool clearCurrent = false,
    List<DjTrack>? queue,
    bool? playing,
    bool? buffering,
    int? positionMs,
    List<String>? requests,
    String? passTo,
    String? passId,
    bool clearPassTo = false,
  }) =>
      DjSnapshot(
        epoch: epoch ?? this.epoch,
        seq: seq ?? this.seq,
        dj: clearDj ? null : (dj ?? this.dj),
        current: clearCurrent ? null : (current ?? this.current),
        queue: queue ?? this.queue,
        playing: playing ?? this.playing,
        buffering: buffering ?? this.buffering,
        positionMs: positionMs ?? this.positionMs,
        requests: requests ?? this.requests,
        passTo: clearPassTo ? null : (passTo ?? this.passTo),
        passId: clearPassTo ? null : (passId ?? this.passId),
      );

  Map<String, Object?> toJson() => {
        'e': epoch,
        's': seq,
        if (dj != null) 'dj': dj,
        if (current != null) 'c': current!.toJson(),
        'q': [for (final t in queue) t.toJson()],
        'p': playing,
        if (buffering) 'b': true,
        'pos': positionMs,
        if (requests.isNotEmpty) 'r': requests,
        if (passTo != null) 'to': passTo,
        if (passId != null) 'pid': passId,
      };

  static DjSnapshot? fromJson(Object? json) {
    if (json is! Map) return null;
    final epoch = djInt(json['e']);
    final seq = djInt(json['s']);
    if (epoch == null || seq == null) return null;
    final queue = json['q'];
    final requests = json['r'];
    return DjSnapshot(
      epoch: epoch,
      seq: seq,
      dj: djString(json['dj'], 256),
      current: DjTrack.fromJson(json['c']),
      queue: queue is List
          ? [
              for (final t in queue.take(DjSnapshot.maxQueue))
                if (DjTrack.fromJson(t) case final track?) track
            ]
          : const [],
      playing: json['p'] == true,
      buffering: json['b'] == true,
      positionMs: djInt(json['pos']) ?? 0,
      requests: requests is List
          ? [
              for (final r in requests.take(64))
                if (djString(r, 256) case final id?) id
            ]
          : const [],
      passTo: djString(json['to'], 256),
      passId: djString(json['pid'], 64),
    );
  }

  /// Most tracks a queue holds.
  static const maxQueue = 1000;
}

/// [value] when it is a non-empty string, cut to [max] characters.
String? djString(Object? value, int max) {
  if (value is! String || value.isEmpty) return null;
  return value.length > max ? value.substring(0, max) : value;
}

/// [value] as a non-negative int, when it is a finite number.
int? djInt(Object? value) {
  if (value is! num || !value.isFinite || value < 0) return null;
  return value > (1 << 53) ? null : value.toInt();
}

/// What a participant's client can do in the booth, announced by itself.
class DjCaps {
  /// Desktop clients (Linux, Windows) can DJ; web and Android only listen.
  final bool canDj;

  /// `linux`, `windows`, `web`, `android`, ...
  final String platform;

  const DjCaps({required this.canDj, required this.platform});
}

/// Matrix user id of a LiveKit identity (`@user:server:device...`).
String djUserIdOf(String identity) {
  final parts = identity.split(':');
  if (parts.length >= 2) return '${parts[0]}:${parts[1]}';
  return identity;
}
