import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:collection/collection.dart';
import 'package:commet/client/client.dart';
import 'package:commet/client/components/activities/activities_component.dart';
import 'package:commet/client/components/voip/audio_processing/audio_processing_manager.dart';
import 'package:commet/client/components/voip/voip_session.dart';
import 'package:commet/client/components/voip/voip_stream.dart';
import 'package:commet/client/components/voip/webrtc_screencapture_source.dart';
import 'package:commet/client/components/voip/android_screencapture_source.dart';
import 'package:commet/client/matrix/components/voip_room/live_media_publisher.dart';
import 'package:commet/client/matrix/components/voip_room/matrix_call_membership.dart';
import 'package:commet/client/matrix/components/voip_room/matrix_livekit_encryption_key_provider.dart';
import 'package:commet/client/matrix/components/voip_room/matrix_livekit_voip_stream.dart';
import 'package:commet/client/matrix/components/voip_room/matrix_voip_room_component.dart';
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

class MatrixLivekitVoipSession implements VoipSession {
  MatrixRoom room;
  lk.Room livekitRoom;
  Timer? heartbeatTimer;
  String? heartbeatDelayId;

  MatrixLivekitEncryptionKeyProvider? keyProvider;

  final StreamController<void> _onVolumeChanged = StreamController.broadcast();

  /// Lists what we publish in our call membership, so people outside the
  /// call see our LIVE badge (issue #9).
  late final LiveMediaPublisher _liveMediaPublisher =
      LiveMediaPublisher(write: _writeLiveMedia);

  String get _ownMembershipKey =>
      "_${room.client.self!.identifier}_${room.matrixRoom.client.deviceID!}_m.call";

  MatrixLivekitVoipSession(this.room, this.livekitRoom, {this.keyProvider}) {
    clientManager?.callManager.onClientSessionStarted(this);
    addInitialStreams();

    final listener = livekitRoom.createListener();
    listener.on(onTrackPublished);
    listener.on(onTrackUnpublished);
    listener.on(onTrackSubscribed);
    listener.on(onTrackUnsubscribed);
    listener.on(onLocalTrackPublished);
    listener.on(onLocalTrackUnpublished);
    listener.on(onTrackStreamEvent);
    listener.on(onTrackMutedEvent);
    listener.on(onTrackUnmutedEvent);
    listener.on(onParticipantConnected);
    listener.on(onParticipantDisconnected);
    listener.on(onDataReceived);

    Timer.periodic(Duration(milliseconds: 200), (timer) {
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

    keyProvider?.init(livekitRoom.localParticipant!.identity, livekitRoom);

    startHeartbeat();
  }

  StreamController _stateChanged = StreamController.broadcast();
  final StreamController<VoipState> _onConnectionChanged =
      StreamController.broadcast();

  StreamSubscription? _settingsSub;
  bool _dspNoiseSuppression = false;

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

    final wantWebrtcSuppression = !_dspNoiseSuppression;
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

    for (var entry in livekitRoom.remoteParticipants.entries) {
      for (var stream in entry.value.trackPublications.entries) {
        if (stream.value.kind == lk.TrackType.VIDEO && stream.value.muted) {
          continue;
        }

        String userId = entry.key;
        userId = userId.split(":").getRange(0, 2).join(":");

        final s = MatrixLivekitVoipStream(stream.value, userId);
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
    if (event.publication.track?.mediaType ==
        RTCRtpMediaType.RTCRtpMediaTypeVideo) {
      _removeStreamsWithSid(event.publication.sid);
    }

    for (var track in streams) {
      final t = track as MatrixLivekitVoipStream;
      if (t.publication.sid == event.publication.sid) {
        t.onStreamUpdatedEvent();
      }
    }

    print("Track muted");

    _stateChanged.add(());
    _publishLiveMedia();
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

    if (streams.any((e) => e.streamId == event.publication.sid)) {
      return;
    }

    final s = MatrixLivekitVoipStream(event.publication, participant);
    _applyStreamVolume(s);
    streams.add(s);
    _stateChanged.add(());
    _publishLiveMedia();
  }

  void onTrackPublished(lk.TrackPublishedEvent event) {
    final participant =
        event.participant.identity.split(":").getRange(0, 2).join(":");

    final s = MatrixLivekitVoipStream(event.publication, participant);
    _applyStreamVolume(s);
    s.deafened = _deafenedIdentities.contains(event.participant.identity);
    streams.add(s);
    _stateChanged.add(());
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
  void onTrackSubscribed(lk.TrackSubscribedEvent event) {
    for (final stream in _streamsWithSid(event.publication.sid)) {
      stream.onTrackSubscribed();
      stream.onStreamUpdatedEvent();
    }
    _stateChanged.add(());
  }

  void onTrackUnsubscribed(lk.TrackUnsubscribedEvent event) {
    for (final stream in _streamsWithSid(event.publication.sid)) {
      stream.onTrackUnsubscribed();
    }
  }

  void onParticipantConnected(lk.ParticipantConnectedEvent event) {
    clientManager?.callManager.joinCallSound();
    // Newcomers have no way of knowing we were already deafened.
    if (_isDeafened) {
      _broadcastVoiceState();
    }
  }

  void onParticipantDisconnected(lk.ParticipantDisconnectedEvent event) {
    _deafenedIdentities.remove(event.participant.identity);
    clientManager?.callManager.endCallSound();
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

  void onLocalTrackPublished(lk.LocalTrackPublishedEvent event) {
    final participant =
        event.participant.identity.split(":").getRange(0, 2).join(":");

    final s = MatrixLivekitVoipStream(event.publication, participant);
    s.deafened = _isDeafened;
    streams.add(s);
    _stateChanged.add(());
    _publishLiveMedia();
  }

  void onLocalTrackUnpublished(lk.LocalTrackUnpublishedEvent event) {
    _removeStreamsWithSid(event.publication.sid);

    _stateChanged.add(());
    _publishLiveMedia();
  }

  /// Screen share and camera as LiveKit sees them, which also covers a
  /// capture the OS or the browser ended.
  Set<LiveMedia> get _localLiveMedia => {
        if (isSharingScreen) LiveMedia.screen,
        if (isCameraEnabled) LiveMedia.camera,
      };

  void _publishLiveMedia() {
    if (state == VoipState.ended) return;
    // Only with the delayed leave armed: it is what clears the membership,
    // and the badge with it, if this client crashes while streaming.
    _liveMediaPublisher
        .update(heartbeatDelayId != null ? _localLiveMedia : const {});
  }

  Future<void> _writeLiveMedia(Set<LiveMedia> media) async {
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
      MatrixCallMembership.withLiveMedia(current.content,
          media: media, joinedAt: joinedAt, now: DateTime.now()),
    );
  }

  void onTrackUnpublished(lk.TrackUnpublishedEvent event) {
    _removeStreamsWithSid(event.publication.sid);

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

  @override
  Future<void> hangUpCall() async {
    Log.i("Hanging up call");

    // First, so no membership write lands after the clear below: leaving
    // unpublishes our tracks, which would schedule one.
    await _liveMediaPublisher.stop();

    keyProvider?.dispose();
    _settingsSub?.cancel();
    _settingsSub = null;

    await Future.wait([
      clearRoomCallState(),
      disconnectCall(),
      stopHeartbeat(),
    ]);

    for (final stream in streams.whereType<MatrixLivekitVoipStream>()) {
      stream.dispose();
    }
    streams.clear();

    state = VoipState.ended;
    _stateChanged.add(());
    _onConnectionChanged.add(state);

    clientManager?.callManager.onSessionEnded(this);
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

  @override
  bool get isSharingScreen =>
      livekitRoom.localParticipant?.isScreenShareEnabled() ?? false;

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

    var captureOptions = lk.ScreenShareCaptureOptions(
      sourceId: srcid,
      maxFrameRate: framerate,
      captureScreenAudio: source.captureAudio,
      params: lk.VideoParameters(
        dimensions: lk.VideoDimensionsPresets.h720_169,
        encoding: lk.VideoEncoding(
            maxFramerate: framerate.toInt(), maxBitrate: bitrate),
      ),
    );

    final tracks = source.captureAudio
        ? await lk.LocalVideoTrack.createScreenShareTracksWithAudio(
            captureOptions)
        : [await lk.LocalVideoTrack.createScreenShareTrack(captureOptions)];

    for (final track in tracks) {
      if (track is lk.LocalVideoTrack) {
        await livekitRoom.localParticipant?.publishVideoTrack(track,
            publishOptions: lk.VideoPublishOptions(
              simulcast: preferences.doSimulcast.value,
              screenShareEncoding: lk.VideoEncoding(
                  maxFramerate: framerate.toInt(), maxBitrate: bitrate),
              videoEncoding: lk.VideoEncoding(
                  maxFramerate: framerate.toInt(), maxBitrate: bitrate),
              videoCodec: preferences.streamCodec.value,
            ));
        track.setDegradationPreference(
            lk.DegradationPreference.maintainFramerate);
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

  @override
  Future<void> stopScreenshare() async {
    await livekitRoom.localParticipant?.setScreenShareEnabled(false);
    final screenAudio = livekitRoom.localParticipant
        ?.getTrackPublicationBySource(lk.TrackSource.screenShareAudio);
    if (screenAudio != null) {
      await livekitRoom.localParticipant?.removePublishedTrack(screenAudio.sid);
    }

    if (PlatformUtils.isAndroid) {
      try {
        await FlutterBackground.disableBackgroundExecution();
      } catch (error) {
        Log.e('error disabling screen share: $error');
      }
    }

    _stateChanged.add(());
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

    await room.matrixRoom.client.setRoomStateWithKey(room.matrixRoom.id,
        MatrixVoipRoomComponent.callMemberStateEvent, stateKey, {});

    Log.i("Cleared call state");
  }

  Future<void> stopHeartbeat() async {
    heartbeatTimer?.cancel();
    heartbeatTimer = null;

    if (heartbeatDelayId == null) {
      return;
    }

    await room.matrixRoom.client.request(RequestType.POST,
        "/client/unstable/org.matrix.msc4140/delayed_events/${Uri.encodeComponent(heartbeatDelayId!)}",
        contentType: "application/json",
        data: jsonEncode({"action": "cancel"}));

    heartbeatDelayId = null;
    Log.i("Stopped heartbeat");
  }

  Future<void> startHeartbeat() async {
    final capabilities = await room.matrixRoom.client.getVersions();
    Log.d("${capabilities}");
    if (capabilities.unstableFeatures?["org.matrix.msc4140"] != true) {
      Log.e("Homeserver does not support delayed events");
      return;
    }

    final stateKey =
        "_${room.client.self!.identifier}_${room.matrixRoom.client.deviceID!}_m.call";

    final timerLength = Duration(seconds: 30);

    final result = await room.matrixRoom.client.request(RequestType.PUT,
        "/client/v3/rooms/${Uri.encodeComponent(room.matrixRoom.id)}/state/${Uri.encodeComponent(MatrixVoipRoomComponent.callMemberStateEvent)}/${Uri.encodeComponent(stateKey)}",
        contentType: "application/json",
        data: "{}",
        query: {
          "org.matrix.msc4140.delay": timerLength.inMilliseconds.toString()
        });

    final delayId = result["delay_id"] as String;
    heartbeatDelayId = delayId;
    _publishLiveMedia();

    heartbeatTimer =
        Timer.periodic(timerLength - Duration(seconds: 5), (timer) async {
      print("Sending heartbeat");
      try {
        final result = await room.matrixRoom.client.request(RequestType.POST,
            "/client/unstable/org.matrix.msc4140/delayed_events/${Uri.encodeComponent(delayId)}",
            contentType: "application/json",
            data: jsonEncode({"action": "restart"}));
        print(result);
        if (heartbeatDelayId == null) {
          heartbeatDelayId = delayId;
          _publishLiveMedia();
        }
      } catch (e, s) {
        // The delayed leave may be gone (it already fired, or the server
        // lost it): stop advertising streams until a restart works again.
        Log.onError(e, s, content: "Call membership heartbeat failed");
        if (heartbeatDelayId != null) {
          heartbeatDelayId = null;
          _publishLiveMedia();
        }
      }
    });
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
