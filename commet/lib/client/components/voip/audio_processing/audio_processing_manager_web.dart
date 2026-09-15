import 'dart:async';
import 'dart:js_interop';

import 'package:commet/client/components/voip/audio_processing/audio_dsp_settings.dart';
import 'package:commet/client/components/voip/audio_processing/audio_processing_manager.dart';
import 'package:commet/client/components/voip/voip_session.dart';
import 'package:commet/client/matrix/components/voip_room/matrix_livekit_voip_session.dart';
import 'package:commet/debug/log.dart';
// ignore: depend_on_referenced_packages
import 'package:dart_webrtc/dart_webrtc.dart' show MediaStreamTrackWeb;
import 'package:flutter_webrtc/flutter_webrtc.dart' show MediaStreamTrack;
import 'package:livekit_client/livekit_client.dart' as lk;
import 'package:web/web.dart' as web;

AudioProcessingManager createAudioProcessingManager() =>
    WebAudioProcessingManager();

// Bindings to window.commetAudioDsp, defined in web/audio_dsp.js.
@JS('commetAudioDsp')
external _CommetAudioDsp? get _commetAudioDsp;

extension type _CommetAudioDsp._(JSObject _) implements JSObject {
  external bool get isSupported;
  external JSPromise<_DspGraph> create(web.MediaStreamTrack track, JSAny? params);
}

extension type _DspGraph._(JSObject _) implements JSObject {
  external web.MediaStreamTrack get processedTrack;
  external String get state;
  external JSPromise<JSBoolean> get ready;
  external void setParams(JSAny? params);
  external void addFarEnd(web.MediaStreamTrack track);
  external void removeFarEnd(web.MediaStreamTrack track);
  external JSPromise<JSAny?> resume();
  external JSPromise<JSAny?> destroy();
  external set onReport(JSFunction? f);
  external set onError(JSFunction? f);
}

/// Browser: the DSP runs in an AudioWorklet (web/audio_dsp.worklet.js) fed by
/// the raw microphone track; LiveKit publishes the worklet's output.
class WebAudioProcessingManager extends AudioProcessingManager {
  CommetWebTrackProcessor? _current;
  lk.EventsListener<lk.RoomEvent>? _roomListener;
  lk.Room? _room;

  @override
  bool get isSupported => _commetAudioDsp?.isSupported ?? false;

  @override
  bool get isActive => _current?.graph != null;

  @override
  lk.TrackProcessor<lk.AudioProcessorOptions>? createTrackProcessor() {
    if (!isSupported) return null;
    _current = CommetWebTrackProcessor(this);
    return _current;
  }

  @override
  Future<void> onSessionStarted(VoipSession session) async {
    if (session is! MatrixLivekitVoipSession) return;
    _attachRoom(session.livekitRoom);
  }

  @override
  Future<void> onSessionEnded() async {
    _detachRoom();
  }

  @override
  Future<void> applySettings(AudioDspSettings settings) async {
    _current?.graph?.setParams(settings.toMap().jsify());
  }

  // Far-end level for ducking: every remote audio track is also fed into the
  // worklet's second input (measurement only, LiveKit keeps playing it).
  void _attachRoom(lk.Room room) {
    _detachRoom();
    _room = room;
    final listener = room.createListener();
    listener.on<lk.TrackSubscribedEvent>((e) => _farEndChanged());
    listener.on<lk.TrackUnsubscribedEvent>((e) => _farEndChanged());
    _roomListener = listener;
    _farEndChanged();
  }

  void _detachRoom() {
    _roomListener?.dispose();
    _roomListener = null;
    _room = null;
  }

  final Map<String, web.MediaStreamTrack> _farEndTracks = {};

  void _farEndChanged() {
    final graph = _current?.graph;
    final room = _room;
    if (graph == null || room == null) return;

    final wanted = <String, web.MediaStreamTrack>{};
    for (final participant in room.remoteParticipants.values) {
      for (final pub in participant.audioTrackPublications) {
        final track = pub.track?.mediaStreamTrack;
        if (track is MediaStreamTrackWeb) {
          wanted[track.jsTrack.id] = track.jsTrack;
        }
      }
    }

    for (final entry in _farEndTracks.entries.toList()) {
      if (!wanted.containsKey(entry.key)) {
        graph.removeFarEnd(entry.value);
        _farEndTracks.remove(entry.key);
      }
    }
    for (final entry in wanted.entries) {
      if (!_farEndTracks.containsKey(entry.key)) {
        graph.addFarEnd(entry.value);
        _farEndTracks[entry.key] = entry.value;
      }
    }
  }

  void onGraphReady(CommetWebTrackProcessor processor) {
    if (processor != _current) return;
    _farEndTracks.clear();
    _farEndChanged();
  }

  void onGraphDestroyed(CommetWebTrackProcessor processor) {
    if (processor == _current) {
      _farEndTracks.clear();
    }
  }
}

/// LiveKit track processor wrapping the Web Audio graph.
class CommetWebTrackProcessor
    implements lk.TrackProcessor<lk.AudioProcessorOptions> {
  final WebAudioProcessingManager manager;
  _DspGraph? graph;
  MediaStreamTrackWeb? _processedTrack;

  CommetWebTrackProcessor(this.manager);

  @override
  String get name => "commet-dsp";

  @override
  MediaStreamTrack? get processedTrack => _processedTrack;

  @override
  Future<void> init(lk.AudioProcessorOptions options) async {
    final api = _commetAudioDsp;
    final track = options.track;
    if (api == null || track is! MediaStreamTrackWeb) {
      Log.w("Voice DSP: browser glue missing, publishing the raw microphone");
      return;
    }

    try {
      final g = await api
          .create(track.jsTrack, manager.settings.toMap().jsify())
          .toDart;
      g.onReport = ((JSObject r) {
        final m = r.dartify() as Map;
        manager.publishReport(AudioDspReport(
          levelDb: (m["levelDb"] as num).toDouble(),
          vad: (m["vad"] as num).toDouble(),
          farLevelDb: (m["farLevelDb"] as num).toDouble(),
          gainDb: (m["gainDb"] as num).toDouble(),
          sampleRate: (m["sampleRate"] as num).toInt(),
          frames: (m["frames"] as num).toInt(),
          flags: (m["flags"] as num).toInt(),
        ));
      }).toJS;
      g.onError = ((JSString message) {
        Log.e("Voice DSP worklet error: ${message.toDart}");
      }).toJS;

      graph = g;
      _processedTrack = MediaStreamTrackWeb(g.processedTrack);

      if (g.state != "running") {
        Log.w("Voice DSP: AudioContext is '${g.state}', trying to resume");
        await g.resume().toDart;
      }

      final ready = (await g.ready.toDart).toDart;
      if (!ready) {
        Log.e("Voice DSP: worklet failed to start, audio passes through");
      }
      manager.onGraphReady(this);
      Log.i("Voice DSP: AudioWorklet graph running (${g.state})");
    } catch (e, s) {
      Log.onError(e, s, content: "Voice DSP: failed to build the audio graph");
      graph = null;
      _processedTrack = null;
    }
  }

  @override
  Future<void> restart(lk.AudioProcessorOptions options) async {
    await destroy();
    await init(options);
  }

  @override
  Future<void> destroy() async {
    final g = graph;
    graph = null;
    _processedTrack = null;
    manager.onGraphDestroyed(this);
    if (g != null) {
      try {
        await g.destroy().toDart;
      } catch (e, s) {
        Log.onError(e, s, content: "Voice DSP: error tearing down graph");
      }
    }
  }

  @override
  Future<void> onPublish(lk.Room room) async {}

  @override
  Future<void> onUnpublish() async {}
}
