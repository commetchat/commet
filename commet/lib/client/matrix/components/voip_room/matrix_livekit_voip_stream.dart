import 'dart:async';
import 'dart:convert';

import 'package:commet/client/components/voip/audio_processing/audio_processing_manager.dart';
import 'package:commet/client/components/voip/voip_stream.dart';
import 'package:commet/client/matrix/components/voip_room/video_stall_detector.dart';
import 'package:commet/client/matrix/components/voip_room/screen_share_watch_list.dart';
import 'package:commet/debug/log.dart';
import 'package:commet/main.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:livekit_client/livekit_client.dart';

/// Sets the playback volume of one audio track.
typedef TrackVolumeSetter = Future<void> Function(
    double volume, AudioTrack track);

typedef AudioVisualizerFactory = AudioVisualizer Function(AudioTrack track);

/// Who decides whether remote screen shares play: the session, which owns
/// the subscriptions (issue #50).
abstract class ScreenShareWatching {
  bool isWatchingScreenShare(String participantIdentity);

  Future<void> setWatchingScreenShare(String participantIdentity, bool watch);
}

class MatrixLivekitVoipStream implements VoipStream {
  TrackPublication publication;
  String userId;

  AudioVisualizer? visualizer;
  EventsListener<AudioVisualizerEvent>? _visualizerListener;
  AudioTrack? _visualizedTrack;

  /// What the listener should hear, from the last [applyVolume]. Kept for
  /// tracks that arrive later: LiveKit announces a remote publication before
  /// it subscribes to it, so the track is often still null here.
  double? _playbackVolume;

  /// Null for streams that always play (tests, local streams).
  final ScreenShareWatching? watching;

  final TrackVolumeSetter _setTrackVolume;
  final AudioVisualizerFactory _createAudioVisualizer;

  StreamController _onChanged = StreamController.broadcast();

  @override
  Stream<void> get onStreamChanged => _onChanged.stream;

  MatrixLivekitVoipStream(this.publication, this.userId,
      {this.watching,
      TrackVolumeSetter? setTrackVolume,
      AudioVisualizerFactory? createAudioVisualizer})
      : _setTrackVolume = setTrackVolume ?? _setPlaybackVolume,
        _createAudioVisualizer = createAudioVisualizer ?? _speakingVisualizer {
    if (publication.track case AudioTrack t) {
      // Our own music is what everyone hears: its level is theirs to set,
      // and on a custom source this volume would change what is sent.
      if (!_isOwnMusic) _setTrackVolume(volume, t);
      if (!_isMusic) _startVisualizer(t);
    }
    if (publication is RemoteTrackPublication &&
        publication.kind == TrackType.VIDEO) {
      _stallTimer = Timer.periodic(_stallCheckInterval, (_) => _checkVideo());
    }
  }

  static const Duration _stallCheckInterval = Duration(seconds: 2);

  /// Watches remote video for a track that never shows a frame. Runs for the
  /// stream's whole life, so it also notices a resubscribe that went nowhere.
  Timer? _stallTimer;
  final VideoStallDetector _stallDetector = VideoStallDetector();
  bool _checkingVideo = false;

  Future<void> _checkVideo() async {
    final pub = publication;
    if (_checkingVideo || pub is! RemoteTrackPublication) return;
    final track = pub.track;

    // Adaptive stream pauses video nobody looks at, so only a track with a
    // renderer on screen is expected to decode frames.
    final watching = track is RemoteVideoTrack &&
        !pub.muted &&
        // ignore: invalid_use_of_internal_member
        track.viewKeys.isNotEmpty;

    _checkingVideo = true;
    try {
      num? framesDecoded;
      if (watching) {
        framesDecoded = (await track.getReceiverStats())?.framesDecoded;
      }
      // The track changed or the stream went away while stats were read.
      if (_stallTimer == null || !identical(pub.track, track)) return;

      switch (_stallDetector.sample(
          watching: watching,
          framesDecoded: framesDecoded,
          now: DateTime.now())) {
        case VideoStallAction.none:
          break;
        case VideoStallAction.firstFrame:
          onStreamUpdatedEvent();
        case VideoStallAction.recover:
          // Not a share the user just stopped watching, nor a stream that is
          // gone: resubscribing waits a moment before it subscribes.
          bool stillWanted() => _stallTimer != null && isWatching;
          if (!stillWanted()) break;
          Log.w("Remote video ${pub.sid} decoded no frames, subscribing again "
              "(attempt ${_stallDetector.recoveries})");
          await pub.resubscribe(stillWanted: stillWanted);
      }
    } catch (e, s) {
      Log.onError(e, s, content: "Could not check remote video ${pub.sid}");
    } finally {
      _checkingVideo = false;
    }
  }

  /// On web, [Helper.setVolume] only puts a volume constraint on the track,
  /// which browsers ignore. Remote audio plays through LiveKit's audio
  /// elements there, so the volume goes on the element instead.
  static Future<void> _setPlaybackVolume(
      double volume, AudioTrack track) async {
    if (kIsWeb) {
      if (track is RemoteAudioTrack) track.setVolume(volume);
      return;
    }
    await Helper.setVolume(volume, track.mediaStreamTrack);
  }

  static AudioVisualizer _speakingVisualizer(AudioTrack track) =>
      // Several bands so the loudest one can be picked: a single band averages
      // the whole spectrum and buries quiet speech under the empty highs.
      createVisualizer(track,
          options: AudioVisualizerOptions(
              barCount: 7, centeredBands: false, smoothTransition: false));

  void _startVisualizer(AudioTrack track) {
    if (identical(_visualizedTrack, track)) return;
    _stopVisualizer();

    final visualizer = _createAudioVisualizer(track);
    _visualizerListener = visualizer.createListener()
      ..on<AudioVisualizerEvent>(setAudioLevel);
    this.visualizer = visualizer;
    _visualizedTrack = track;
    visualizer.start();
  }

  Future<void> _stopVisualizer() async {
    final visualizer = this.visualizer;
    final listener = _visualizerListener;
    this.visualizer = null;
    _visualizerListener = null;
    _visualizedTrack = null;
    if (visualizer == null) return;

    try {
      await listener?.dispose();
      await visualizer.stop();
      await visualizer.dispose();
    } catch (e, s) {
      Log.onError(e, s, content: "Could not stop an audio visualizer");
    }
  }

  /// LiveKit attached the publication's track: listen to it and give it the
  /// playback volume chosen so far.
  void onTrackSubscribed() {
    if (publication.track is VideoTrack) {
      _stallDetector.trackChanged();
    }
    if (publication.track case AudioTrack t) {
      if (!_isMusic) _startVisualizer(t);
      if (!_isOwnMusic) _setTrackVolume(_playbackVolume ?? volume, t);
    }
  }

  /// Music has no speaking indicator, so no level analyser either.
  bool get _isMusic => type == VoipStreamType.music;

  bool get _isOwnMusic => _isMusic && publication is LocalTrackPublication;

  /// LiveKit detached the publication's track.
  Future<void> onTrackUnsubscribed() => _stopVisualizer();

  /// Releases what the stream holds. The session calls this once the stream
  /// has left its stream list.
  Future<void> dispose() async {
    _stallTimer?.cancel();
    _stallTimer = null;
    await _stopVisualizer();
    await _onChanged.close();
  }

  // Loudest visualizer band (0..1, dB scaled so -100 dB is 0) above which a
  // frame counts as audio. Quiet speech (-50 dBFS) lands near 0.47; a mic
  // behind a closed input gate (-40 dB floor) stays under 0.35 even when
  // shouting, so only audio that was really sent lights the indicator.
  static const double _audioThreshold = 0.4;

  // Keep reporting "speaking" this long after the last audio, so the
  // indicator stays lit across the gaps between syllables instead of
  // flickering.
  static const Duration _speakingHold = Duration(milliseconds: 400);

  DateTime? _lastAudioAt;

  bool get _isLocalMic =>
      publication is LocalTrackPublication &&
      publication.source == TrackSource.microphone;

  @override
  double get audiolevel {
    if (isMuted) return 0;

    // For our own mic the visualizer taps the audio before the input gate,
    // so it would light up for audio that never leaves the client. When the
    // DSP is running, its gate is what decides.
    final dsp = AudioProcessingManager.instance;
    final last =
        _isLocalMic && dsp.isProcessing ? dsp.lastGateOpenAt : _lastAudioAt;
    if (last != null && DateTime.now().difference(last) < _speakingHold) {
      return 1;
    }

    // LiveKit's server side speaker detection works from the audio level of
    // what was actually sent, including our own mic.
    if (publication.source == TrackSource.microphone &&
        publication.participant.isSpeaking) {
      return 1;
    }

    return 0;
  }

  void setAudioLevel(AudioVisualizerEvent e) {
    var peak = 0.0;
    for (final band in e.event) {
      final v = (band as num).toDouble();
      if (v > peak) peak = v;
    }
    if (peak > _audioThreshold) {
      _lastAudioAt = DateTime.now();
    }
  }

  void onStreamUpdatedEvent() {
    _onChanged.add(());
  }

  @override
  double? get aspectRatio {
    if (publication.dimensions == null) {
      return null;
    }
    return publication.dimensions!.width.toDouble() /
        publication.dimensions!.height.toDouble();
  }

  @override
  Widget? buildVideoRenderer(BoxFit fit, Key key) {
    if (publication.track case VideoTrack track) {
      // Keyed by the track so a resubscribed track gets a fresh renderer
      // instead of one still bound to the old media stream.
      return VideoTrackRenderer(track, key: ObjectKey(track));
    }

    return null;
  }

  @override
  VoipStreamDirection get direction => publication is LocalTrackPublication
      ? VoipStreamDirection.outgoing
      : VoipStreamDirection.incoming;

  @override
  String get label => "label";

  @override
  String get streamId => publication.sid;

  @override
  String get streamUserId => userId;

  @override
  String get streamOwnerId => publication.participant.identity;

  @override
  VoipStreamType get type =>
      typeOf(publication.kind, publication.source, name: publication.name);

  /// Name the DJ booth publishes its music under (the track source says
  /// nothing: LiveKit has no source for it).
  static const musicTrackName = 'commet-dj-music';

  /// Maps a LiveKit publication's kind and source onto the app's stream
  /// types. System audio captured with a screen share is its own type so the
  /// call grid can fold it into the screen share tile instead of drawing a
  /// second avatar for the sharer.
  static VoipStreamType typeOf(TrackType kind, TrackSource source,
      {String? name}) {
    if (kind == TrackType.AUDIO) {
      if (name == musicTrackName) return VoipStreamType.music;
      return source == TrackSource.screenShareAudio
          ? VoipStreamType.screenshareAudio
          : VoipStreamType.audio;
    }

    if (source == TrackSource.screenShareVideo) {
      return VoipStreamType.screenshare;
    }

    return VoipStreamType.video;
  }

  bool get isScreenShareAudio => type == VoipStreamType.screenshareAudio;

  @override
  bool get isMuted => publication.track?.muted ?? false;

  /// Set by the owning session from the deafen broadcast (remote) or the
  /// local deafen toggle (outgoing streams). LiveKit has no notion of
  /// "deafened", it only sees a muted mic.
  bool deafened = false;

  @override
  bool get isDeafened => deafened;

  @override
  // TODO: implement stats
  String get stats => JsonEncoder.withIndent("  ").convert({
        "is encrypted": publication.participant.isEncrypted,
        "encryption type": publication.encryptionType.toString(),
      });

  @override
  Future<void> setVolume(double volume) async {
    if (type == VoipStreamType.music) {
      await preferences.djMusicVolume.set(volume);
    } else if (isScreenShareAudio) {
      preferences.setVoipScreenShareVolume(userId, volume);
    } else {
      preferences.setVoipUserVolume(userId, volume);
    }
    applyVolume(listenerDeafened ? 0.0 : volume);
    // Other controls showing this volume (tile overlay, context menu,
    // fullscreen) follow.
    onStreamUpdatedEvent();
  }

  /// Whether the local user is deafened. Set by the owning session, so a
  /// volume change made while deafened is saved but stays silent.
  bool listenerDeafened = false;

  /// Sets the playback volume without changing the saved preference. The
  /// session uses this to silence the stream while deafened. A track that
  /// isn't attached yet gets it in [onTrackSubscribed].
  void applyVolume(double volume) {
    _playbackVolume = volume;
    if (_isOwnMusic) return;
    if (publication.track case AudioTrack track) {
      _setTrackVolume(volume, track);
    }
  }

  @override
  bool get requiresWatching =>
      watching != null &&
      direction == VoipStreamDirection.incoming &&
      ScreenShareWatchList.isScreenShareSource(publication.source);

  @override
  bool get isWatching =>
      !requiresWatching ||
      watching!.isWatchingScreenShare(publication.participant.identity);

  @override
  Future<void> watch() async {
    if (!requiresWatching) return;
    await watching!
        .setWatchingScreenShare(publication.participant.identity, true);
  }

  @override
  Future<void> stopWatching() async {
    if (!requiresWatching) return;
    await watching!
        .setWatchingScreenShare(publication.participant.identity, false);
  }

  @override
  double get volume => type == VoipStreamType.music
      ? preferences.djMusicVolume.value
      : isScreenShareAudio
          ? preferences.getVoipScreenShareVolume(userId)
          : preferences.getVoipUserVolume(userId);
}
