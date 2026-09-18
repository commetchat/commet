import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:collection/collection.dart';
import 'package:commet/client/call_manager.dart';
import 'package:commet/client/client.dart';
import 'package:commet/client/components/activities/activities_component.dart';
import 'package:commet/client/components/voip/audio_processing/audio_processing_manager.dart';
import 'package:commet/client/components/voip/voip_session.dart';
import 'package:commet/client/components/voip/voip_stream.dart';
import 'package:commet/client/components/voip/webrtc_screencapture_source.dart';
import 'package:commet/client/components/voip/android_screencapture_source.dart';
import 'package:commet/client/matrix/components/voip_room/call_membership_writes.dart';
import 'package:commet/client/matrix/components/voip_room/call_membership_publisher.dart';
import 'package:commet/client/matrix/components/voip_room/matrix_call_membership.dart';
import 'package:commet/client/matrix/components/voip_room/matrix_livekit_encryption_key_provider.dart';
import 'package:commet/client/matrix/components/voip_room/matrix_livekit_voip_stream.dart';
import 'package:commet/client/matrix/components/voip_room/matrix_voip_room_component.dart';
import 'package:commet/client/matrix/components/voip_room/screen_share_watch_list.dart';
import 'package:commet/client/matrix/matrix_room.dart';
import 'package:commet/config/platform_utils.dart';
import 'package:commet/debug/log.dart';
import 'package:commet/main.dart';
import 'package:flutter/src/widgets/framework.dart';
import 'package:flutter_background/flutter_background.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:matrix/matrix.dart' show Event;
import 'package:matrix/matrix_api_lite.dart';
import 'package:livekit_client/livekit_client.dart' as lk;

/// The publish options for a screen share.
///
/// Both streams a share can send carry the user's frame rate and bitrate.
/// The backup codec is the one viewers that cannot decode the primary codec
/// receive — with H.265 in practice, and the SFU falls back to it for them.
/// Without an explicit encoding the SDK computes one from a screen-share
/// preset capped at 15 FPS, so those viewers saw a low frame rate while the
/// sharer's settings said otherwise (issue #79). E2EE rooms get no backup
/// codec, matching the SDK's own policy: multi-codec simulcast is not
/// supported with frame encryption.
lk.VideoPublishOptions buildScreenSharePublishOptions({
  required String codec,
  required int framerate,
  required int bitrate,
  required bool simulcast,
  required bool e2ee,
}) {
  final encoding =
      lk.VideoEncoding(maxFramerate: framerate, maxBitrate: bitrate);
  return lk.VideoPublishOptions(
    simulcast: simulcast,
    screenShareEncoding: encoding,
    videoEncoding: encoding,
    degradationPreference: lk.DegradationPreference.maintainFramerate,
    videoCodec: codec,
    backupVideoCodec: lk.BackupVideoCodec(
      enabled: !e2ee,
      codec: 'vp8',
      simulcast: simulcast,
      encoding: encoding,
    ),
  );
}

class MatrixLivekitVoipSession implements VoipSession, ScreenShareWatching {
  MatrixRoom room;
  lk.Room livekitRoom;
  Timer? heartbeatTimer;
  String? heartbeatDelayId;

  MatrixLivekitEncryptionKeyProvider? keyProvider;

  final StreamController<void> _onVolumeChanged = StreamController.broadcast();

  /// Lists what we publish and whether we have silenced ourselves in our call
  /// membership, so people outside the call see our LIVE badge and our
  /// muted/deafened icon (issue #9).
  late final CallMembershipPublisher _membershipPublisher =
      CallMembershipPublisher(write: _writeMembershipState);

  /// The session connects with auto-subscribe off and subscribes itself,
  /// leaving out screen shares nobody opted in to watch (issue #50).
  final ScreenShareWatchList _watchList = ScreenShareWatchList(
      autoWatch: () => preferences.voipAutoWatchScreenShares.value);

  /// The capture tracks this session published for its screen share: the
  /// screen video and, when system audio is shared, the screen audio. The
  /// session keeps them because LiveKit's publication map is not a handle on
  /// the capture — a full reconnect clears it while the OS capture keeps
  /// running — and [stopScreenshare] still has to stop it (issue #63).
  final List<lk.LocalTrack> _captureTracks = [];

  /// The capture tracks above that the session has stopped. A full reconnect
  /// republishes the track objects LiveKit held before it cleared its map, so
  /// identity against these is what tells a share that was already stopped
  /// apart from a new one (issue #64).
  final List<lk.LocalTrack> _stoppedCaptures = [];

  String get _ownMembershipKey =>
      "_${room.client.self!.identifier}_${room.matrixRoom.client.deviceID!}_m.call";

  /// The call manager this session registered with. An app refresh replaces
  /// the global one, and a hang up that finishes late must not report to it.
  late final CallManager? _callManager = clientManager?.callManager;

  MatrixLivekitVoipSession(this.room, this.livekitRoom, {this.keyProvider}) {
    // First: if this throws, nothing was registered or started yet, so no
    // half built session is left behind in the call manager.
    keyProvider?.init(livekitRoom.localParticipant!.identity, livekitRoom);

    _callManager?.onClientSessionStarted(this);
    addInitialStreams();

    final listener = livekitRoom.createListener();
    _roomListener = listener;
    listener.on(onTrackPublished);
    listener.on(onTrackUnpublished);
    listener.on(onTrackSubscribed);
    listener.on(onTrackUnsubscribed);
    listener.on(onTrackSubscriptionException);
    listener.on(onLocalTrackPublished);
    listener.on(onLocalTrackUnpublished);
    listener.on(onTrackStreamEvent);
    listener.on(onTrackMutedEvent);
    listener.on(onTrackUnmutedEvent);
    listener.on(onParticipantConnected);
    listener.on(onParticipantDisconnected);
    listener.on(onDataReceived);
    listener.on(onRoomReconnected);
    listener.on(onRoomConnected);
    listener.on(onRoomDisconnected);
    listener.on(onSubscriptionPermissionChanged);

    _volumeTimer = Timer.periodic(Duration(milliseconds: 200), (timer) {
      if (state == VoipState.ended) timer.cancel();
      _onVolumeChanged.add(());
    });

    _dspNoiseSuppression = preferences.voipNoiseSuppression.value;
    _settingsSub = preferences.onSettingChanged.listen((_) {
      final now = preferences.voipNoiseSuppression.value;
      if (now == _dspNoiseSuppression) return;
      _dspNoiseSuppression = now;
      _reapplyNoiseSuppression();
    });
    _dspWatchdog =
        Timer.periodic(const Duration(seconds: 1), (_) => _checkDspAlive());

    startHeartbeat().catchError((Object e, StackTrace s) {
      Log.onError(e, s, content: "Could not start the membership heartbeat");
    });
  }

  StreamController _stateChanged = StreamController.broadcast();
  final StreamController<VoipState> _onConnectionChanged =
      StreamController.broadcast();

  StreamSubscription? _settingsSub;
  bool _dspNoiseSuppression = false;

  /// The microphone track is created with WebRTC's suppressor off whenever
  /// our DSP is supported (MatrixLivekitBackend.join), which is decided by
  /// the library loading, before anything has been captured. If the DSP
  /// then never receives audio, the call would have neither suppressor.
  /// Once that has been seen for [_dspStallLimit] of live microphone, WebRTC's
  /// suppressor goes back on for the rest of the call.
  bool _dspFailed = false;
  DateTime? _dspStalledSince;
  Timer? _dspWatchdog;
  static const _dspStallLimit = Duration(seconds: 4);

  void _checkDspAlive() {
    if (_dspFailed || state == VoipState.ended) return;
    final dsp = AudioProcessingManager.instance;
    final pub =
        livekitRoom.localParticipant?.audioTrackPublications.firstOrNull;
    final micLive = pub != null && pub.track != null && !pub.muted;
    if (!dsp.isSupported || !_dspNoiseSuppression || !micLive) {
      _dspStalledSince = null;
      return;
    }
    if (dsp.isProcessing) {
      _dspStalledSince = null;
      return;
    }
    final since = _dspStalledSince ??= DateTime.now();
    if (DateTime.now().difference(since) < _dspStallLimit) return;
    _dspFailed = true;
    Log.w("Voice DSP: no microphone audio reached it in "
        "${_dspStallLimit.inSeconds} s of live microphone; turning WebRTC's "
        "noise suppression back on for this call");
    _reapplyNoiseSuppression();
  }

  lk.EventsListener<lk.RoomEvent>? _roomListener;
  Timer? _volumeTimer;

  /// The WebRTC / browser noise suppressor is a capture option fixed when
  /// the microphone track is created (off while our DSP suppresses, see
  /// MatrixLivekitBackend.join). Toggling our suppressor mid-call therefore
  /// has to recreate the track with the opposite option, otherwise the user
  /// ends up with both or neither.
  Future<void> _reapplyNoiseSuppression() async {
    final dsp = AudioProcessingManager.instance;
    if (!dsp.isSupported) return;
    final participant = livekitRoom.localParticipant;
    if (participant == null) return;
    final pub = participant.audioTrackPublications.firstOrNull;
    final track = pub?.track;
    if (pub == null || track is! lk.LocalAudioTrack || pub.muted) return;

    final wantWebrtcSuppression = !_dspNoiseSuppression || _dspFailed;
    if (track.currentOptions.noiseSuppression == wantWebrtcSuppression) {
      return;
    }
    try {
      await track.restartTrack(track.currentOptions
          .copyWith(noiseSuppression: wantWebrtcSuppression));
      Log.i("Voice DSP: restarted the microphone, WebRTC noise suppression "
          "${wantWebrtcSuppression ? "on" : "off"}");
    } catch (e, s) {
      Log.onError(e, s, content: "Voice DSP: could not restart microphone");
    }
  }

  @override
  Stream<VoipState> get onConnectionStateChanged => _onConnectionChanged.stream;

  void addInitialStreams() {
    if (livekitRoom.localParticipant != null) {
      for (var entry
          in livekitRoom.localParticipant!.trackPublications.entries) {
        if (entry.value.muted && entry.value.kind == lk.TrackType.VIDEO) {
          continue;
        }

        streams.add(
            MatrixLivekitVoipStream(entry.value, room.client.self!.identifier));
      }
    }

    // Auto-watch first, for every participant: the subscriptions below are
    // decided from the watch list, and a screen share's audio can come
    // before its video.
    for (var entry in livekitRoom.remoteParticipants.entries) {
      for (var publication in entry.value.trackPublications.values) {
        if (publication.source == lk.TrackSource.screenShareVideo) {
          _watchList.onScreenSharePublished(entry.value.identity);
        }
      }
    }

    for (var entry in livekitRoom.remoteParticipants.entries) {
      for (var stream in entry.value.trackPublications.entries) {
        // Before the muted check: a muted camera still has to be subscribed
        // for when it unmutes.
        _syncSubscription(stream.value);

        if (_hiddenWhileMuted(stream.value)) continue;

        String userId = entry.key;
        userId = userId.split(":").getRange(0, 2).join(":");

        final s = MatrixLivekitVoipStream(stream.value, userId, watching: this);
        _applyStreamVolume(s);
        streams.add(s);
      }
    }
  }

  @override
  Future<void> acceptCall(
      {bool withMicrophone = false, bool withCamera = false}) {
    throw UnimplementedError();
  }

  void onTrackStreamEvent(lk.TrackStreamStateUpdatedEvent event) {
    for (var track in streams) {
      final t = track as MatrixLivekitVoipStream;
      if (t.publication.sid == event.publication.sid) {
        t.onStreamUpdatedEvent();
      }
    }
  }

  void onTrackMutedEvent(lk.TrackMutedEvent event) {
    // LiveKit only reports a mute for a publication that has its track. One
    // muted while unsubscribed is dealt with in [onTrackSubscribed]. A muted
    // screen share keeps its tile: it hosts the volume control of the system
    // audio, which keeps playing.
    if (_hiddenWhileMuted(event.publication)) {
      _removeStreamsWithSid(event.publication.sid);
    }

    for (var track in streams) {
      final t = track as MatrixLivekitVoipStream;
      if (t.publication.sid == event.publication.sid) {
        t.onStreamUpdatedEvent();
      }
    }

    _stateChanged.add(());
    _publishMembershipState();
  }

  void onTrackUnmutedEvent(lk.TrackUnmutedEvent event) {
    final participant =
        event.participant.identity.split(":").getRange(0, 2).join(":");

    for (var track in streams) {
      final t = track as MatrixLivekitVoipStream;
      if (t.publication.sid == event.publication.sid) {
        t.onStreamUpdatedEvent();
      }
    }

    // A stream we already have (a microphone, a muted screen share) still
    // changed: the room list's mute icon reads it, and would otherwise keep
    // showing a remote member as muted until something else refreshed it.
    if (streams.any((e) => e.streamId == event.publication.sid)) {
      _stateChanged.add(());
      _publishMembershipState();
      return;
    }

    final remote = event.publication is lk.RemoteTrackPublication;
    final s = MatrixLivekitVoipStream(event.publication, participant,
        watching: remote ? this : null);
    _applyStreamVolume(s);
    s.deafened = remote
        ? _deafenedIdentities.contains(event.participant.identity)
        : _isDeafened;
    streams.add(s);
    _stateChanged.add(());
    _publishMembershipState();
  }

  void onTrackPublished(lk.TrackPublishedEvent event) {
    if (event.publication.source == lk.TrackSource.screenShareVideo &&
        _watchList.onScreenSharePublished(event.participant.identity)) {
      // Auto-watch started watching now: the screen audio may have been
      // announced before the video, when nothing was watched yet.
      _syncScreenShare(event.participant);
    }
    _syncSubscription(event.publication);

    if (!_hiddenWhileMuted(event.publication)) {
      _addRemoteStream(event.participant, event.publication);
    }
    _stateChanged.add(());
  }

  /// A muted camera has no tile, it gets one when it unmutes. Not so for a
  /// screen share: one nobody watches has no track, and LiveKit reports no
  /// unmute without a track, so its tile could never come back.
  bool _hiddenWhileMuted(lk.TrackPublication publication) =>
      publication.kind == lk.TrackType.VIDEO &&
      publication.muted &&
      publication.source != lk.TrackSource.screenShareVideo;

  MatrixLivekitVoipStream _addRemoteStream(
      lk.RemoteParticipant participant, lk.RemoteTrackPublication publication) {
    final userId = participant.identity.split(":").getRange(0, 2).join(":");

    final s = MatrixLivekitVoipStream(publication, userId, watching: this);
    _applyStreamVolume(s);
    s.deafened = _deafenedIdentities.contains(participant.identity);
    streams.add(s);
    return s;
  }

  Iterable<MatrixLivekitVoipStream> _streamsWithSid(String sid) => streams
      .whereType<MatrixLivekitVoipStream>()
      .where((s) => s.publication.sid == sid);

  /// Removes the streams of a publication and releases what they hold.
  void _removeStreamsWithSid(String sid) {
    final removed = _streamsWithSid(sid).toList();
    streams.removeWhere(removed.contains);
    for (final stream in removed) {
      stream.dispose();
    }
  }

  /// LiveKit announces a remote publication (TrackPublishedEvent) before it
  /// subscribes to it, so the stream's track, and with it the playback
  /// volume and the speaking visualizer, only arrives here.
  ///
  /// A publication can also have lost its stream by then (a video muted and
  /// unmuted while unsubscribed), so a subscribed track always gets one.
  void onTrackSubscribed(lk.TrackSubscribedEvent event) {
    // Stop watching was clicked while the subscription was still on its way:
    // unsubscribe() ignores publications without a track.
    if (!_watchList.shouldSubscribe(
        event.participant.identity, event.publication.source)) {
      // Silent until it is gone: the audio element plays at full volume
      // until the unsubscribe lands, a round trip away.
      for (final stream in _streamsWithSid(event.publication.sid)) {
        stream.applyVolume(0);
      }
      _syncSubscription(event.publication);
      return;
    }

    // Muted while it had no track: LiveKit sent no mute event for it, and a
    // renderer on a muted track is a black tile (issue #47).
    if (_hiddenWhileMuted(event.publication)) {
      _removeStreamsWithSid(event.publication.sid);
      _stateChanged.add(());
      return;
    }

    // A stream can outlive its publication: LiveKit rebuilds publications
    // on a full reconnect and keeps their sid.
    final outdated = _streamsWithSid(event.publication.sid)
        .where((s) => !identical(s.publication, event.publication))
        .toList();
    streams.removeWhere(outdated.contains);
    for (final stream in outdated) {
      stream.dispose();
    }

    final existing = _streamsWithSid(event.publication.sid).toList();
    if (existing.isEmpty) {
      existing.add(_addRemoteStream(event.participant, event.publication));
    }
    for (final stream in existing) {
      stream.onTrackSubscribed();
      stream.onStreamUpdatedEvent();
    }
    _subscriptionRetries.remove(event.publication.sid);
    _stateChanged.add(());
  }

  void onTrackUnsubscribed(lk.TrackUnsubscribedEvent event) {
    for (final stream in _streamsWithSid(event.publication.sid)) {
      stream.onTrackUnsubscribed();
      stream.onStreamUpdatedEvent();
    }
    _stateChanged.add(());
  }

  static const int _maxSubscriptionRetries = 3;
  final Map<String, int> _subscriptionRetries = {};

  /// LiveKit gave up attaching a track (usually its metadata came too late).
  /// Nothing else asks for it again, so the tile would stay empty.
  Future<void> onTrackSubscriptionException(
      lk.TrackSubscriptionExceptionEvent event) async {
    Log.w("Track subscription failed: $event");
    final sid = event.sid;
    if (sid == null) return;

    final retries = _subscriptionRetries[sid] ?? 0;
    if (retries >= _maxSubscriptionRetries) return;
    _subscriptionRetries[sid] = retries + 1;

    await Future.delayed(Duration(seconds: 1 << retries));
    if (state == VoipState.ended) return;
    final publication = event.participant?.getTrackPublicationBySid(sid);
    if (publication == null || publication.subscribed) return;
    // Not for a screen share the user stopped watching in the meantime.
    if (!_watchList.shouldSubscribe(
        publication.participant.identity, publication.source)) {
      return;
    }
    try {
      await publication.resubscribe(
          stillWanted: () =>
              state != VoipState.ended &&
              _watchList.shouldSubscribe(
                  publication.participant.identity, publication.source));
    } catch (e, s) {
      Log.onError(e, s, content: "Could not subscribe to track $sid again");
    }
    _stateChanged.add(());
  }

  /// LiveKit reconnected. After a full reconnect it has rebuilt every remote
  /// participant without announcing their publications again, and it drops
  /// the publications announced while it was reconnecting. With auto
  /// subscribe off (issue #50) nobody subscribes to those for us, so the
  /// call would stay silent until rejoining.
  void onRoomReconnected(lk.RoomReconnectedEvent event) =>
      _resyncRemoteStreams();

  /// Emitted again after a reconnect rebuilt the participants, which is the
  /// point at which their publications can be seen. RoomReconnectedEvent
  /// alone can arrive while that rebuild is still running.
  void onRoomConnected(lk.RoomConnectedEvent event) => _resyncRemoteStreams();

  /// LiveKit gave up: it ran out of reconnect attempts, or the server closed
  /// the room. Nothing else noticed, so the call stayed on screen with no
  /// audio, and the heartbeat kept us listed as a participant (issue #48).
  void onRoomDisconnected(lk.RoomDisconnectedEvent event) {
    if (event.reason == lk.DisconnectReason.clientInitiated) return;
    if (state == VoipState.ended) return;
    Log.w("Livekit room disconnected (${event.reason}), ending the call");
    hangUpCall();
  }

  /// A sharer allowed us to subscribe after refusing: LiveKit ignored the
  /// subscribe() sent while it was refused.
  void onSubscriptionPermissionChanged(
          lk.TrackSubscriptionPermissionChangedEvent event) =>
      _syncSubscription(event.publication);

  void _resyncRemoteStreams() {
    if (state == VoipState.ended) return;

    final current = <String, lk.RemoteTrackPublication>{};
    for (final participant in livekitRoom.remoteParticipants.values) {
      for (final publication in participant.trackPublications.values) {
        current[publication.sid] = publication;
      }
    }

    final hasRemoteStreams = streams
        .whereType<MatrixLivekitVoipStream>()
        .any((s) => s.publication is lk.RemoteTrackPublication);
    // The rebuild has not happened yet: dropping everything now would leave
    // the call empty, with nothing left to announce the participants again.
    if (current.isEmpty && hasRemoteStreams) {
      Log.w("Skipped a resync: livekit has no remote participants yet");
      return;
    }

    // Streams of publications that are gone or were rebuilt.
    final outdated = streams
        .whereType<MatrixLivekitVoipStream>()
        .where((s) =>
            s.publication is lk.RemoteTrackPublication &&
            !identical(current[s.publication.sid], s.publication))
        .toList();
    streams.removeWhere(outdated.contains);
    for (final stream in outdated) {
      stream.dispose();
    }

    // Local publications are rebuilt too, and LiveKit republishes them
    // without announcing that the old ones are gone.
    final localPublications =
        livekitRoom.localParticipant?.trackPublications ?? const {};
    final staleLocal = streams
        .whereType<MatrixLivekitVoipStream>()
        .where((s) =>
            s.publication is lk.LocalTrackPublication &&
            !identical(localPublications[s.publication.sid], s.publication))
        .toList();
    streams.removeWhere(staleLocal.contains);
    for (final stream in staleLocal) {
      stream.dispose();
    }

    // A share that ended needs opting in again next time. Only for people we
    // can see: someone missing from the rebuild may still be sharing.
    _watchList.retainWhere((identity) =>
        !livekitRoom.remoteParticipants.containsKey(identity) ||
        current.values.any((p) =>
            p.participant.identity == identity &&
            p.source == lk.TrackSource.screenShareVideo));

    // Auto-watch shares that started while we were away, before subscribing.
    for (final participant in livekitRoom.remoteParticipants.values) {
      for (final publication in participant.trackPublications.values) {
        if (publication.source == lk.TrackSource.screenShareVideo) {
          _watchList.onScreenSharePublished(participant.identity);
        }
      }
    }

    for (final participant in livekitRoom.remoteParticipants.values) {
      for (final publication in participant.trackPublications.values) {
        _syncSubscription(publication);
        if (_streamsWithSid(publication.sid).isNotEmpty) continue;
        if (_hiddenWhileMuted(publication)) continue;
        _addRemoteStream(participant, publication);
      }
    }
    _stateChanged.add(());
  }

  /// Brings every screen share publication of [participant] in line with the
  /// watch list.
  Future<void> _syncScreenShare(lk.RemoteParticipant participant) =>
      Future.wait([
        for (final publication in participant.trackPublications.values)
          if (ScreenShareWatchList.isScreenShareSource(publication.source))
            _syncSubscription(publication),
      ]);

  /// Subscribes to or unsubscribes from a remote publication, as
  /// [_watchList] wants.
  Future<void> _syncSubscription(lk.RemoteTrackPublication publication) async {
    final subscribe = _watchList.shouldSubscribe(
        publication.participant.identity, publication.source);
    if (subscribe == publication.subscribed) return;
    try {
      if (subscribe) {
        await publication.subscribe();
      } else {
        await publication.unsubscribe();
      }
    } catch (e, s) {
      Log.onError(e, s,
          content: "Could not update the subscription to ${publication.sid}");
    }
  }

  @override
  bool isWatchingScreenShare(String participantIdentity) =>
      _watchList.isWatching(participantIdentity);

  @override
  Future<void> setWatchingScreenShare(
      String participantIdentity, bool watch) async {
    final changed = watch
        ? _watchList.watch(participantIdentity)
        : _watchList.stopWatching(participantIdentity);
    if (!changed) return;

    final participant = livekitRoom.remoteParticipants[participantIdentity];
    if (participant != null) {
      await _syncScreenShare(participant);
    }

    for (final stream in streams.whereType<MatrixLivekitVoipStream>()) {
      if (stream.publication.participant.identity == participantIdentity) {
        stream.onStreamUpdatedEvent();
      }
    }
    _stateChanged.add(());
  }

  void onParticipantConnected(lk.ParticipantConnectedEvent event) {
    _callManager?.joinCallSound();
    // Newcomers have no way of knowing we were already deafened.
    if (_isDeafened) {
      _broadcastVoiceState();
    }
  }

  void onParticipantDisconnected(lk.ParticipantDisconnectedEvent event) {
    _deafenedIdentities.remove(event.participant.identity);
    _callManager?.endCallSound();
  }

  /// Data topic used to tell the room about state LiveKit itself does not
  /// carry (deafen). Payload: `{"deafened": bool}`.
  static const voiceStateTopic = "chat.commet.voice_state.v1";

  /// LiveKit identities of remote participants who told us they are deafened.
  final Set<String> _deafenedIdentities = {};

  void onDataReceived(lk.DataReceivedEvent event) {
    if (event.topic != voiceStateTopic) return;
    final identity = event.participant?.identity;
    if (identity == null) return;

    bool deafened;
    try {
      final data = jsonDecode(utf8.decode(event.data));
      deafened = data is Map && data["deafened"] == true;
    } catch (_) {
      return;
    }

    if (deafened) {
      _deafenedIdentities.add(identity);
    } else {
      _deafenedIdentities.remove(identity);
    }

    _setStreamsDeafened(identity, deafened);
  }

  void _setStreamsDeafened(String identity, bool deafened) {
    for (var stream in streams) {
      final s = stream as MatrixLivekitVoipStream;
      if (s.publication.participant.identity != identity) continue;
      if (s.deafened == deafened) continue;
      s.deafened = deafened;
      s.onStreamUpdatedEvent();
    }
    _stateChanged.add(());
  }

  Future<void> _broadcastVoiceState() async {
    try {
      await livekitRoom.localParticipant?.publishData(
        utf8.encode(jsonEncode({"deafened": _isDeafened})),
        reliable: true,
        topic: voiceStateTopic,
      );
    } catch (e, s) {
      Log.onError(e, s, content: "Failed to broadcast voice state");
    }
  }

  /// Whether [tracks] holds [track], by identity: LiveKit's republish reuses
  /// the objects it held, so identity is what tells our captures apart.
  bool _containsIdentical(
          Iterable<lk.LocalTrack> tracks, lk.LocalTrack track) =>
      tracks.any((owned) => identical(owned, track));

  /// Owns a capture track of our screen share, once. LiveKit can announce the
  /// same track more than once: a reconnect republishes the track objects it
  /// held before clearing its map.
  void _ownCaptureTrack(lk.LocalTrack track) {
    if (!ScreenShareWatchList.isScreenShareSource(track.source)) {
      return;
    }
    if (_containsIdentical(_captureTracks, track)) return;
    _captureTracks.add(track);
  }

  /// Owned capture tracks that were stopped, for [stopScreenshare] to refuse
  /// when LiveKit republishes them.
  void _markCaptureStopped(lk.LocalTrack track) {
    if (_containsIdentical(_stoppedCaptures, track)) return;
    _stoppedCaptures.add(track);
  }

  bool _isStoppedCapture(lk.LocalTrack track) =>
      _containsIdentical(_stoppedCaptures, track);

  /// Refuses a screen share LiveKit republished after a reconnect for a
  /// capture this session already stopped, or a publication a stop left
  /// behind. The publication is removed through LiveKit so the sender the
  /// republish recreated is released, and no outgoing stream is added:
  /// participants see the share end instead of a dead tile, and the panel
  /// offers no LIVE tile for it (issues #64 and #79).
  Future<void> _refuseRepublishedShare(
      lk.LocalTrackPublication publication) async {
    Log.w("Refusing the screen share ${publication.sid}: "
        "its capture is no longer live");
    // A republish accepted before its capture was marked stopped left an
    // outgoing stream behind, and the refusal has to take it off the panel.
    _removeStreamsWithSid(publication.sid);
    try {
      await livekitRoom.localParticipant?.removePublishedTrack(publication.sid);
    } catch (e, s) {
      Log.onError(e, s, content: "Could not remove a republished screen share");
    }
  }

  Future<void> onLocalTrackPublished(lk.LocalTrackPublishedEvent event) async {
    final track = event.publication.track;
    if (track != null) {
      _ownCaptureTrack(track);
    }

    // A full reconnect clears LiveKit's publication map and republishes the
    // track objects it held. A share this session stopped must not come back:
    // the republish is refused as soon as it arrives, so one click is enough
    // even when the republish lands after the stop returned (issue #64).
    if (track != null && _isStoppedCapture(track)) {
      await _refuseRepublishedShare(event.publication);
      return;
    }

    final participant =
        event.participant.identity.split(":").getRange(0, 2).join(":");

    // Republished after a reconnect: LiveKit clears its publications without
    // announcing it, so the old stream would stay next to the new one.
    _removeStreamsWithSid(event.publication.sid);

    final s = MatrixLivekitVoipStream(event.publication, participant);
    s.deafened = _isDeafened;
    streams.add(s);
    _stateChanged.add(());
    _publishMembershipState();
  }

  void onLocalTrackUnpublished(lk.LocalTrackUnpublishedEvent event) {
    _removeStreamsWithSid(event.publication.sid);

    _stateChanged.add(());
    _publishMembershipState();
  }

  /// Screen share and camera as LiveKit sees them, which also covers a
  /// capture the OS or the browser ended.
  Set<LiveMedia> get _localLiveMedia => {
        if (isSharingScreen) LiveMedia.screen,
        if (isCameraEnabled) LiveMedia.camera,
      };

  /// Deafening turns the microphone off, so it always reports muted too.
  Set<VoiceState> get _localVoiceState => {
        if (isMicrophoneMuted || _isDeafened) VoiceState.muted,
        if (_isDeafened) VoiceState.deafened,
      };

  void _publishMembershipState() {
    if (state == VoipState.ended) return;
    // Only with the delayed leave armed: it is what clears the membership,
    // and the badge with it, if this client crashes while streaming.
    _membershipPublisher.update(heartbeatDelayId != null
        ? CallMembershipState(media: _localLiveMedia, voice: _localVoiceState)
        : const CallMembershipState());
  }

  // Named `published`, not `state`: `state` is this session's VoipState.
  Future<void> _writeMembershipState(CallMembershipState published) async {
    final current =
        room.matrixRoom.states[MatrixVoipRoomComponent.callMemberStateEvent]
            ?[_ownMembershipKey];
    // Never bring back a membership that was cleared (by hanging up, or by
    // the delayed leave): it would have no dead man's switch.
    if (current is! Event || current.content["application"] == null) {
      throw StateError("Our call membership is not in the room state yet");
    }
    final joinedAt =
        MatrixCallMembership.joinedAt(current.content, current.originServerTs)!;
    await room.matrixRoom.client.setRoomStateWithKey(
      room.matrixRoom.id,
      MatrixVoipRoomComponent.callMemberStateEvent,
      _ownMembershipKey,
      MatrixCallMembership.withPublishedState(current.content,
          media: published.media,
          voiceState: published.voice,
          joinedAt: joinedAt,
          now: DateTime.now()),
    );
  }

  void onTrackUnpublished(lk.TrackUnpublishedEvent event) {
    _removeStreamsWithSid(event.publication.sid);

    _subscriptionRetries.remove(event.publication.sid);

    // Only once no share is left: LiveKit announces the replacement before
    // it retires the old publication, and a sharer that reconnects
    // republishes with new sids. Ending the watch there would stop a share
    // nobody asked to stop (issue #50).
    if (event.publication.source == lk.TrackSource.screenShareVideo &&
        event.participant
                .getTrackPublicationBySource(lk.TrackSource.screenShareVideo) ==
            null) {
      _watchList.onScreenShareEnded(event.participant.identity);
      // Screen audio unpublished after the video must not keep playing.
      for (final publication in event.participant.trackPublications.values) {
        _syncSubscription(publication);
      }
    }

    _stateChanged.add(());
  }

  @override
  Client get client => room.client;

  @override
  VoipState state = VoipState.connected;

  @override
  Future<void> declineCall() {
    throw UnimplementedError();
  }

  Future<void>? _hangUp;

  /// One hang up however many callers ask for it (call view, call panel, app
  /// refresh): a second one used to cancel the same delayed leave again and
  /// fail, and ended the session twice.
  @override
  Future<void> hangUpCall() {
    // A failed hang up is not cached: it would be handed to every later
    // caller, and the session could never end (issue #48).
    return _hangUp ??= _doHangUp().catchError((Object e, StackTrace s) {
      _hangUp = null;
      Log.onError(e, s, content: "Could not hang up the call");
    });
  }

  Future<void> _doHangUp() async {
    if (state == VoipState.ended) return;
    Log.i("Hanging up call");

    // The captures belong to this session, and the room's dispose only
    // unpublishes what the SDK still has in its map — empty in exactly the
    // reconnect window that leaves the OS capture running. Stop them before
    // the teardown, bounded like it: the stop reaches a platform call, and a
    // capture that refuses to release must not keep the session alive
    // (issue #66).
    await _stopOwnedCaptureTracks()
        .timeout(const Duration(seconds: 8))
        .catchError((Object e, StackTrace s) {
      Log.onError(e, s,
          content: "Could not stop the screen capture on hang up");
    });

    try {
      // First, so no membership write lands after the clear below: leaving
      // unpublishes our tracks, which would schedule one.
      await _membershipPublisher.stop();
      // Likewise a heartbeat that is restoring our membership.
      heartbeatTimer?.cancel();
      await _heartbeatInFlight?.timeout(const Duration(seconds: 5),
          onTimeout: () {});

      keyProvider?.dispose();
      _settingsSub?.cancel();
      _settingsSub = null;
      _dspWatchdog?.cancel();
      _dspWatchdog = null;

      // Bounded: these hang when the network is what broke, and the session
      // still has to end and release LiveKit. The delayed leave, or
      // clearStaleOwnMembership, takes care of a membership left behind.
      await Future.wait([
        clearRoomCallState(),
        disconnectCall(),
        stopHeartbeat(),
      ]).timeout(const Duration(seconds: 8));
    } catch (e, s) {
      // Not rethrown: the session ends either way, and not every caller
      // awaits this.
      Log.onError(e, s, content: "Could not leave the call cleanly");
    } finally {
      // Even if one of the requests above failed: a session left half open
      // kept the old LiveKit room alive, and rejoining could fail with
      // "no internet connection" until the app restarted (issue #48).
      for (final stream in streams.whereType<MatrixLivekitVoipStream>()) {
        stream.dispose();
      }
      streams.clear();

      state = VoipState.ended;
      _volumeTimer?.cancel();
      _volumeTimer = null;
      _stateChanged.add(());
      _onConnectionChanged.add(state);

      _callManager?.onSessionEnded(this);

      await _roomListener?.dispose();
      _roomListener = null;
      await livekitRoom.dispose();
      Log.i("Disposed livekit room");
    }
  }

  bool _isDeafened = false;

  @override
  bool get isDeafened => _isDeafened;

  void _applyStreamVolume(MatrixLivekitVoipStream stream) {
    if (stream.direction == VoipStreamDirection.incoming) {
      stream.listenerDeafened = _isDeafened;
      stream.applyVolume(_isDeafened ? 0.0 : stream.volume);
    }
  }

  @override
  bool get isCameraEnabled =>
      livekitRoom.localParticipant?.isCameraEnabled() ?? false;

  @override
  bool get isMicrophoneMuted => livekitRoom.localParticipant?.isMuted ?? false;

  /// Whether a screen capture this session owns is still running.
  bool get _hasActiveCapture => _captureTracks.any((track) => track.isActive);

  /// Sharing follows the capture, not only LiveKit: a full reconnect empties
  /// the publication map while the capture keeps running, and the app must not
  /// report the screen as private then (issue #65). An Android capture,
  /// created by the SDK, is owned through the publication event and reads the
  /// same way; only how it is started and stopped is left to the SDK.
  @override
  bool get isSharingScreen =>
      (livekitRoom.localParticipant?.isScreenShareEnabled() ?? false) ||
      _hasActiveCapture;

  @override
  Stream<void> get onStateChanged => _stateChanged.stream;

  @override
  String? get remoteUserId => null;

  @override
  VoipStream? get remoteUserMediaStream => null;

  @override
  String? get remoteUserName => null;

  @override
  String get roomId => room.identifier;

  @override
  String get roomName => room.displayName;

  @override
  String get sessionId => "";

  @override
  Future<void> setMicrophoneMute(bool state) async {
    // Regra do Discord: desmutar microfone enquanto ensurdecido cancela o deafen
    if (!state && _isDeafened) {
      await setDeafened(false);
      return;
    }

    await livekitRoom.localParticipant?.setMicrophoneEnabled(!state);
    _publishMembershipState();
    _stateChanged.add(());
  }

  @override
  Future<void> setDeafened(bool state) async {
    _isDeafened = state;

    if (state) {
      await livekitRoom.localParticipant?.setMicrophoneEnabled(false);
    } else {
      await livekitRoom.localParticipant?.setMicrophoneEnabled(true);
    }

    for (var stream in streams) {
      if (stream is MatrixLivekitVoipStream) {
        _applyStreamVolume(stream);
      }
    }

    final localIdentity = livekitRoom.localParticipant?.identity;
    if (localIdentity != null) {
      _setStreamsDeafened(localIdentity, state);
    }

    _broadcastVoiceState();
    // LiveKit tells the room right away; the membership is what people
    // outside the call read, so it has to be rewritten too.
    _publishMembershipState();

    _stateChanged.add(());
  }

  @override
  Future<void> setScreenShare(ScreenCaptureSource source) async {
    if (source is WebrtcAndroidScreencaptureSource) {
      livekitRoom.localParticipant?.setScreenShareEnabled(true);
      Log.i("Got android screen capture source!");
      _stateChanged.add(());
      return;
    }

    final srcid = source is WebrtcBrowserScreenCaptureSource
        ? ''
        : (source as WebrtcScreencaptureSource).source.id;

    var bitrate = (preferences.streamBitrate.value * 1_000_000).toInt();
    var framerate = preferences.streamFramerate.value;
    var codec = preferences.streamCodec.value;
    var res = lk.VideoDimensionsPresets.h720_169;

    try {
      var resolution = preferences.streamResolution;
      var parts = resolution.value.split("x");
      res = lk.VideoDimensions(int.parse(parts[0]), int.parse(parts[1]));
    } catch (e, s) {
      Log.onError(e, s, content: "Error calculating desired resolution");
    }

    Log.i(
        "Starting stream with settings: ${preferences.streamBitrate.value}Mbps, ${framerate}FPS, $codec ${res}");

    final encoding =
        lk.VideoEncoding(maxFramerate: framerate.toInt(), maxBitrate: bitrate);

    var captureOptions = lk.ScreenShareCaptureOptions(
      sourceId: srcid,
      maxFrameRate: framerate,
      captureScreenAudio: source.captureAudio,
      params: lk.VideoParameters(
        dimensions: lk.VideoDimensionsPresets.h720_169,
        encoding: encoding,
      ),
    );

    final tracks = source.captureAudio
        ? await lk.LocalVideoTrack.createScreenShareTracksWithAudio(
            captureOptions)
        : [await lk.LocalVideoTrack.createScreenShareTrack(captureOptions)];

    final publishOptions = buildScreenSharePublishOptions(
      codec: codec,
      framerate: framerate.toInt(),
      bitrate: bitrate,
      simulcast: preferences.doSimulcast.value,
      e2ee: room.isE2EE,
    );

    for (final track in tracks) {
      _ownCaptureTrack(track);
      if (track is lk.LocalVideoTrack) {
        await livekitRoom.localParticipant
            ?.publishVideoTrack(track, publishOptions: publishOptions);
      } else if (track is lk.LocalAudioTrack) {
        await livekitRoom.localParticipant?.publishAudioTrack(track);
      }
    }

    _stateChanged.add(());
  }

  @override
  Future<void> setCamera(MediaDeviceInfo? device) async {
    if (isCameraEnabled) {
      Log.e("Tried to enable camera when camera already enabled!");
      return;
    }

    await livekitRoom.localParticipant?.setCameraEnabled(true);
    _stateChanged.add(());
  }

  @override
  Future<void> stopCamera() async {
    await livekitRoom.localParticipant?.setCameraEnabled(false);

    _stateChanged.add(());
  }

  /// Stops every capture track this session owns. This is what releases the
  /// OS capture when LiveKit no longer has a publication to stop — a full
  /// reconnect clears the publication map while the capture keeps running
  /// (issues #63 and #66). Failures are logged, not thrown: the hang up has
  /// to finish either way, and [stopScreenshare] surfaces them through
  /// [_verifyScreenshareStopped]. Stopping a stopped track is a no-op in the
  /// SDK.
  Future<void> _stopOwnedCaptureTracks() async {
    for (final track in _captureTracks) {
      try {
        await track.stop();
      } catch (e, s) {
        Log.onError(e, s, content: "Could not stop a screen capture track");
      }
      // Only a capture that really stopped is refused when republished: a
      // stuck track still captures, and its share has to keep flowing until
      // the user hangs up or reconnects (issue #64).
      if (!track.isActive) {
        _markCaptureStopped(track);
      }
    }
  }

  @override
  Future<void> stopScreenshare() async {
    // Ask LiveKit first: on the normal path it removes the screen share
    // publication (stopping its track) and any screen audio publication the
    // SDK still finds. A failure here must not skip what follows: the SDK
    // walks several platform calls (stop the track, remove every sender,
    // renegotiate), and one of them failing used to leave the capture and the
    // stream running for viewers while the stop reported nothing to do
    // (issue #79).
    try {
      await livekitRoom.localParticipant?.setScreenShareEnabled(false);
    } catch (e, s) {
      Log.onError(e, s,
          content: "Could not remove the screen share through livekit");
    }

    try {
      final screenAudio = livekitRoom.localParticipant
          ?.getTrackPublicationBySource(lk.TrackSource.screenShareAudio);
      if (screenAudio != null) {
        await livekitRoom.localParticipant
            ?.removePublishedTrack(screenAudio.sid);
      }
    } catch (e, s) {
      Log.onError(e, s, content: "Could not remove the screen share audio");
    }

    // Then stop the captures this session created: the SDK call above is a
    // no-op when a full reconnect cleared its publication map, and the OS
    // capture survives that (issue #63). The stop records what actually
    // stopped, so a republish of it is refused below (issue #64).
    await _stopOwnedCaptureTracks();

    // A republish that landed while the stop was still running may have been
    // accepted before its capture was marked stopped, and a publication the
    // SDK failed to remove is still in its map. The stop refuses those now, so
    // one click always ends the share (issues #64 and #79).
    await _refuseStoppedCapturePublications();

    if (PlatformUtils.isAndroid) {
      try {
        await FlutterBackground.disableBackgroundExecution();
      } catch (error) {
        Log.e('error disabling screen share: $error');
      }
    }

    _stateChanged.add(());

    _verifyScreenshareStopped();
  }

  /// Removes every screen-share publication whose capture this session has
  /// stopped, and any that lost its track. A republish arriving while a stop
  /// is still running reaches [onLocalTrackPublished] before the capture is
  /// marked stopped, and a stop whose SDK-side removal failed (the H.265
  /// codec path, issue #79) leaves the publication in the map: the stop cleans
  /// those up itself instead of leaving a dead share to the next click
  /// (issues #64 and #79).
  Future<void> _refuseStoppedCapturePublications() async {
    final participant = livekitRoom.localParticipant;
    if (participant == null) return;

    final refused = participant.trackPublications.values.where((publication) {
      final track = publication.track;
      return ScreenShareWatchList.isScreenShareSource(publication.source) &&
          (track == null || _isStoppedCapture(track));
    }).toList();
    for (final publication in refused) {
      await _refuseRepublishedShare(publication);
    }
  }

  /// A stop is only over once the session can no longer see the share as
  /// live: a screen-share publication still published, or an owned capture
  /// track still active. Reporting success while it is would leave the screen
  /// captured with nothing left to stop it, so this raises instead.
  void _verifyScreenshareStopped() {
    final participant = livekitRoom.localParticipant;
    final stillPublished = const [
      lk.TrackSource.screenShareVideo,
      lk.TrackSource.screenShareAudio,
    ].any((source) => participant?.getTrackPublicationBySource(source) != null);
    final stillCapturing = _hasActiveCapture;
    if (stillPublished || stillCapturing) {
      throw StateError(
          "The screen share could not be stopped: it still looks live");
    }
  }

  @override
  List<VoipStream> streams = List<VoipStream>.empty(growable: true);

  @override
  bool get supportsScreenshare => true;

  @override
  Future<void> updateStats() async {}

  @override
  Future<ScreenCaptureSource?> pickScreenCapture(BuildContext context) async {
    if (PlatformUtils.isAndroid) {
      return WebrtcAndroidScreencaptureSource.getCaptureSource(context);
    }
    if (PlatformUtils.isWeb) {
      return WebrtcBrowserScreenCaptureSource();
    }
    return WebrtcScreencaptureSource.showSelectSourcePrompt(context);
  }

  Future<void> clearRoomCallState() async {
    Log.i("Clearing call state");
    final stateKey =
        "_${room.client.self!.identifier}_${room.matrixRoom.client.deviceID!}_m.call";

    // Registered so a rejoin waits for it: this request can outlive the
    // session, and landing after the next join would erase its membership.
    await CallMembershipWrites.clearing(
        stateKey,
        room.matrixRoom.client.setRoomStateWithKey(room.matrixRoom.id,
            MatrixVoipRoomComponent.callMemberStateEvent, stateKey, {}));

    Log.i("Cleared call state");
  }

  /// How long the server waits for a heartbeat before its delayed leave
  /// clears our membership, and how often we send one. Several heartbeats
  /// fit in one window, so one slow or lost request no longer drops us from
  /// everyone's call list while we are still in the call.
  static const _delayedLeaveTimeout = Duration(seconds: 30);
  static const _heartbeatInterval = Duration(seconds: 10);

  /// The delayed leave the heartbeat restarts. Unlike [heartbeatDelayId],
  /// kept while restarts fail, so the next heartbeat retries it.
  String? _delayedLeaveId;

  /// The heartbeat in progress; a hang up waits for it, so a membership it
  /// restores cannot land after the hang up clears ours.
  Future<void>? _heartbeatInFlight;

  /// Our membership as last seen in the room state, and when we joined, to
  /// write back if the delayed leave cleared it while we were in the call.
  Map<String, Object?>? _lastMembership;
  DateTime? _joinedAt;

  DateTime? _lastMembershipRestore;
  DateTime? _lastExpiryRefresh;

  bool get _leaving => state == VoipState.ended || _hangUp != null;

  Future<void> stopHeartbeat() async {
    heartbeatTimer?.cancel();
    heartbeatTimer = null;

    final delayId = _delayedLeaveId ?? heartbeatDelayId;
    _delayedLeaveId = null;
    heartbeatDelayId = null;
    if (delayId == null) {
      return;
    }

    await room.matrixRoom.client.request(RequestType.POST,
        "/client/unstable/org.matrix.msc4140/delayed_events/${Uri.encodeComponent(delayId)}",
        contentType: "application/json",
        data: jsonEncode({"action": "cancel"}));

    Log.i("Stopped heartbeat");
  }

  Future<void> startHeartbeat() async {
    final capabilities = await room.matrixRoom.client.getVersions();
    Log.d("${capabilities}");
    if (capabilities.unstableFeatures?["org.matrix.msc4140"] != true) {
      Log.e("Homeserver does not support delayed events");
      return;
    }

    await _armDelayedLeave();
    if (_leaving) {
      // Hung up while it was being armed, after the hang up cancelled
      // nothing: left alone it would fire into a rejoin and clear the new
      // membership.
      await stopHeartbeat();
      return;
    }

    heartbeatTimer = Timer.periodic(_heartbeatInterval, (_) {
      if (_heartbeatInFlight != null || _leaving) return;
      final beat = _heartbeat();
      _heartbeatInFlight = beat;
      beat.whenComplete(() => _heartbeatInFlight = null);
    });
  }

  /// Schedules a delayed leave: the server clears our membership once
  /// [_delayedLeaveTimeout] passes without a heartbeat.
  Future<void> _armDelayedLeave() async {
    final result = await room.matrixRoom.client.request(RequestType.PUT,
        "/client/v3/rooms/${Uri.encodeComponent(room.matrixRoom.id)}/state/${Uri.encodeComponent(MatrixVoipRoomComponent.callMemberStateEvent)}/${Uri.encodeComponent(_ownMembershipKey)}",
        contentType: "application/json",
        data: "{}",
        query: {
          "org.matrix.msc4140.delay":
              _delayedLeaveTimeout.inMilliseconds.toString()
        });

    final delayId = result["delay_id"] as String;
    _delayedLeaveId = delayId;
    heartbeatDelayId = delayId;
    _publishMembershipState();
  }

  Future<void> _heartbeat() async {
    final delayId = _delayedLeaveId;
    if (delayId == null) return;

    try {
      try {
        await room.matrixRoom.client.request(RequestType.POST,
            "/client/unstable/org.matrix.msc4140/delayed_events/${Uri.encodeComponent(delayId)}",
            contentType: "application/json",
            data: jsonEncode({"action": "restart"}));
        if (heartbeatDelayId == null) {
          heartbeatDelayId = delayId;
          _publishMembershipState();
        }
      } on MatrixException catch (e) {
        // It fired (a heartbeat came too late) or the server lost it. Either
        // way nothing is left to restart: arm a new one, and put back the
        // membership the old one may have cleared.
        if (e.error != MatrixError.M_NOT_FOUND) rethrow;
        Log.w("Our delayed leave is gone, arming a new one");
        await _armDelayedLeave();
      }

      await _restoreMembershipIfCleared();
      await _refreshMembershipExpiry();
    } catch (e, s) {
      // Stop advertising streams until a heartbeat works again: without the
      // delayed leave, nothing would clear them if this client died.
      Log.onError(e, s, content: "Call membership heartbeat failed");
      if (heartbeatDelayId != null) {
        heartbeatDelayId = null;
        _publishMembershipState();
      }
    }
  }

  /// The delayed leave fires when a heartbeat is missed, and clears our
  /// membership while we are still connected: we would stay in the call
  /// but vanish from everyone's list of who is in it. A delayed leave is
  /// armed again by now, so it is safe to write the membership back.
  Future<void> _restoreMembershipIfCleared() async {
    final current =
        room.matrixRoom.states[MatrixVoipRoomComponent.callMemberStateEvent]
            ?[_ownMembershipKey];
    if (current != null && current.content["application"] != null) {
      _lastMembership = Map.of(current.content);
      _joinedAt ??= MatrixCallMembership.joinedAt(
          current.content, current is Event ? current.originServerTs : null);
      return;
    }

    final membership = _lastMembership;
    if (membership == null || heartbeatDelayId == null || _leaving) return;

    // Our write only shows up in the room state once it comes back over
    // sync: don't write it again in the meantime.
    final now = DateTime.now();
    final last = _lastMembershipRestore;
    if (last != null && now.difference(last) < const Duration(seconds: 30)) {
      return;
    }
    _lastMembershipRestore = now;

    Log.w("Our call membership was cleared while we are in the call, "
        "restoring it");
    await room.matrixRoom.client.setRoomStateWithKey(
      room.matrixRoom.id,
      MatrixVoipRoomComponent.callMemberStateEvent,
      _ownMembershipKey,
      MatrixCallMembership.withPublishedState(membership,
          media: _localLiveMedia,
          voiceState: _localVoiceState,
          joinedAt: _joinedAt ?? now,
          now: now),
    );
  }

  /// A membership's `expires` counts from the join, and only a change to
  /// what we publish or our mute state rewrites it. Push it out well before
  /// it passes, or after four hours in a call every client stops listing us.
  Future<void> _refreshMembershipExpiry() async {
    final current =
        room.matrixRoom.states[MatrixVoipRoomComponent.callMemberStateEvent]
            ?[_ownMembershipKey];
    if (current is! Event || current.content["application"] == null) return;
    final expires = current.content["expires"];
    if (expires is! int) return;

    final now = DateTime.now();
    final joinedAt =
        MatrixCallMembership.joinedAt(current.content, current.originServerTs)!;
    final expiresAt = joinedAt.add(Duration(milliseconds: expires));
    if (expiresAt.difference(now) > const Duration(hours: 1)) return;

    final last = _lastExpiryRefresh;
    if (last != null && now.difference(last) < const Duration(minutes: 5)) {
      return;
    }
    _lastExpiryRefresh = now;

    Log.i("Extending our call membership before it expires");
    await _writeMembershipState(heartbeatDelayId != null
        ? CallMembershipState(media: _localLiveMedia, voice: _localVoiceState)
        : const CallMembershipState());
  }

  @override
  double get generalAudioLevel {
    // Shared screen audio is not someone talking, so it must not light up
    // the call indicator.
    double result = streams
        .where((stream) => stream.type != VoipStreamType.screenshareAudio)
        .fold(0.0, (value, stream) => max(value, stream.audiolevel));
    return result;
  }

  @override
  Stream<void> get onUpdateVolumeVisualizers => _onVolumeChanged.stream;

  Future<void> disconnectCall() async {
    Log.i("Disconnecting livekit room");
    await livekitRoom.disconnect();
    Log.i("Disconnected livekit room");
  }
}
