// The DJ booth's data: the tracks in the queue and the room-wide state the DJ
// broadcasts. Everything here is plain data with a compact JSON form, sent
// over the LiveKit data channel (see dj_protocol.dart), so it has no Flutter
// or Matrix dependency.

/// One song in the queue (or playing).
class DjTrack {
  /// Stable id of this queue entry, so the same song queued twice is two
  /// entries.
  final String id;

  /// How the DJ's client gets the song (see docs/dj-extensions.md): a local
  /// file (`file:<id>`, known only to the DJ who added it), or what a source
  /// extension gave for it (`ext:<extension id>:<its source>`). Clients from
  /// before extensions queued plain links.
  final String source;

  /// The page to open for the song, when it is not [source]. A track with
  /// one keeps the title and artist it was queued with.
  final String? link;

  /// The chip shown with the song: [fileKind], or a label its extension
  /// gave (`Radio`, say). Clients from before extensions sent lowercase
  /// names.
  final String kind;
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

  static const fileKind = 'file';
  static const linkKind = 'link';
  static const filePrefix = 'file:';
  static const extensionPrefix = 'ext:';

  /// Longest [kind] kept.
  static const maxKind = 16;

  /// The page to open for this track, when it has one.
  String? get pageUrl {
    final page = link ?? extensionSource ?? source;
    final uri = Uri.tryParse(page);
    return uri != null && (uri.scheme == 'https' || uri.scheme == 'http')
        ? page
        : null;
  }

  /// A file on the disk of the DJ who added it.
  bool get isLocalFile => source.startsWith(filePrefix);

  /// The extension that fetches this track, for `ext:<id>:<source>`.
  String? get extensionId {
    if (!source.startsWith(extensionPrefix)) return null;
    final end = source.indexOf(':', extensionPrefix.length);
    return end > extensionPrefix.length
        ? source.substring(extensionPrefix.length, end)
        : null;
  }

  /// What the extension gave as the source, for `ext:<id>:<source>`.
  String? get extensionSource {
    final id = extensionId;
    return id == null
        ? null
        : source.substring(extensionPrefix.length + id.length + 1);
  }

  DjTrack copyWith({
    String? id,
    String? source,
    String? title,
    String? artist,
    int? durationMs,
    String? thumbnail,
    bool clearLink = false,
    String? link,
    String? kind,
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
        'k': kind,
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
      kind: djString(json['k'], maxKind) ?? linkKind,
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
