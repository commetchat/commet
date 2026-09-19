// The DJ booth of one call: who the DJ is, what plays, what is queued, who
// asked for the booth. One instance per joined call, on every client.
//
// Authority: the DJ's client owns the booth. It changes the queue and
// playback locally and broadcasts the whole state (`state`) plus its
// position every few seconds (`tick`). Everyone else only displays it, and
// sends requests (`req`).
//
// Who is the DJ is decided by an epoch that every change of DJ bumps. The
// rule every client applies is the same, so they all end up agreeing:
// - A state names its sender as the DJ, or names nobody (an empty booth).
// - A higher epoch wins. Between two DJs at the same epoch (two claims at
//   once), the smaller LiveKit identity wins. Within an epoch, a lower `seq`
//   is an older state.
// - A client that sees someone else win stops its own music.
// - Someone sending a state that loses is sent ours back, so a newcomer that
//   claimed without knowing the booth learns and steps down.
//
// How the epoch moves:
// - Claim: with the booth empty, a desktop client announces itself with the
//   next epoch, carrying on with the queue where it stopped.
// - Pass: the DJ names a target. The target fetches the playing track while
//   the DJ keeps playing, loads it at the live position, then announces
//   itself with the next epoch; the old DJ stops when it sees that. Queue,
//   position and pause carry over.
// - Release or leave: the booth empties, keeping queue and position,
//   paused. Anyone who knows an empty booth tells newcomers about it.
//
// None of this is a security boundary: anyone in the call can send anything
// on the data channel. It keeps honest clients consistent.
import 'dart:async';
import 'dart:math';

import 'package:collection/collection.dart';
import 'package:commet/client/components/dj/dj_engine.dart';
import 'package:commet/client/components/dj/dj_links.dart';
import 'package:commet/client/components/dj/dj_models.dart';
import 'package:commet/client/components/dj/dj_protocol.dart';
import 'package:flutter/foundation.dart';

enum DjRole {
  listener,

  /// Claiming the empty booth, or taking over a pass: the engine starts and
  /// the playing track is fetched.
  joining,
  dj,
}

typedef DjEngineFactory = DjPlaybackEngine Function();

class DjSession extends ChangeNotifier {
  final DjTransport transport;

  /// What this client can do. [DjCaps.canDj] needs [engineFactory].
  final DjCaps caps;
  final DjEngineFactory? engineFactory;
  final DjResolver? resolver;

  /// Gets this client ready to DJ (the tools it needs, the user's consent to
  /// download them); false when it can't. Asked before claiming, requesting
  /// and taking over.
  final Future<bool> Function()? prepareToDj;

  /// Asks the user whether to take the decks [fromIdentity] is handing them,
  /// when they didn't ask for them. No function: taken without asking.
  final Future<bool> Function(String fromIdentity)? acceptPass;

  /// Matrix user id of this client's user, recorded on what they queue.
  final String selfUserId;

  final DateTime Function() _now;
  final String Function() _newId;

  final Duration tickInterval;
  final Duration pollInterval;
  final Duration passTimeout;

  /// Most tracks the queue holds.
  static const maxQueue = DjSnapshot.maxQueue;

  /// How many upcoming tracks the DJ fetches ahead.
  static const prefetchAhead = 2;

  /// Songs failing in a row before the booth stops trying the next one.
  static const maxFailuresInARow = 3;

  /// How long a new DJ waits before its music starts: the old DJ's music
  /// has to stop first (a data message, then a short fade).
  static const handoffLead = Duration(milliseconds: 250);

  /// A DJ that has said nothing for this long (no tick, no state) is taken
  /// to be gone, even if LiveKit still lists them: a frozen app, or a
  /// client that lost a claim and never learned it.
  static const djSilenceLimit = Duration(seconds: 10);

  /// How often a pass target tells the DJ it is still getting ready.
  static const passKeepAlive = Duration(seconds: 20);

  DjSession({
    required this.transport,
    required this.caps,
    required this.selfUserId,
    this.engineFactory,
    this.resolver,
    this.prepareToDj,
    this.acceptPass,
    DateTime Function()? now,
    String Function()? newId,
    this.tickInterval = const Duration(seconds: 2),
    this.pollInterval = const Duration(milliseconds: 250),
    this.passTimeout = const Duration(seconds: 90),
  })  : _now = now ?? DateTime.now,
        _newId = newId ?? _randomId;

  static final Random _random = Random();
  static String _randomId() =>
      List.generate(3, (_) => _random.nextInt(1 << 30).toRadixString(36))
          .join();

  String get selfIdentity => transport.selfIdentity;

  // ---------------------------------------------------------------------
  // State

  DjSnapshot _snap = DjSnapshot.empty;

  /// Position in [_snap.current] at [_baseAt], as last announced.
  int _basePos = 0;
  DateTime _baseAt = DateTime.fromMillisecondsSinceEpoch(0);

  final Map<String, DjCaps> _caps = {};

  DjRole _role = DjRole.listener;
  DjPlaybackEngine? _engine;

  /// The DJ's pause, which the engine follows once the track is loaded.
  bool _paused = false;

  /// Bumped whenever the DJ starts something else, so a fetch that finishes
  /// late knows it was overtaken.
  int _playGen = 0;
  bool _loading = false;
  int _failuresInARow = 0;

  /// The pass we are taking over, and passes we already tried.
  String? _takingPass;
  final Set<String> _triedPasses = {};

  final List<DjPendingAdd> _pendingAdds = [];
  final StreamController<DjNotice> _notices = StreamController.broadcast();
  final DjPartAssembler _assembler = DjPartAssembler();

  final List<StreamSubscription> _subs = [];
  Timer? _tickTimer;
  Timer? _pollTimer;
  Timer? _passTimer;
  Timer? _syncRetry;
  bool _gotState = false;
  bool _disposed = false;

  /// Every message goes out after the previous one, parts included, so the
  /// room receives our states in the order we made them.
  Future<void> _outbox = Future.value();

  DjSnapshot get snapshot => _snap;
  DjRole get role => _role;
  bool get isDj => _role == DjRole.dj;
  bool get isJoining => _role == DjRole.joining;
  bool get isDisposed => _disposed;
  String? get djIdentity => _snap.dj;
  String? get djUserId => _snap.dj == null ? null : djUserIdOf(_snap.dj!);
  DjTrack? get current => _snap.current;
  List<DjTrack> get queue => _snap.queue;
  bool get isPlaying => _snap.playing && _snap.current != null;
  bool get isBuffering => _snap.buffering || (isDj && _loading);
  String? get passTarget => _snap.passTo;
  List<String> get requests => _snap.requests;
  List<DjPendingAdd> get pendingAdds => List.unmodifiable(_pendingAdds);
  Stream<DjNotice> get notices => _notices.stream;

  /// Whether the booth is free to claim: nobody is the DJ, or the DJ is gone
  /// (left, or silent for [djSilenceLimit]).
  bool get isVacant {
    final dj = _snap.dj;
    if (dj == null) return true;
    if (dj == selfIdentity) return false;
    return !transport.isPresent(dj) || _djSilent;
  }

  bool get _djSilent =>
      _now().difference(_lastHeardFromDj) > djSilenceLimit;

  /// When the DJ last said anything (a state or a tick).
  DateTime _lastHeardFromDj = DateTime.fromMillisecondsSinceEpoch(0);

  /// When we last answered each sender's losing state: at most once every
  /// few seconds, so no disagreement can turn into a message storm.
  final Map<String, DateTime> _answered = {};

  /// Redraws listeners when the DJ falls silent (the booth becomes free).
  Timer? _silenceTimer;
  bool _wasVacant = true;

  bool get hasRequested => _snap.requests.contains(selfIdentity);

  /// What [identity] announced about their client; null until they did.
  DjCaps? capsOf(String identity) =>
      identity == selfIdentity ? caps : _caps[identity];

  bool isDjUser(String userId) => djUserId == userId;

  bool hasRequestedUser(String userId) =>
      _snap.requests.any((r) => djUserIdOf(r) == userId);

  /// The call identities (devices) of [userId] the booth has heard of and
  /// that are in the call.
  List<String> identitiesOf(String userId) => {
        selfIdentity,
        ..._caps.keys,
        if (_snap.dj != null) _snap.dj!,
        ..._snap.requests,
      }
          .where((i) => djUserIdOf(i) == userId && transport.isPresent(i))
          .toList();

  /// Which of [userId]'s devices the booth can be passed to: the one that
  /// asked, else any that can DJ. Null when none can.
  String? passCandidateFor(String userId) {
    final candidates = identitiesOf(userId)
        .where((i) => i != selfIdentity && capsOf(i)?.canDj == true)
        .toList();
    return candidates.firstWhereOrNull(_snap.requests.contains) ??
        candidates.firstOrNull;
  }

  /// What [userId] is listening on, when they said (`web`, `android`, ...).
  String? platformOf(String userId) => identitiesOf(userId)
      .map((i) => capsOf(i)?.platform)
      .whereType<String>()
      .firstOrNull;

  /// Where the playing track is now, estimated from the last announcement
  /// on listeners.
  int get positionMs {
    final engine = _engine;
    if (isDj && engine != null) {
      final status = engine.status;
      if (!_loading && status.trackId == _snap.current?.id) {
        return status.positionMs;
      }
      return _basePos;
    }
    if (!_snap.playing || _snap.buffering || _snap.current == null) {
      return _basePos;
    }
    final elapsed = _now().difference(_baseAt).inMilliseconds;
    final estimate = _basePos + (elapsed > 0 ? elapsed : 0);
    final duration = _snap.current?.durationMs;
    return duration != null && duration > 0 && estimate > duration
        ? duration
        : estimate;
  }

  /// Length of the playing track: from the engine on the DJ (it knows the
  /// real file), from the track otherwise.
  int? get durationMs {
    final engine = _engine;
    if (isDj && engine != null && !_loading) {
      final status = engine.status;
      if (status.trackId == _snap.current?.id && status.durationMs > 0) {
        return status.durationMs;
      }
    }
    return _snap.current?.durationMs;
  }

  // ---------------------------------------------------------------------
  // Lifecycle

  void start() {
    _subs.add(transport.incoming.listen(_onIncoming));
    _subs.add(transport.participantLeft.listen(_onParticipantLeft));
    _subs.add(transport.participantJoined.listen(_onParticipantJoined));
    _subs.add(transport.reconnected.listen((_) => _onReconnected()));
    _hello();
    // A newcomer's first messages can go out before the room hears it.
    _syncRetry = Timer(const Duration(seconds: 3), () {
      if (_gotState || _disposed) return;
      _hello();
    });
    _silenceTimer = Timer.periodic(const Duration(seconds: 2), (_) {
      final vacant = isVacant;
      if (vacant != _wasVacant) {
        _wasVacant = vacant;
        _notify();
      }
    });
  }

  void _hello() {
    _sendCaps();
    _send({'t': 'sync'});
  }

  void _sendCaps({List<String>? to}) =>
      _send({'t': 'caps', 'dj': caps.canDj, 'p': caps.platform}, to: to);

  @override
  Future<void> dispose() async {
    if (_disposed) return;
    _disposed = true;
    // Everything that could act later stops first.
    _stopTimers();
    _syncRetry?.cancel();
    _silenceTimer?.cancel();
    _playGen++;
    final engine = _engine;
    final wasDj = _snap.dj == selfIdentity;
    final position = positionMs;
    _engine = null;
    _role = DjRole.listener;

    // Leaving as the DJ: hand the room an empty booth right away instead of
    // making it wait for LiveKit to notice we left. Not while handing the
    // decks over ("here, take over" and hang up): the target finishes the
    // pass once LiveKit says we left, and the music carries on.
    if (wasDj && _snap.passTo == null) {
      _snap = _snap.copyWith(
          epoch: _snap.epoch + 1,
          seq: 0,
          clearDj: true,
          playing: false,
          buffering: false,
          positionMs: position,
          requests: const [],
          clearPassTo: true);
      _basePos = position;
      await _sendState().timeout(const Duration(seconds: 2), onTimeout: () {});
    }
    for (final sub in _subs) {
      await sub.cancel();
    }
    await engine?.shutdown().catchError((_) {});
    await _notices.close();
    super.dispose();
  }

  void _stopTimers() {
    _tickTimer?.cancel();
    _tickTimer = null;
    _pollTimer?.cancel();
    _pollTimer = null;
    _passTimer?.cancel();
    _passTimer = null;
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  void _notice(String message, {bool isError = false}) {
    if (!_notices.isClosed) {
      _notices.add(DjNotice(message, isError: isError));
    }
  }

  Future<void> _send(Map<String, Object?> message, {List<String>? to}) {
    final sent = _outbox.then((_) => transport.send(message, to: to)).then(
        (_) {}, onError: (_) {
      // The data channel reports its own failures; the booth carries on and
      // the next state or tick repairs what was lost.
    });
    _outbox = sent;
    return sent;
  }

  // ---------------------------------------------------------------------
  // Incoming

  void _onIncoming(DjIncoming incoming) {
    if (_disposed) return;
    var message = incoming.message;
    if (message['t'] == 'part') {
      final whole = _assembler.add(incoming.sender, message, now: _now());
      if (whole == null) return;
      message = whole;
    }
    final sender = incoming.sender;
    if (sender == selfIdentity) return;
    switch (message['t']) {
      case 'caps':
        _caps[sender] = DjCaps(
            canDj: message['dj'] == true,
            platform: djString(message['p'], 32) ?? '');
        _notify();
      case 'sync':
        _onSync(sender);
      case 'state':
        final snap = DjSnapshot.fromJson(message);
        if (snap != null) _onState(sender, snap);
      case 'tick':
        _onTick(sender, message);
      case 'req':
        _onRequest(sender, message['on'] == true);
      case 'pfail':
        _onPassFailed(sender, message);
      case 'pwait':
        _onPassWait(sender, message);
    }
  }

  /// The pass target is still getting ready (the consent prompt, the
  /// downloads): its time starts over.
  void _onPassWait(String sender, Map<String, Object?> message) {
    if (!isDj || _snap.passTo != sender) return;
    if (message['pid'] != _snap.passId) return;
    _startPassTimer(_snap.passId!);
  }

  void _onSync(String sender) {
    _sendCaps(to: [sender]);
    if (isDj) {
      _sendState(to: [sender]);
    } else if (_snap.dj == null && _snap.epoch > 0 && _role == DjRole.listener) {
      // An empty booth has nobody to speak for it: whoever knows it does,
      // so a newcomer claims with the right epoch and the kept queue.
      _sendState(to: [sender]);
    }
  }

  /// Whether [snap], sent by [sender], replaces what we know.
  bool _accepts(String sender, DjSnapshot snap) {
    // A state names its sender as the DJ, or nobody.
    if (snap.dj != null && snap.dj != sender) return false;
    final known = _snap;
    if (snap.epoch > known.epoch) return true;
    if (snap.epoch < known.epoch) return false;

    // Same epoch.
    if (snap.dj == null) return known.dj == null;
    if (known.dj == sender) return snap.seq >= known.seq;
    // A DJ beats an empty booth: releases bump the epoch, so an empty booth
    // at the same epoch only means LiveKit said the DJ left (a reconnect).
    // A claim that lost and still echoes goes quiet and is then taken for
    // gone ([djSilenceLimit]).
    if (known.dj == null) return true;
    // Two claims of the same empty booth: the smaller identity wins.
    return sender.compareTo(known.dj!) < 0;
  }

  void _onState(String sender, DjSnapshot snap) {
    if (!_accepts(sender, snap)) {
      _answerLoser(sender, snap);
      return;
    }
    _gotState = true;
    _snap = snap;
    _basePos = snap.positionMs;
    _baseAt = _now();
    if (snap.dj != null) _lastHeardFromDj = _now();

    // Someone else is the DJ now (a pass landed, we lost a claim), unless
    // this is the DJ still naming us as the pass we are taking.
    if (_role != DjRole.listener && snap.dj != selfIdentity) {
      final stillOurPass = _role == DjRole.joining &&
          _takingPass != null &&
          snap.passTo == selfIdentity &&
          snap.passId == _takingPass;
      if (!stillOurPass) _stepDown();
    }

    final passId = snap.passId;
    if (snap.passTo == selfIdentity &&
        passId != null &&
        snap.dj != null &&
        _role == DjRole.listener &&
        _triedPasses.add(passId)) {
      if (_canBecomeDj) {
        _takeOver(passId);
      } else {
        _send({
          't': 'pfail',
          'e': snap.epoch,
          'pid': passId,
          'why': "their app can't DJ",
        }, to: [snap.dj!]);
      }
    }
    _notify();
  }

  /// [sender] sent a state that lost to ours: tell them, so a claim made
  /// without knowing the booth ends. Only the DJ answers for a booth that
  /// has one, and only listeners for an empty one.
  void _answerLoser(String sender, DjSnapshot theirs) {
    if (theirs.epoch == _snap.epoch && theirs.dj == _snap.dj) {
      return; // an older state of the same DJ
    }
    // Only when ours wins at their end too, so an answer can't be rejected
    // and answered in turn.
    final bool oursWins;
    if (isDj) {
      oursWins = _snap.epoch > theirs.epoch ||
          (_snap.epoch == theirs.epoch &&
              (theirs.dj == null || selfIdentity.compareTo(theirs.dj!) < 0));
    } else if (_snap.dj == null && _role == DjRole.listener) {
      oursWins = _snap.epoch > theirs.epoch;
    } else {
      oursWins = false;
    }
    if (oursWins && _mayAnswer(sender)) _sendState(to: [sender]);
  }

  /// At most one answer (a state, a sync) to each sender every few seconds.
  bool _mayAnswer(String sender) {
    final now = _now();
    final last = _answered[sender];
    if (last != null && now.difference(last) < const Duration(seconds: 3)) {
      return false;
    }
    _answered[sender] = now;
    if (_answered.length > 256) _answered.remove(_answered.keys.first);
    return true;
  }

  void _onTick(String sender, Map<String, Object?> message) {
    final epoch = djInt(message['e']);
    if (epoch == null) return;
    if (epoch > _snap.epoch) {
      // Someone is DJ at an epoch we never heard of: we missed states.
      if (_mayAnswer(sender)) _send({'t': 'sync'}, to: [sender]);
      return;
    }
    if (isDj) {
      // Another DJ: both of us resolve it from each other's state.
      if (sender != selfIdentity && _mayAnswer(sender)) {
        _sendState(to: [sender]);
      }
      return;
    }
    if (epoch == _snap.epoch && sender != _snap.dj) {
      // A DJ we don't know of at our epoch: we missed their return (a
      // reconnect). Ask; their state beats the empty booth we hold.
      if (_mayAnswer(sender)) _send({'t': 'sync'}, to: [sender]);
      return;
    }
    if (sender != _snap.dj || epoch != _snap.epoch) return;
    _lastHeardFromDj = _now();
    if (message['c'] != _snap.current?.id) return;
    final pos = djInt(message['pos']);
    if (pos == null) return;
    _basePos = pos;
    _baseAt = _now();
    final playing = message['p'] == true;
    final buffering = message['b'] == true;
    if (playing != _snap.playing || buffering != _snap.buffering) {
      _snap = _snap.copyWith(playing: playing, buffering: buffering);
      _notify();
    }
  }

  void _onRequest(String sender, bool on) {
    if (!isDj) return;
    // Only a client that can DJ asks; its caps may not have reached us.
    if (on && _caps[sender]?.canDj != true) {
      _caps[sender] =
          DjCaps(canDj: true, platform: _caps[sender]?.platform ?? '');
    }
    final has = _snap.requests.contains(sender);
    if (on == has) return;
    if (on && _snap.requests.length >= 64) return;
    _snap = _snap.copyWith(
        requests: on
            ? [..._snap.requests, sender]
            : _snap.requests.where((r) => r != sender).toList());
    _sendState();
    _notify();
  }

  void _onPassFailed(String sender, Map<String, Object?> message) {
    if (!isDj || _snap.passTo != sender) return;
    if (message['pid'] != _snap.passId) return;
    _passTimer?.cancel();
    _snap = _snap.copyWith(clearPassTo: true);
    _sendState();
    final why = djString(message['why'], 200);
    _notice("Couldn't hand the booth over${why != null ? ': $why' : ''}",
        isError: true);
    _notify();
  }

  void _onParticipantJoined(String identity) {
    // The newcomer asks with `sync` once it can hear us; answering here too
    // covers a sync that went out before its channel was open.
    if (isDj) _sendState(to: [identity]);
  }

  void _onReconnected() {
    if (_disposed) return;
    // Whatever was said while we were away may be lost, and LiveKit made
    // everyone leave and come back without telling us they came back.
    _hello();
    if (isDj) _sendState();
  }

  void _onParticipantLeft(String identity) {
    // Their caps are kept: a reconnect makes everyone "leave" and come back
    // without announcing it, and they don't send them again.
    var changed = false;
    if (_snap.requests.contains(identity)) {
      _snap = _snap.copyWith(
          requests: _snap.requests.where((r) => r != identity).toList());
      changed = true;
    }
    if (identity == _snap.dj && identity != selfIdentity) {
      // The music stopped with them. Keep the queue and where it was, paused,
      // for whoever takes the booth next.
      _basePos = positionMs;
      _baseAt = _now();
      _snap = _snap.copyWith(
          clearDj: true,
          playing: false,
          buffering: false,
          positionMs: _basePos,
          // Nobody left to ask: a raised hand would stay up for good.
          requests: const [],
          // A pass in progress may still complete: its target announces the
          // next epoch.
          clearPassTo: _takingPass == null);
      changed = true;
    }
    if (isDj && identity == _snap.passTo) {
      _passTimer?.cancel();
      _snap = _snap.copyWith(clearPassTo: true);
      _notice("The booth wasn't handed over: they left the call");
      changed = true;
    }
    if (changed) {
      if (isDj) _sendState();
      _notify();
    }
  }

  // ---------------------------------------------------------------------
  // Becoming the DJ

  bool get _canBecomeDj => caps.canDj && engineFactory != null;

  Future<bool> _prepare() async {
    final prepare = prepareToDj;
    if (prepare == null) return true;
    try {
      return await prepare();
    } catch (e) {
      _notice("Couldn't get ready to DJ: $e", isError: true);
      return false;
    }
  }

  /// Takes the empty booth, carrying on with its queue from where it
  /// stopped, paused.
  Future<void> becomeDj() async {
    if (!_canBecomeDj || _role != DjRole.listener || !isVacant) return;
    if (!await _prepare()) return;
    // The booth may have been taken while the user decided.
    if (_disposed || _role != DjRole.listener || !isVacant) return;
    final engine = engineFactory!();
    _engine = engine;
    _role = DjRole.joining;
    _paused = true;
    _failuresInARow = 0;
    final position = positionMs;
    _snap = _snap.copyWith(
      epoch: _snap.epoch + 1,
      seq: 0,
      dj: selfIdentity,
      playing: false,
      buffering: false,
      positionMs: position,
      requests: _snap.requests.where((r) => r != selfIdentity).toList(),
      clearPassTo: true,
    );
    _basePos = position;
    _baseAt = _now();
    // Claim first, so a competing claim is settled before we publish.
    _sendState();
    _notify();

    try {
      await engine.start();
    } catch (e) {
      if (_engine != engine) return;
      _notice("Couldn't start the DJ booth: $e", isError: true);
      await _release();
      return;
    }
    // Lost to a competing claim, or left, while starting.
    if (_disposed || _engine != engine || _snap.dj != selfIdentity) return;
    _becameDj();
    if (_snap.current != null) _startCurrent(positionMs: position);
  }

  /// The DJ handed us the booth: fetch the playing track while they keep
  /// playing, load it at the live position, then announce ourselves.
  Future<void> _takeOver(String passId) async {
    final engine = engineFactory?.call();
    if (engine == null) return;
    final from = _snap.dj;
    final epoch = _snap.epoch;
    _engine = engine;
    _role = DjRole.joining;
    _takingPass = passId;
    _notify();

    // Still ours: nothing replaced the pass (a cancel, another target, a
    // release, another DJ). The DJ leaving mid-pass doesn't end it.
    bool stillOurs() =>
        !_disposed &&
        _engine == engine &&
        _snap.epoch == epoch &&
        (_snap.dj == null ||
            (_snap.passTo == selfIdentity && _snap.passId == passId));

    // Tell the DJ we are still at it: the consent prompt and the downloads
    // can take longer than the pass timeout.
    final keepAlive = from == null
        ? null
        : Timer.periodic(passKeepAlive, (_) {
            if (_engine == engine && isJoining) {
              _send({'t': 'pwait', 'pid': passId}, to: [from]);
            }
          });

    void decline(String why) {
      if (from != null) {
        _send({'t': 'pfail', 'e': epoch, 'pid': passId, 'why': why},
            to: [from]);
      }
    }

    var agreed = false;
    Future<void> calledOff() async {
      if (agreed && !_disposed) {
        _notice('The handoff was called off; ${_nameOf(from)} keeps the decks');
      }
      await _abandon(engine);
    }

    String? failure;
    try {
      // Someone who asked for the decks takes them; anyone else is asked.
      final asked = _snap.requests.contains(selfIdentity);
      final accept = acceptPass;
      if (!asked && accept != null && !await accept(from ?? '')) {
        decline('they said no');
        return await _abandon(engine);
      }
      if (!stillOurs()) return await calledOff();
      agreed = true;
      if (!await _prepare()) {
        decline("they aren't set up to DJ");
        return await _abandon(engine);
      }
      if (!stillOurs()) return await calledOff();
      await engine.start();

      // Fetch until the track we hold is still the one playing: it may end
      // while we download.
      DjTrack? fetched;
      DjTrackInfo? info;
      for (var attempt = 0; attempt < 3; attempt++) {
        final track = _snap.current;
        if (track == null || !stillOurs()) break;
        info = await engine.prepare(track);
        fetched = track;
        if (_snap.current?.id == track.id) break;
      }
      if (!stillOurs()) return await calledOff();

      // From here to the announcement nothing awaits, so nothing can change
      // the booth under us.
      final track = _snap.current;
      final playing = _snap.playing && _snap.dj != null;
      // Loaded paused a moment ahead, and started once the old DJ has
      // heard us and faded out: the room never hears both copies.
      final lead = playing ? handoffLead.inMilliseconds : 0;
      final position = positionMs + lead;
      if (track != null) {
        if (fetched?.id != track.id) {
          throw StateError('the song kept changing while it downloaded');
        }
        engine.load(track, positionMs: position, paused: true);
      }
      _paused = !playing;
      _failuresInARow = 0;
      _snap = _snap.copyWith(
        epoch: epoch + 1,
        seq: 0,
        dj: selfIdentity,
        clearPassTo: true,
        requests: _snap.requests.where((r) => r != selfIdentity).toList(),
        playing: playing,
        buffering: false,
        positionMs: position,
      );
      if (track != null && info != null) _mergeInfo(track.id, info);
      _basePos = position;
      _baseAt = _now();
      _takingPass = null;
      _becameDj();
      _notice("You're on the decks");
      // Counted from when the announcement is out, however many parts a
      // long queue takes: the old DJ stops when it has it.
      final announced = _sendState();
      if (track != null && playing) {
        announced.then((_) => Timer(handoffLead, () {
              if (_engine == engine && isDj && !_paused) {
                engine.setPaused(false);
              }
            }));
      }
      _prefetch();
    } catch (e) {
      failure = e.toString().replaceFirst('Bad state: ', '');
    } finally {
      keepAlive?.cancel();
    }
    if (failure != null && _engine == engine) {
      decline(failure);
      _notice("Couldn't take over the decks: $failure", isError: true);
      await _abandon(engine);
    }
  }

  String _nameOf(String? identity) =>
      identity == null ? 'the DJ' : djUserIdOf(identity);

  Future<void> _abandon(DjPlaybackEngine engine) async {
    if (_engine == engine) {
      _engine = null;
      _role = DjRole.listener;
      _takingPass = null;
      _notify();
    }
    await engine.shutdown().catchError((_) {});
  }

  void _becameDj() {
    _role = DjRole.dj;
    _lastEngineState = null;
    _tickTimer?.cancel();
    _tickTimer = Timer.periodic(tickInterval, (_) => _sendTick());
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(pollInterval, (_) => _poll());
    _notify();
  }

  /// Someone else is the DJ: stop our music right away.
  void _stepDown() {
    final engine = _engine;
    _engine = null;
    _role = DjRole.listener;
    _takingPass = null;
    _loading = false;
    _playGen++;
    _stopTimers();
    engine?.shutdown().catchError((_) {});
  }

  // ---------------------------------------------------------------------
  // Listener actions

  /// Asks the DJ for the booth, or stops asking. Getting ready first means a
  /// pass to us works right away.
  Future<void> requestDj(bool on) async {
    if (!_canBecomeDj || isDj || _snap.dj == null) return;
    if (on == hasRequested) return;
    if (on && !await _prepare()) return;
    if (_disposed || isDj || _snap.dj == null || on == hasRequested) return;
    // Shown right away; the DJ's next state confirms it.
    _snap = _snap.copyWith(
        requests: on
            ? [..._snap.requests, selfIdentity]
            : _snap.requests.where((r) => r != selfIdentity).toList());
    _send({'t': 'req', 'on': on}, to: [_snap.dj!]);
    _notify();
  }

  // ---------------------------------------------------------------------
  // DJ actions

  /// Hands the booth to [identity]; they take over once they are ready.
  void passTo(String identity) {
    if (!isDj || identity == selfIdentity) return;
    if (capsOf(identity)?.canDj != true || !transport.isPresent(identity)) {
      return;
    }
    final passId = _newId();
    _snap = _snap.copyWith(passTo: identity, passId: passId);
    _startPassTimer(passId);
    _sendState();
    _notify();
  }

  void _startPassTimer(String passId) {
    _passTimer?.cancel();
    _passTimer = Timer(passTimeout, () {
      if (!isDj || _snap.passId != passId) return;
      _snap = _snap.copyWith(clearPassTo: true);
      _sendState();
      _notice("The decks weren't handed over: they didn't take them in time");
      _notify();
    });
  }

  void cancelPass() {
    if (!isDj || _snap.passTo == null) return;
    _passTimer?.cancel();
    _snap = _snap.copyWith(clearPassTo: true);
    _sendState();
    _notify();
  }

  /// Leaves the booth. The queue stays, paused, for the next DJ.
  Future<void> stopDjing() async {
    if (_role == DjRole.listener || _snap.dj != selfIdentity) {
      // Only fetching a pass: say no to it instead.
      if (_role == DjRole.joining && _engine != null) {
        final engine = _engine!;
        final from = _snap.dj;
        final passId = _takingPass;
        await _abandon(engine);
        if (from != null && passId != null) {
          _send({'t': 'pfail', 'e': _snap.epoch, 'pid': passId, 'why': 'they said no'},
              to: [from]);
        }
      }
      return;
    }
    await _release();
  }

  Future<void> _release() async {
    final position = positionMs;
    _snap = _snap.copyWith(
        epoch: _snap.epoch + 1,
        seq: 0,
        clearDj: true,
        playing: false,
        buffering: false,
        positionMs: position,
        // Nobody left to ask.
        requests: const [],
        clearPassTo: true);
    _basePos = position;
    _baseAt = _now();
    _stepDown();
    await _sendState();
    _notify();
  }

  bool get _locked => !isDj || _snap.passTo != null;

  void togglePause() => setPaused(!(_paused || _snap.current == null));

  void setPaused(bool paused) {
    if (_locked) return;
    _failuresInARow = 0;
    if (_snap.current == null) {
      if (!paused && _snap.queue.isNotEmpty) _advance();
      return;
    }
    // A song that failed to load stays on the decks; playing retries it.
    if (!paused && !_loading && _engine?.status.trackId != _snap.current!.id) {
      _paused = false;
      _startCurrent(positionMs: _basePos);
      return;
    }
    _paused = paused;
    _engine?.setPaused(paused);
    _basePos = positionMs;
    _baseAt = _now();
    _snap = _snap.copyWith(playing: !paused);
    _sendState();
    _notify();
  }

  void skip() {
    if (_locked) return;
    _failuresInARow = 0;
    _advance();
  }

  Future<void> seek(int positionMs) async {
    if (_locked || _snap.current == null || _loading) return;
    final duration = durationMs;
    final target = max(0,
        duration != null && duration > 0 ? min(positionMs, duration) : positionMs);
    try {
      await _engine?.seek(target);
    } catch (e) {
      _notice("Couldn't jump there: $e", isError: true);
      return;
    }
    _basePos = target;
    _baseAt = _now();
    _sendState();
    _notify();
  }

  /// Plays a queued track now, in place of the current one.
  void playNow(String id) {
    if (_locked) return;
    final track = _snap.queue.firstWhereOrNull((t) => t.id == id);
    if (track == null) return;
    _snap = _snap.copyWith(
        current: track, queue: _snap.queue.where((t) => t.id != id).toList());
    _paused = false;
    _failuresInARow = 0;
    _startCurrent(positionMs: 0);
  }

  void playNext(String id) {
    if (_locked) return;
    final track = _snap.queue.firstWhereOrNull((t) => t.id == id);
    if (track == null) return;
    _setQueue([track, ..._snap.queue.where((t) => t.id != id)]);
  }

  /// Moves the queue entry at [from] to [to], both indexes into the queue
  /// before the move (like ReorderableListView reports them).
  void move(int from, int to) {
    if (_locked) return;
    final queue = [..._snap.queue];
    if (from < 0 || from >= queue.length) return;
    final track = queue.removeAt(from);
    if (to > from) to--;
    queue.insert(to.clamp(0, queue.length), track);
    _setQueue(queue);
  }

  void remove(String id) {
    if (_locked) return;
    _setQueue(_snap.queue.where((t) => t.id != id).toList());
  }

  void clearQueue() {
    if (_locked) return;
    _setQueue(const []);
  }

  void shuffle() {
    if (_locked) return;
    _setQueue([..._snap.queue]..shuffle(_random));
  }

  /// Replaces a queued track, e.g. with the result of a corrected link.
  void replace(String id, List<DjTrack> tracks) {
    if (_locked) return;
    final index = _snap.queue.indexWhere((t) => t.id == id);
    if (index < 0) return;
    _setQueue([
      ..._snap.queue.take(index),
      ...tracks,
      ..._snap.queue.skip(index + 1),
    ].take(maxQueue).toList());
  }

  /// Points a queued song at another [link] (looked up again, shown in the
  /// add bar while it is) and gives it another [title].
  void editTrack(String id, {String? link, String? title}) {
    if (_locked) return;
    final track = _snap.queue.firstWhereOrNull((t) => t.id == id);
    if (track == null) return;
    final newTitle = title?.trim();
    final newLink = link?.trim();
    if (newLink == null || newLink.isEmpty || newLink == track.pageUrl) {
      if (newTitle != null && newTitle != track.title) rename(id, newTitle);
      return;
    }
    final parsed = DjLinks.parse(newLink);
    final resolver = this.resolver;
    if (parsed == null || resolver == null) {
      _notice("That doesn't look like a link the booth can play",
          isError: true);
      return;
    }
    final pending = DjPendingAdd(_newId(), parsed);
    _pendingAdds.add(pending);
    _notify();
    resolver.resolve(parsed, addedBy: track.addedBy).then((tracks) {
      _pendingAdds.remove(pending);
      if (_disposed) return;
      if (tracks.isEmpty) {
        _notice("Nothing playable in that link", isError: true);
      } else if (_locked || !_snap.queue.any((t) => t.id == id)) {
        _notice('That song left the queue before its new link was ready',
            isError: true);
      } else {
        // A title given with the new link wins, for a single song.
        final renamed = tracks.length == 1 &&
                newTitle != null &&
                newTitle.isNotEmpty &&
                newTitle != track.title
            ? [tracks.single.copyWith(title: newTitle)]
            : tracks;
        replace(id, renamed);
      }
      _notify();
    }, onError: (Object e) {
      _pendingAdds.remove(pending);
      _notice("Couldn't use that link: $e", isError: true);
      _notify();
    });
  }

  void rename(String id, String title) {
    final trimmed = title.trim();
    if (_locked || trimmed.isEmpty) return;
    final kept = trimmed.length > DjTrack.maxText
        ? trimmed.substring(0, DjTrack.maxText)
        : trimmed;
    _setQueue([
      for (final t in _snap.queue) t.id == id ? t.copyWith(title: kept) : t,
    ]);
  }

  /// Queues [tracks] at the end, or next. Starts playing when nothing is.
  void addTracks(List<DjTrack> tracks, {bool next = false}) {
    if (_locked || tracks.isEmpty) return;
    final room = maxQueue - _snap.queue.length;
    if (room <= 0) {
      _notice('The queue is full', isError: true);
      return;
    }
    final added = tracks.take(room).toList();
    if (added.length < tracks.length) {
      _notice('The queue is full: ${tracks.length - added.length} left out');
    }
    _setQueue(next ? [...added, ..._snap.queue] : [..._snap.queue, ...added]);
    // Like a jukebox: songs added to an idle booth start playing.
    if (_snap.current == null) _advance();
  }

  /// Resolves every link in [text] and queues what they hold, in order.
  /// Returns how many links were found.
  int addLinks(String text, {bool next = false}) {
    if (_locked) return 0;
    final links = DjLinks.parseAll(text);
    final resolver = this.resolver;
    if (links.isEmpty || resolver == null) return 0;

    // Resolved in parallel, queued in the pasted order.
    final pending = [for (final l in links) DjPendingAdd(_newId(), l)];
    _pendingAdds.addAll(pending);
    _notify();
    final results = [
      for (final p in pending)
        resolver.resolve(p.link, addedBy: selfUserId).then<List<DjTrack>?>(
            (tracks) => tracks, onError: (Object e) {
          _notice("Couldn't add ${p.link.url}: $e", isError: true);
          return null;
        }),
    ];
    () async {
      final resolved = <DjTrack>[];
      for (var i = 0; i < pending.length; i++) {
        final tracks = await results[i];
        _pendingAdds.remove(pending[i]);
        if (tracks != null) resolved.addAll(tracks);
      }
      if (_disposed) return;
      if (resolved.isNotEmpty) {
        if (_locked) {
          _notice("The booth changed hands before those songs were added",
              isError: true);
        } else {
          addTracks(resolved, next: next);
        }
      }
      _notify();
    }();
    return links.length;
  }

  void _setQueue(List<DjTrack> queue) {
    final next = _snap.copyWith(queue: queue);
    // Grown past what one state can carry (long titles and links on a full
    // queue): refused here, so no announcement, a handoff's least of all,
    // can ever fail to go out.
    if (queue.length > _snap.queue.length &&
        DjProtocol.split({'t': 'state', ...next.toJson()}) == null) {
      _notice('The queue is too long to share; remove some songs first',
          isError: true);
      return;
    }
    _snap = next;
    _sendState();
    _prefetch();
    _notify();
  }

  // ---------------------------------------------------------------------
  // Playback on the DJ

  /// Plays the next queued track, or goes idle when there is none.
  void _advance() {
    if (!isDj) return;
    if (_snap.queue.isEmpty) {
      _playGen++;
      _loading = false;
      _engine?.unload();
      _snap = _snap.copyWith(
          clearCurrent: true, playing: false, buffering: false, positionMs: 0);
      _basePos = 0;
      _baseAt = _now();
      _sendState();
      _notify();
      return;
    }
    _snap = _snap.copyWith(
        current: _snap.queue.first, queue: _snap.queue.skip(1).toList());
    _paused = false;
    _startCurrent(positionMs: 0);
  }

  Future<void> _startCurrent({required int positionMs}) async {
    final engine = _engine;
    final track = _snap.current;
    if (engine == null || track == null) return;
    final gen = ++_playGen;
    _loading = true;
    _lastEngineState = null;
    _basePos = positionMs;
    _baseAt = _now();
    _snap = _snap.copyWith(
        playing: !_paused, buffering: true, positionMs: positionMs);
    _sendState();
    _notify();

    bool overtaken() => gen != _playGen || _engine != engine || _disposed;
    try {
      final info = await engine.prepare(track);
      if (overtaken()) return;
      engine.load(track, positionMs: positionMs, paused: _paused);
      _loading = false;
      _failuresInARow = 0;
      _mergeInfo(track.id, info);
      _snap = _snap.copyWith(playing: !_paused, buffering: false);
      _basePos = positionMs;
      _baseAt = _now();
      _sendState();
      _prefetch();
      _notify();
    } catch (e) {
      if (overtaken()) return;
      _loading = false;
      _failed(track, e.toString().replaceFirst('Bad state: ', ''));
    }
  }

  /// [track] couldn't play: on to the next one, unless songs keep failing
  /// (the tools broke, the network is down), then stop and say so.
  void _failed(DjTrack track, String why) {
    _failuresInARow++;
    if (_failuresInARow < maxFailuresInARow) {
      _notice("Couldn't play ${track.title}: $why", isError: true);
      _advance();
      return;
    }
    _notice(
        "Stopped: $_failuresInARow songs in a row couldn't play "
        "(last: $why)",
        isError: true);
    _paused = true;
    _engine?.unload();
    _basePos = 0;
    _baseAt = _now();
    _snap = _snap.copyWith(playing: false, buffering: false, positionMs: 0);
    _sendState();
    _notify();
  }

  /// Fills in what fetching taught us about a track (title and length for
  /// SoundCloud sets, the real length of a Spotify song's YouTube match).
  void _mergeInfo(String id, DjTrackInfo info) {
    DjTrack merge(DjTrack t) {
      if (t.id != id) return t;
      if (t.kind == DjSource.spotify) {
        return t.copyWith(
            durationMs: info.durationMs ?? t.durationMs,
            thumbnail: t.thumbnail ?? info.thumbnail);
      }
      return t.copyWith(
          title: djString(info.title, DjTrack.maxText) ?? t.title,
          artist: djString(info.artist, DjTrack.maxText) ?? t.artist,
          durationMs: info.durationMs ?? t.durationMs,
          thumbnail: t.thumbnail ?? djString(info.thumbnail, DjTrack.maxUrl));
    }

    final current = _snap.current;
    _snap = _snap.copyWith(
      current: current == null ? null : merge(current),
      queue: [for (final t in _snap.queue) merge(t)],
    );
  }

  void _prefetch() {
    final engine = _engine;
    if (!isDj || engine == null) return;
    for (final track in _snap.queue.take(prefetchAhead)) {
      engine.prepare(track).then((info) {
        if (_engine != engine || _disposed) return;
        final before = _snap.queue.firstWhereOrNull((t) => t.id == track.id);
        _mergeInfo(track.id, info);
        final after = _snap.queue.firstWhereOrNull((t) => t.id == track.id);
        if (before != after) {
          _sendState();
          _notify();
        }
      }, onError: (_) {
        // Reported when it is its turn to play.
      });
    }
  }

  DjEngineState? _lastEngineState;

  void _poll() {
    final engine = _engine;
    if (!isDj || engine == null || _loading) return;
    final status = engine.status;
    if (status.trackId != _snap.current?.id) return;
    final state = status.state;
    if (state == _lastEngineState) return;
    _lastEngineState = state;
    switch (state) {
      case DjEngineState.ended:
        _advance();
      case DjEngineState.error:
        _failed(_snap.current!, 'the decoder failed');
      case DjEngineState.buffering:
      case DjEngineState.playing:
        final buffering = state == DjEngineState.buffering;
        if (buffering != _snap.buffering) {
          _snap = _snap.copyWith(buffering: buffering);
          _sendTick();
          _notify();
        }
      case DjEngineState.idle:
      case DjEngineState.paused:
        break;
    }
  }

  /// Sends the booth to everyone (a new `seq`), or to [to] (the same one).
  Future<void> _sendState({List<String>? to}) {
    if (_snap.dj == selfIdentity) {
      _snap = _snap.copyWith(positionMs: positionMs);
    }
    if (to == null) _snap = _snap.copyWith(seq: _snap.seq + 1);
    final messages = DjProtocol.split({'t': 'state', ..._snap.toJson()});
    if (messages == null) {
      _notice('The queue is too long to share; remove some songs',
          isError: true);
      return Future.value();
    }
    Future<void> last = Future.value();
    for (final message in messages) {
      last = _send(message, to: to);
    }
    return last;
  }

  void _sendTick() {
    if (!isDj) return;
    _send({
      't': 'tick',
      'e': _snap.epoch,
      's': _snap.seq,
      'c': _snap.current?.id,
      'pos': positionMs,
      'p': _snap.playing,
      if (_snap.buffering) 'b': true,
    });
  }

  /// How loud the DJ hears their own music. Listeners set theirs on the
  /// music stream instead.
  set monitorVolume(double volume) => _engine?.monitorVolume = volume;
}
