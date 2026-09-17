import 'dart:async';
import 'dart:convert';

import 'package:commet/client/components/voip/audio_processing/audio_processing_manager.dart';
import 'package:commet/client/components/voip/voip_stream.dart';
import 'package:commet/debug/log.dart';
import 'package:commet/main.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:livekit_client/livekit_client.dart';

/// Sets the playback volume of one WebRTC track.
typedef TrackVolumeSetter = Future<void> Function(
    double volume, MediaStreamTrack track);

typedef AudioVisualizerFactory = AudioVisualizer Function(AudioTrack track);

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

  final TrackVolumeSetter _setTrackVolume;
  final AudioVisualizerFactory _createAudioVisualizer;

  StreamController _onChanged = StreamController.broadcast();

  @override
  Stream<void> get onStreamChanged => _onChanged.stream;

  MatrixLivekitVoipStream(this.publication, this.userId,
      {TrackVolumeSetter? setTrackVolume,
      AudioVisualizerFactory? createAudioVisualizer})
      : _setTrackVolume = setTrackVolume ?? Helper.setVolume,
        _createAudioVisualizer = createAudioVisualizer ?? _speakingVisualizer {
    if (publication.track case AudioTrack t) {
      _setTrackVolume(volume, t.mediaStreamTrack);
      _startVisualizer(t);
    }
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
    if (publication.track case AudioTrack t) {
      _startVisualizer(t);
      _setTrackVolume(_playbackVolume ?? volume, t.mediaStreamTrack);
    }
  }

  /// LiveKit detached the publication's track.
  Future<void> onTrackUnsubscribed() => _stopVisualizer();

  /// Releases what the stream holds. The session calls this once the stream
  /// has left its stream list.
  Future<void> dispose() => _stopVisualizer();

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
    if (publication.track is VideoTrack) {
      return VideoTrackRenderer(publication.track as VideoTrack);
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
  VoipStreamType get type => typeOf(publication.kind, publication.source);

  /// Maps a LiveKit publication's kind and source onto the app's stream
  /// types. System audio captured with a screen share is its own type so the
  /// call grid can fold it into the screen share tile instead of drawing a
  /// second avatar for the sharer.
  static VoipStreamType typeOf(TrackType kind, TrackSource source) {
    if (kind == TrackType.AUDIO) {
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
    if (isScreenShareAudio) {
      preferences.setVoipScreenShareVolume(userId, volume);
    } else {
      preferences.setVoipUserVolume(userId, volume);
    }
    applyVolume(volume);
  }

  /// Sets the playback volume without changing the saved preference. The
  /// session uses this to silence the stream while deafened. A track that
  /// isn't attached yet gets it in [onTrackSubscribed].
  void applyVolume(double volume) {
    _playbackVolume = volume;
    if (publication.track case AudioTrack track) {
      _setTrackVolume(volume, track.mediaStreamTrack);
    }
  }

  @override
  double get volume => isScreenShareAudio
      ? preferences.getVoipScreenShareVolume(userId)
      : preferences.getVoipUserVolume(userId);
}
