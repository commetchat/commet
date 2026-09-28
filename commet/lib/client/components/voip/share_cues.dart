// The sounds a voice room plays when someone starts sharing their screen or
// turns their camera on. Every client plays them for itself when it sees the
// change, so everyone in the room hears them, the one who started included.
//
// Plain logic, fed what is live now: whatever event told the session about
// it (a publish, an unmute, a reconnect that rebuilt everything), only a
// start plays, and only once.

/// Something that has a sound when it starts.
enum ShareCue { screenShare, camera }

class ShareCueTracker {
  ShareCueTracker({DateTime Function()? now}) : _now = now ?? DateTime.now;

  final DateTime Function() _now;

  /// What was live at the last update: `<participant>|<cue>`.
  Set<String> _live = {};
  bool _seeded = false;
  DateTime? _quietUntil;
  final Map<ShareCue, DateTime> _lastPlayed = {};

  /// Shortest gap between two of the same sound: several people starting at
  /// once make one.
  static const minGap = Duration(seconds: 1);

  /// How long after a reconnect nothing plays: LiveKit rebuilds the room and
  /// republishes what was already live, which is no start.
  static const reconnectQuiet = Duration(seconds: 5);

  /// Takes what is live now, as `participant identity -> cues`, and gives the
  /// sounds to play: one per kind that someone started since the last update.
  /// The first update only learns what is there (joining a call where people
  /// already share is no start), and so does any update with [quiet] set or
  /// inside the quiet time after [reconnected].
  List<ShareCue> update(Map<String, Set<ShareCue>> live, {bool quiet = false}) {
    final now = _now();
    final keys = {
      for (final MapEntry(key: who, value: cues) in live.entries)
        for (final cue in cues) '$who|${cue.name}',
    };
    final started = keys.difference(_live);
    _live = keys;
    final silent = !_seeded ||
        quiet ||
        (_quietUntil != null && now.isBefore(_quietUntil!));
    _seeded = true;
    if (silent || started.isEmpty) return const [];

    final cues = <ShareCue>[];
    for (final cue in ShareCue.values) {
      if (!started.any((key) => key.endsWith('|${cue.name}'))) continue;
      final last = _lastPlayed[cue];
      if (last != null && now.difference(last) < minGap) continue;
      _lastPlayed[cue] = now;
      cues.add(cue);
    }
    return cues;
  }

  /// The room was rebuilt after a reconnect: what comes back in the next
  /// moments was already live before.
  void reconnected() => _quietUntil = _now().add(reconnectQuiet);
}
