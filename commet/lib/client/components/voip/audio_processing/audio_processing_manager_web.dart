import 'dart:async';
import 'dart:js_interop';

import 'package:commet/client/components/voip/audio_processing/audio_dsp_settings.dart';
import 'package:commet/client/components/voip/audio_processing/audio_processing_manager.dart';
import 'package:commet/client/components/voip/audio_processing/noise_suppression_notice.dart';
import 'package:commet/client/components/voip/voip_session.dart';
import 'package:commet/client/matrix/components/voip_room/matrix_livekit_voip_session.dart';
import 'package:commet/client/matrix/components/voip_room/matrix_livekit_voip_stream.dart';
import 'package:commet/debug/log.dart';
// ignore: depend_on_referenced_packages
import 'package:dart_webrtc/dart_webrtc.dart'
    show MediaStreamTrackWeb, MediaStreamWeb;
import 'package:flutter_webrtc/flutter_webrtc.dart'
    show MediaStream, MediaStreamTrack;
import 'package:livekit_client/livekit_client.dart' as lk;
import 'package:web/web.dart' as web;

AudioProcessingManager createAudioProcessingManager() =>
    WebAudioProcessingManager();

// Bindings to window.commetAudioDsp, defined in web/audio_dsp.js.
@JS('commetAudioDsp')
external _CommetAudioDsp? get _commetAudioDsp;

extension type _CommetAudioDsp._(JSObject _) implements JSObject {
  external bool get isSupported;
  external JSPromise<_Probe> probe();
  external JSPromise<_DspGraph> create(
      web.MediaStreamTrack track, JSAny? params);
}

extension type _Probe._(JSObject _) implements JSObject {
  external bool get ok;
  external String get reason;
}

extension type _DspGraph._(JSObject _) implements JSObject {
  external web.MediaStreamTrack get processedTrack;
  external String get state;
  external JSPromise<JSBoolean> get ready;
  external void setParams(JSAny? params);
  external void addFarEnd(web.MediaStreamTrack track);
  external void removeFarEnd(web.MediaStreamTrack track);
  external void setMonitor(bool enabled);
  external JSPromise<JSAny?> resume();
  external JSPromise<JSAny?> destroy();
  external set onReport(JSFunction? f);
  external set onError(JSFunction? f);
}

/// Browser: the DSP runs in an AudioWorklet (web/audio_dsp.worklet.js) fed by
/// the raw microphone track; LiveKit publishes the worklet's output.
///
/// The microphone test builds the same graph from a `getUserMedia` track
/// and, when monitoring, connects the worklet to the speakers.
class WebAudioProcessingManager extends AudioProcessingManager {
  CommetWebTrackProcessor? _current;
  lk.EventsListener<lk.RoomEvent>? _roomListener;
  lk.Room? _room;
  VoipSession? _roomSession;

  _DspGraph? _testGraph;
  web.MediaStream? _testStream;
  bool _monitor = false;
  Future<void> _testOps = Future.value();

  WebAudioProcessingManager() {
    // Early, so the settings page and the first call rarely wait for it.
    ensureReady();
  }

  /// What window.commetAudioDsp.probe() found: null until it answered.
  bool? _probeOk;
  String? _unavailableReason;
  Future<bool>? _probing;

  @override
  bool get isSupported =>
      (_commetAudioDsp?.isSupported ?? false) && _probeOk != false;

  @override
  String? get unavailableReason {
    if (_commetAudioDsp == null) return "audio_dsp.js did not load";
    return _probeOk == false ? _unavailableReason : null;
  }

  @override
  Future<bool> ensureReady() {
    final api = _commetAudioDsp;
    if (api == null) return Future.value(false);
    if (_probeOk == true) return Future.value(true);
    return _probing ??= () async {
      try {
        final result = await api.probe().toDart;
        _probeOk = result.ok;
        _unavailableReason = result.ok ? null : result.reason;
      } catch (e) {
        _probeOk = false;
        _unavailableReason = "$e";
      } finally {
        _probing = null;
      }
      if (_probeOk != true) {
        Log.w("Voice DSP: cannot run in this browser: $_unavailableReason");
      }
      notifyStateChanged();
      return _probeOk == true;
    }();
  }

  /// A graph failed to start although the probe passed. Until a new probe
  /// says otherwise, calls keep the browser's suppressor on.
  void _graphFailed(String reason) {
    _probeOk = false;
    _unavailableReason = reason;
    warnNoiseSuppressionUnavailable(reason);
    notifyStateChanged();
  }

  @override
  bool get isActive =>
      _current?.graph != null || _testGraph != null || _streamGraphs.isNotEmpty;

  @override
  bool get isTesting => _testGraph != null;

  @override
  bool get micTestMonitor => _monitor;

  @override
  lk.TrackProcessor<lk.AudioProcessorOptions>? createTrackProcessor() {
    if (!isSupported) return null;
    _current = CommetWebTrackProcessor(this);
    return _current;
  }

  @override
  Future<void> onSessionStarted(VoipSession session) async {
    if (isTesting) {
      Log.i("Voice DSP: stopping the microphone test, a call started");
      await stopMicTest();
    }
    addSession(session);
    if (session is MatrixLivekitVoipSession) {
      _attachRoom(session.livekitRoom);
      _roomSession = session;
    }
    notifyStateChanged();
  }

  @override
  Future<void> onSessionEnded(VoipSession session) async {
    if (!removeSession(session)) return;
    if (session == _roomSession) {
      _roomSession = null;
      _detachRoom();
    }
    if (!isInCall) await _destroyStreamGraphs();
    notifyStateChanged();
  }

  @override
  Future<void> applySettings(AudioDspSettings settings) async {
    final params = settings.toMap().jsify();
    _current?.graph?.setParams(params);
    _testGraph?.setParams(params);
    for (final s in _streamGraphs) {
      s.graph.setParams(params);
    }
  }

  /// Legacy 1:1 calls' microphones (processMicrophoneStream), with the raw
  /// capture each one reads: until the calls end.
  final List<({_DspGraph graph, web.MediaStreamTrack raw})> _streamGraphs = [];

  @override
  Future<MediaStream?> processMicrophoneStream(MediaStream stream) async {
    final api = _commetAudioDsp;
    final audio = stream.getAudioTracks().firstOrNull;
    if (api == null || audio is! MediaStreamTrackWeb) return null;
    try {
      final g =
          await api.create(audio.jsTrack, settings.toMap().jsify()).toDart;
      g.onReport = ((JSObject r) {
        publishReport(_reportFromJs(r));
      }).toJS;
      g.onError = ((JSString message) {
        Log.e("Voice DSP worklet error: ${message.toDart}");
      }).toJS;
      _streamGraphs.add((graph: g, raw: audio.jsTrack));
      final tracks = <web.MediaStreamTrack>[
        g.processedTrack,
        for (final video in stream.getVideoTracks())
          if (video is MediaStreamTrackWeb) video.jsTrack,
      ];
      Log.i("Voice DSP: AudioWorklet graph running for a 1:1 call");
      notifyStateChanged();
      return MediaStreamWeb(web.MediaStream(tracks.toJS), 'local');
    } catch (e, s) {
      Log.onError(e, s, content: "Voice DSP: failed to build the audio graph");
      _graphFailed("$e");
      return null;
    }
  }

  Future<void> _destroyStreamGraphs() async {
    final graphs = [..._streamGraphs];
    _streamGraphs.clear();
    for (final s in graphs) {
      // The call stops the processed track it was given; the microphone
      // behind it is ours to close.
      s.raw.stop();
      try {
        await s.graph.destroy().toDart;
      } catch (e, st) {
        Log.onError(e, st, content: "Voice DSP: error tearing down graph");
      }
    }
  }

  @override
  Future<void> onNoiseSuppressionChanged(bool enabled) async {
    // The browser suppressor is a getUserMedia constraint: restart the test
    // capture so what the user hears matches the setting.
    if (!isTesting) return;
    _testOps = _testOps.then((_) async {
      if (!isTesting) return;
      await _destroyTest();
      await _createTest();
      notifyStateChanged();
    });
    await _testOps;
  }

  @override
  Future<bool> startMicTest() async {
    if (!isSupported || isInCall) return false;
    if (isTesting) return true;
    var started = false;
    _testOps = _testOps.then((_) async {
      if (isInCall || isTesting) return;
      started = await _createTest();
      notifyStateChanged();
    });
    await _testOps;
    return started;
  }

  @override
  Future<void> stopMicTest() async {
    _testOps = _testOps.then((_) async {
      if (!isTesting) return;
      await _destroyTest();
      Log.i("Voice DSP: microphone test stopped");
      notifyStateChanged();
    });
    await _testOps;
  }

  @override
  Future<void> setMicTestMonitor(bool enabled) async {
    _monitor = enabled;
    _testGraph?.setMonitor(enabled);
    notifyStateChanged();
  }

  Future<bool> _createTest() async {
    final api = _commetAudioDsp;
    if (api == null) return false;
    try {
      // Same constraints as a call: the browser suppressor only when ours
      // is off.
      final constraints = web.MediaStreamConstraints(
        audio: {
          'echoCancellation': true,
          'noiseSuppression': !settings.noiseSuppression,
          'autoGainControl': true,
        }.jsify()!,
      );
      final stream = await web.window.navigator.mediaDevices
          .getUserMedia(constraints)
          .toDart;
      final tracks = stream.getAudioTracks().toDart;
      if (tracks.isEmpty) {
        Log.w("Voice DSP: microphone test got no audio track");
        return false;
      }
      _testStream = stream;
      final g = await api.create(tracks.first, settings.toMap().jsify()).toDart;
      g.onReport = ((JSObject r) {
        publishReport(_reportFromJs(r));
      }).toJS;
      g.onError = ((JSString message) {
        Log.e("Voice DSP worklet error: ${message.toDart}");
      }).toJS;
      _testGraph = g;
      g.setMonitor(_monitor);
      if (g.state != "running") {
        await g.resume().toDart;
      }
      final ready = (await g.ready.toDart).toDart;
      if (!ready) {
        Log.e("Voice DSP: worklet failed to start for the microphone test");
        await _destroyTest();
        return false;
      }
      Log.i("Voice DSP: microphone test running");
      return true;
    } catch (e, s) {
      Log.onError(e, s, content: "Voice DSP: microphone test failed to start");
      await _destroyTest();
      return false;
    }
  }

  Future<void> _destroyTest() async {
    final g = _testGraph;
    _testGraph = null;
    if (g != null) {
      try {
        await g.destroy().toDart;
      } catch (e, s) {
        Log.onError(e, s, content: "Voice DSP: error tearing down test graph");
      }
    }
    final stream = _testStream;
    _testStream = null;
    if (stream != null) {
      for (final track in stream.getTracks().toDart) {
        track.stop();
      }
    }
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
        // The DJ booth's music plays without a break: as far-end it would
        // keep the ducker on for as long as the music lasts, whatever the
        // listener set its volume to. The browser's echo canceller has it.
        if (pub.name == MatrixLivekitVoipStream.musicTrackName) continue;
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
    notifyStateChanged();
  }

  void onGraphDestroyed(CommetWebTrackProcessor processor) {
    if (processor == _current) {
      _farEndTracks.clear();
    }
    notifyStateChanged();
  }
}

AudioDspReport _reportFromJs(JSObject r) {
  final m = r.dartify() as Map;
  return AudioDspReport(
    levelDb: (m["levelDb"] as num).toDouble(),
    vad: (m["vad"] as num).toDouble(),
    farLevelDb: (m["farLevelDb"] as num).toDouble(),
    gainDb: (m["gainDb"] as num).toDouble(),
    sampleRate: (m["sampleRate"] as num).toInt(),
    frames: (m["frames"] as num).toInt(),
    flags: (m["flags"] as num).toInt(),
  );
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
        manager.publishReport(_reportFromJs(r));
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

      manager.onGraphReady(this);
      Log.i("Voice DSP: AudioWorklet graph running (${g.state})");
    } catch (e, s) {
      graph = null;
      _processedTrack = null;
      // The capture ended before the graph was built (a restart racing a
      // device that went away): nothing is wrong with the DSP, and the
      // microphone watch opens a new capture.
      if ("$e".contains("CaptureEnded")) {
        Log.w("Voice DSP: the microphone ended before its graph was built");
        return;
      }
      // No processed track: LiveKit sends the raw microphone, whose browser
      // suppressor was turned off for ours. The session's next update puts
      // it back once the manager says the DSP cannot run.
      Log.onError(e, s, content: "Voice DSP: failed to build the audio graph");
      manager._graphFailed("$e");
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
