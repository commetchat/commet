import 'dart:async';
import 'dart:ffi';

import 'package:commet/client/components/voip/audio_processing/audio_dsp_settings.dart';
import 'package:commet/client/components/voip/audio_processing/audio_processing_manager.dart';
import 'package:commet/client/components/voip/audio_processing/audio_processing_manager_stub.dart'
    show UnsupportedAudioProcessingManager;
import 'package:commet/client/components/voip/voip_session.dart';
import 'package:commet/client/components/voip/webrtc_default_devices.dart';
import 'package:commet/config/platform_utils.dart';
import 'package:commet/config/rust_library.dart';
import 'package:commet/debug/log.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart' as webrtc;
import 'package:livekit_client/livekit_client.dart' as lk;

AudioProcessingManager createAudioProcessingManager() {
  if (PlatformUtils.isLinux || PlatformUtils.isWindows) {
    return NativeAudioProcessingManager();
  }
  // Android: librust_lib_commet is not built for it yet (cargokit is disabled
  // in rust/rust_builder/android/build.gradle), so there is nothing to load.
  return UnsupportedAudioProcessingManager();
}

/// Mirrors `audio_dsp::Params` (24 bytes).
final class DspParams extends Struct {
  @Uint8()
  external int noiseSuppression;
  @Uint8()
  external int gateMode;
  @Uint8()
  external int farEndDucking;

  /// Close the gate on loudspeaker bleed. Was padding before ABI 2.
  @Uint8()
  external int speakerBleed;
  @Float()
  external double inputScale;
  @Float()
  external double gateThresholdDb;
  @Float()
  external double gateFloorDb;
  @Float()
  external double duckDepthDb;
  @Float()
  external double duckFarThresholdDb;
}

/// Mirrors `audio_dsp::Report` (28 bytes).
final class DspReport extends Struct {
  @Float()
  external double levelDb;
  @Float()
  external double vad;
  @Float()
  external double farLevelDb;
  @Float()
  external double gainDb;
  @Int32()
  external int sampleRate;
  @Uint32()
  external int frames;
  @Uint32()
  external int flags;
}

typedef _InitNative = Void Function(Pointer<Void>, Int32, Int32);
typedef _ProcessNative = Void Function(
    Pointer<Void>, Int32, Int32, Int32, Pointer<Float>);
typedef _ResetNative = Void Function(Pointer<Void>, Int32);
typedef _FeedReferenceNative = Void Function(
    Pointer<Void>, Pointer<Int16>, Size, Size, Int32);

class _Bindings {
  final DynamicLibrary lib;
  _Bindings(this.lib);

  static const expectedAbi = 2;

  late final int Function() abiVersion =
      lib.lookupFunction<Uint32 Function(), int Function()>(
          'commet_dsp_abi_version');

  late final int Function() paramsSize =
      lib.lookupFunction<UintPtr Function(), int Function()>(
          'commet_dsp_params_size');

  late final int Function() reportSize =
      lib.lookupFunction<UintPtr Function(), int Function()>(
          'commet_dsp_report_size');

  late final Pointer<Void> Function(Pointer<DspParams>) create =
      lib.lookupFunction<Pointer<Void> Function(Pointer<DspParams>),
          Pointer<Void> Function(Pointer<DspParams>)>('commet_dsp_create');

  late final void Function(Pointer<Void>) destroy = lib.lookupFunction<
      Void Function(Pointer<Void>),
      void Function(Pointer<Void>)>('commet_dsp_destroy');

  late final void Function(Pointer<Void>, Pointer<DspParams>) setParams =
      lib.lookupFunction<
          Void Function(Pointer<Void>, Pointer<DspParams>),
          void Function(
              Pointer<Void>, Pointer<DspParams>)>('commet_dsp_set_params');

  late final void Function(Pointer<Void>, Pointer<DspReport>) getReport =
      lib.lookupFunction<
          Void Function(Pointer<Void>, Pointer<DspReport>),
          void Function(
              Pointer<Void>, Pointer<DspReport>)>('commet_dsp_get_report');

  late final Pointer<DspParams> Function() paramsAlloc = lib.lookupFunction<
      Pointer<DspParams> Function(),
      Pointer<DspParams> Function()>('commet_dsp_params_alloc');

  late final void Function(Pointer<DspParams>) paramsFree = lib.lookupFunction<
      Void Function(Pointer<DspParams>),
      void Function(Pointer<DspParams>)>('commet_dsp_params_free');

  late final Pointer<DspReport> Function() reportAlloc = lib.lookupFunction<
      Pointer<DspReport> Function(),
      Pointer<DspReport> Function()>('commet_dsp_report_alloc');

  late final void Function(Pointer<DspReport>) reportFree = lib.lookupFunction<
      Void Function(Pointer<DspReport>),
      void Function(Pointer<DspReport>)>('commet_dsp_report_free');

  // Addresses of the CustomProcessing shaped callbacks, handed to the
  // LiveKit plugin which calls them from WebRTC's audio thread.
  late final int captureInit = lib
      .lookup<NativeFunction<_InitNative>>('commet_dsp_capture_init')
      .address;
  late final int captureProcess = lib
      .lookup<NativeFunction<_ProcessNative>>('commet_dsp_capture_process')
      .address;
  late final int captureReset = lib
      .lookup<NativeFunction<_ResetNative>>('commet_dsp_capture_reset')
      .address;
  late final int renderInit =
      lib.lookup<NativeFunction<_InitNative>>('commet_dsp_render_init').address;
  late final int renderProcess = lib
      .lookup<NativeFunction<_ProcessNative>>('commet_dsp_render_process')
      .address;
  late final int renderReset = lib
      .lookup<NativeFunction<_ResetNative>>('commet_dsp_render_reset')
      .address;

  // Handed to the vendored flutter-webrtc plugin, which calls it from its
  // loopback capture thread with the system mix (see
  // third_party/flutter-webrtc/common/cpp/include/commet_system_audio_reference.h).
  late final int feedReference = lib
      .lookup<NativeFunction<_FeedReferenceNative>>('commet_dsp_feed_reference')
      .address;
}

/// Linux and Windows: hooks rust/audio_dsp (shipped inside
/// librust_lib_commet) into WebRTC's audio processing module via the
/// vendored LiveKit plugin.
///
/// The hook is process-global: it sees whatever the audio device module
/// captures. Outside a call nothing is captured, so the microphone test
/// runs a local loopback pair of peer connections; that makes WebRTC start
/// recording (through the APM and our hook) and lets us play the result
/// back.
class NativeAudioProcessingManager extends AudioProcessingManager {
  _Bindings? _bindings;
  bool _loadAttempted = false;

  Pointer<Void>? _handle;
  Pointer<DspParams>? _params;
  Pointer<DspReport>? _report;
  Timer? _pollTimer;
  bool _installed = false;
  bool _inCall = false;

  /// Whether the flutter-webrtc loopback is feeding the system mix to the
  /// bleed detector. Start and stop are serialized through [_referenceOps].
  bool _referenceRunning = false;
  Future<void> _referenceOps = Future.value();

  _MicLoopback? _loopback;
  bool _monitor = false;
  // Start/stop/restart are serialized so a fast toggle cannot interleave.
  Future<void> _testOps = Future.value();

  static const _pollInterval = Duration(milliseconds: 100);

  _Bindings? get bindings {
    if (_loadAttempted) return _bindings;
    _loadAttempted = true;
    final lib = openRustLibrary();
    if (lib == null) return null;
    try {
      final b = _Bindings(lib);
      final abi = b.abiVersion();
      if (abi != _Bindings.expectedAbi) {
        Log.w("Voice DSP: ABI $abi, expected ${_Bindings.expectedAbi}");
        return null;
      }
      if (b.paramsSize() != sizeOf<DspParams>() ||
          b.reportSize() != sizeOf<DspReport>()) {
        Log.w("Voice DSP: struct size mismatch between Dart and Rust");
        return null;
      }
      _bindings = b;
    } catch (e, s) {
      Log.onError(e, s, content: "Voice DSP: symbol lookup failed");
      return null;
    }
    return _bindings;
  }

  @override
  bool get isSupported => bindings != null;

  @override
  bool get isActive => _installed;

  @override
  bool get isInCall => _inCall;

  @override
  bool get isTesting => _loopback != null;

  @override
  bool get micTestMonitor => _monitor;

  @override
  Future<void> onSessionStarted(VoipSession session) async {
    // The loopback holds the microphone; the call needs it.
    if (isTesting) {
      Log.i("Voice DSP: stopping the microphone test, a call started");
      await stopMicTest();
    }
    _inCall = true;
    await _install();
    notifyStateChanged();
  }

  @override
  Future<void> onSessionEnded() async {
    _inCall = false;
    if (!isTesting) await _uninstall();
    notifyStateChanged();
  }

  Future<void> _install() async {
    final b = bindings;
    if (b == null) return;
    if (_installed) return;

    _params ??= b.paramsAlloc();
    _report ??= b.reportAlloc();
    _writeParams(settings);
    _handle ??= b.create(_params!);

    final ok = await lk.Native.setExternalAudioProcessing(
      ctx: _handle!.address,
      captureInit: b.captureInit,
      captureProcess: b.captureProcess,
      captureReset: b.captureReset,
      renderInit: b.renderInit,
      renderProcess: b.renderProcess,
      renderReset: b.renderReset,
    );

    if (!ok) {
      Log.w("Voice DSP: the LiveKit plugin refused the audio processors");
      _teardown();
      return;
    }

    _installed = true;
    Log.i("Voice DSP: installed on the WebRTC audio pipeline");
    _pollTimer = Timer.periodic(_pollInterval, (_) => _poll());
    await _syncReference();
  }

  Future<void> _uninstall() async {
    if (!_installed) return;
    _installed = false;
    _pollTimer?.cancel();
    _pollTimer = null;
    // The loopback thread calls into the Rust handle too: detach it first.
    await _syncReference();
    // Detach from the audio thread before freeing the Rust state.
    await lk.Native.clearExternalAudioProcessing();
    _teardown();
    Log.i("Voice DSP: removed from the WebRTC audio pipeline");
  }

  /// Runs the system-audio loopback that feeds the bleed detector exactly
  /// while the DSP is installed and "filter sound from your speakers" is on.
  ///
  /// On Linux the loopback is the default sink's monitor, which carries our
  /// own playback too: during the microphone test with "Hear myself" on, it
  /// would hear the user's voice coming back out of the speakers and hold
  /// the voice back. It stays off then. (On Windows the loopback excludes
  /// our own process.)
  Future<void> _syncReference() {
    return _referenceOps = _referenceOps.then((_) async {
      final b = _bindings;
      final handle = _handle;
      final want = _installed &&
          b != null &&
          handle != null &&
          settings.speakerBleed &&
          !(PlatformUtils.isLinux && isTesting && _monitor);
      if (want == _referenceRunning) return;
      try {
        if (want) {
          final ok = await webrtc.WebRTC.invokeMethod<bool, dynamic>(
              'commetStartSystemAudioReference',
              {'ctx': handle.address, 'feed': b.feedReference});
          _referenceRunning = ok == true;
          Log.i(_referenceRunning
              ? "Voice DSP: listening to system audio for speaker bleed"
              : "Voice DSP: no system audio capture, speaker bleed is only "
                  "judged against call audio");
        } else {
          // Only reached after the plugin answered a start, so the method
          // exists, and its stop handler cannot fail: once this returns the
          // capture thread no longer holds the Rust handle.
          _referenceRunning = false;
          await webrtc.WebRTC.invokeMethod<bool, dynamic>(
              'commetStopSystemAudioReference');
          Log.i("Voice DSP: stopped listening to system audio");
        }
      } catch (e, s) {
        Log.onError(e, s, content: "Voice DSP: system audio reference");
      }
    });
  }

  void _teardown() {
    final b = _bindings;
    if (b == null) return;
    if (_handle != null) {
      b.destroy(_handle!);
      _handle = null;
    }
    if (_params != null) {
      b.paramsFree(_params!);
      _params = null;
    }
    if (_report != null) {
      b.reportFree(_report!);
      _report = null;
    }
  }

  @override
  lk.TrackProcessor<lk.AudioProcessorOptions>? createTrackProcessor() => null;

  @override
  Future<void> applySettings(AudioDspSettings settings) async {
    final b = _bindings;
    if (b == null || _handle == null || _params == null) return;
    _writeParams(settings);
    b.setParams(_handle!, _params!);
    await _syncReference();
  }

  @override
  Future<void> onNoiseSuppressionChanged(bool enabled) async {
    // The WebRTC suppressor is chosen when the capture starts: restart the
    // test capture so what the user hears matches the setting.
    if (!isTesting) return;
    _testOps = _testOps.then((_) async {
      final lb = _loopback;
      if (lb == null) return;
      await lb.dispose();
      _loopback = null;
      await _startLoopback();
      notifyStateChanged();
    });
    await _testOps;
  }

  @override
  Future<bool> startMicTest() async {
    if (!isSupported || _inCall) return false;
    if (isTesting) return true;
    var started = false;
    _testOps = _testOps.then((_) async {
      if (_inCall || isTesting) return;
      await _install();
      if (!_installed) return;
      started = await _startLoopback();
      await _syncReference();
      if (!started) await _uninstall();
      notifyStateChanged();
    });
    await _testOps;
    return started;
  }

  Future<bool> _startLoopback() async {
    try {
      final lb = await _MicLoopback.start(
          noiseSuppression: !settings.noiseSuppression, monitor: _monitor);
      _loopback = lb;
      Log.i("Voice DSP: microphone test running");
      return true;
    } catch (e, s) {
      Log.onError(e, s, content: "Voice DSP: microphone test failed to start");
      return false;
    }
  }

  @override
  Future<void> stopMicTest() async {
    _testOps = _testOps.then((_) async {
      final lb = _loopback;
      if (lb == null) return;
      _loopback = null;
      await lb.dispose();
      if (!_inCall) await _uninstall();
      Log.i("Voice DSP: microphone test stopped");
      notifyStateChanged();
    });
    await _testOps;
  }

  @override
  Future<void> setMicTestMonitor(bool enabled) async {
    _monitor = enabled;
    _loopback?.setMonitor(enabled);
    await _syncReference();
    notifyStateChanged();
  }

  void _writeParams(AudioDspSettings s) {
    final params = _params!.ref;
    params.noiseSuppression = s.noiseSuppression ? 1 : 0;
    params.gateMode = s.gateMode;
    params.farEndDucking = s.farEndDucking ? 1 : 0;
    params.speakerBleed = s.speakerBleed ? 1 : 0;
    // WebRTC hands us int16-scale floats.
    params.inputScale = 1.0;
    params.gateThresholdDb = s.gateThresholdDb;
    params.gateFloorDb = AudioDspSettings.gateFloorDb;
    params.duckDepthDb = AudioDspSettings.duckDepthDb;
    params.duckFarThresholdDb = AudioDspSettings.duckFarThresholdDb;
  }

  void _poll() {
    final b = _bindings;
    if (b == null || _handle == null || _report == null) return;
    b.getReport(_handle!, _report!);
    final r = _report!.ref;
    publishReport(AudioDspReport(
      levelDb: r.levelDb,
      vad: r.vad,
      farLevelDb: r.farLevelDb,
      gainDb: r.gainDb,
      sampleRate: r.sampleRate,
      frames: r.frames,
      flags: r.flags,
    ));
  }
}

/// Two peer connections on the same machine: the microphone goes out of one
/// and comes back in the other. WebRTC only records while a sending audio
/// stream exists, so this is what pushes microphone audio through the APM
/// (and our hook) without a call. The received track plays through the
/// speakers when [setMonitor] is on; otherwise it is disabled and silent.
class _MicLoopback {
  final webrtc.RTCPeerConnection send;
  final webrtc.RTCPeerConnection recv;
  final webrtc.MediaStream mic;
  webrtc.MediaStreamTrack? _remote;
  bool _monitor;

  _MicLoopback._(this.send, this.recv, this.mic, this._monitor);

  static Future<_MicLoopback> start(
      {required bool noiseSuppression, required bool monitor}) async {
    final config = <String, dynamic>{
      'iceServers': <Map<String, dynamic>>[],
      'sdpSemantics': 'unified-plan',
    };
    final send = await webrtc.createPeerConnection(config);
    final recv = await webrtc.createPeerConnection(config);

    // Same options as a call (MatrixLivekitBackend.join): WebRTC's own
    // suppressor only when ours is off.
    final constraints = <String, dynamic>{
      'echoCancellation': true,
      'noiseSuppression': noiseSuppression,
      'autoGainControl': true,
    };
    final deviceId = await WebrtcDefaultDevices.getDefaultMicrophoneId();
    if (deviceId != null) {
      constraints['deviceId'] = {'exact': deviceId};
    }

    webrtc.MediaStream? mic;
    try {
      mic = await webrtc.navigator.mediaDevices
          .getUserMedia({'audio': constraints, 'video': false});
      final lb = _MicLoopback._(send, recv, mic, monitor);

      // Candidates can fire before the other side has its remote
      // description; hold them until the handshake is done.
      final pendingToRecv = <webrtc.RTCIceCandidate>[];
      final pendingToSend = <webrtc.RTCIceCandidate>[];
      var handshakeDone = false;
      send.onIceCandidate = (c) {
        if (handshakeDone) {
          recv.addCandidate(c);
        } else {
          pendingToRecv.add(c);
        }
      };
      recv.onIceCandidate = (c) {
        if (handshakeDone) {
          send.addCandidate(c);
        } else {
          pendingToSend.add(c);
        }
      };
      recv.onTrack = (event) {
        final track = event.track;
        if (track.kind != 'audio') return;
        lb._remote = track;
        track.enabled = lb._monitor;
      };

      for (final track in mic.getAudioTracks()) {
        await send.addTrack(track, mic);
      }

      final offer = await send.createOffer({});
      await send.setLocalDescription(offer);
      await recv.setRemoteDescription(offer);
      final answer = await recv.createAnswer({});
      await recv.setLocalDescription(answer);
      await send.setRemoteDescription(answer);

      handshakeDone = true;
      for (final c in pendingToRecv) {
        await recv.addCandidate(c);
      }
      for (final c in pendingToSend) {
        await send.addCandidate(c);
      }
      return lb;
    } catch (_) {
      await _closeAll(send, recv, mic);
      rethrow;
    }
  }

  void setMonitor(bool enabled) {
    _monitor = enabled;
    final remote = _remote;
    if (remote != null) remote.enabled = enabled;
  }

  Future<void> dispose() => _closeAll(send, recv, mic);

  static Future<void> _closeAll(webrtc.RTCPeerConnection send,
      webrtc.RTCPeerConnection recv, webrtc.MediaStream? mic) async {
    Future<void> guard(Future<void> Function() f) async {
      try {
        await f();
      } catch (e, s) {
        Log.onError(e, s, content: "Voice DSP: microphone test cleanup");
      }
    }

    await guard(() => send.close());
    await guard(() => recv.close());
    if (mic != null) {
      for (final track in mic.getTracks()) {
        await guard(() => track.stop());
      }
      await guard(() => mic.dispose());
    }
    await guard(() => send.dispose());
    await guard(() => recv.dispose());
  }
}
