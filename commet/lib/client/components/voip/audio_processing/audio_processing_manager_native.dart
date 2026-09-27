import 'dart:async';
import 'dart:ffi';

import 'package:collection/collection.dart';

import 'package:commet/client/components/voip/audio_processing/audio_dsp_settings.dart';
import 'package:commet/client/components/voip/audio_processing/audio_processing_manager.dart';
import 'package:commet/client/components/voip/audio_processing/audio_processing_manager_stub.dart'
    show UnsupportedAudioProcessingManager;
import 'package:commet/client/components/voip/audio_processing/microphone_noise_suppression.dart';
import 'package:commet/client/components/voip/voip_session.dart';
import 'package:commet/client/components/voip/webrtc_default_devices.dart';
import 'package:commet/config/platform_utils.dart';
import 'package:commet/config/rust_library.dart';
import 'package:commet/debug/log.dart';
import 'package:flutter/foundation.dart';
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

/// Looks a symbol up in the DSP library. Tests stand in for a library that
/// lacks some.
typedef DspSymbolLookup = Pointer<T> Function<T extends NativeType>(
    DynamicLibrary library, String name);

Pointer<T> _lookup<T extends NativeType>(DynamicLibrary library, String name) =>
    library.lookup<T>(name);

/// The DSP's C ABI. Every entry point is resolved here, when the library
/// loads: a missing one found only when a call installs the DSP used to leave
/// the call with WebRTC's suppressor already off and nothing of ours on the
/// hook.
class _Bindings {
  static const expectedAbi = 2;

  final int Function() abiVersion;
  final int Function() paramsSize;
  final int Function() reportSize;
  final Pointer<Void> Function(Pointer<DspParams>) create;
  final void Function(Pointer<Void>) destroy;
  final void Function(Pointer<Void>, Pointer<DspParams>) setParams;
  final void Function(Pointer<Void>, Pointer<DspReport>) getReport;
  final Pointer<DspParams> Function() paramsAlloc;
  final void Function(Pointer<DspParams>) paramsFree;
  final Pointer<DspReport> Function() reportAlloc;
  final void Function(Pointer<DspReport>) reportFree;

  // Addresses of the CustomProcessing shaped callbacks, handed to the
  // LiveKit plugin which calls them from WebRTC's audio thread.
  final int captureInit;
  final int captureProcess;
  final int captureReset;
  final int renderInit;
  final int renderProcess;
  final int renderReset;

  // Handed to the vendored flutter-webrtc plugin, which calls it from its
  // loopback capture thread with the system mix (see
  // third_party/flutter-webrtc/common/cpp/include/commet_system_audio_reference.h).
  final int feedReference;

  _Bindings(DynamicLibrary lib, DspSymbolLookup find)
      : abiVersion = find<NativeFunction<Uint32 Function()>>(
                lib, 'commet_dsp_abi_version')
            .asFunction<int Function()>(),
        paramsSize = find<NativeFunction<UintPtr Function()>>(
                lib, 'commet_dsp_params_size')
            .asFunction<int Function()>(),
        reportSize = find<NativeFunction<UintPtr Function()>>(
                lib, 'commet_dsp_report_size')
            .asFunction<int Function()>(),
        create =
            find<NativeFunction<Pointer<Void> Function(Pointer<DspParams>)>>(
                    lib, 'commet_dsp_create')
                .asFunction<Pointer<Void> Function(Pointer<DspParams>)>(),
        destroy = find<NativeFunction<Void Function(Pointer<Void>)>>(
                lib, 'commet_dsp_destroy')
            .asFunction<void Function(Pointer<Void>)>(),
        setParams = find<
                    NativeFunction<
                        Void Function(Pointer<Void>, Pointer<DspParams>)>>(
                lib, 'commet_dsp_set_params')
            .asFunction<void Function(Pointer<Void>, Pointer<DspParams>)>(),
        getReport = find<
                    NativeFunction<
                        Void Function(Pointer<Void>, Pointer<DspReport>)>>(
                lib, 'commet_dsp_get_report')
            .asFunction<void Function(Pointer<Void>, Pointer<DspReport>)>(),
        paramsAlloc = find<NativeFunction<Pointer<DspParams> Function()>>(
                lib, 'commet_dsp_params_alloc')
            .asFunction<Pointer<DspParams> Function()>(),
        paramsFree = find<NativeFunction<Void Function(Pointer<DspParams>)>>(
                lib, 'commet_dsp_params_free')
            .asFunction<void Function(Pointer<DspParams>)>(),
        reportAlloc = find<NativeFunction<Pointer<DspReport> Function()>>(
                lib, 'commet_dsp_report_alloc')
            .asFunction<Pointer<DspReport> Function()>(),
        reportFree = find<NativeFunction<Void Function(Pointer<DspReport>)>>(
                lib, 'commet_dsp_report_free')
            .asFunction<void Function(Pointer<DspReport>)>(),
        captureInit =
            find<NativeFunction<_InitNative>>(lib, 'commet_dsp_capture_init')
                .address,
        captureProcess = find<NativeFunction<_ProcessNative>>(
                lib, 'commet_dsp_capture_process')
            .address,
        captureReset =
            find<NativeFunction<_ResetNative>>(lib, 'commet_dsp_capture_reset')
                .address,
        renderInit =
            find<NativeFunction<_InitNative>>(lib, 'commet_dsp_render_init')
                .address,
        renderProcess = find<NativeFunction<_ProcessNative>>(
                lib, 'commet_dsp_render_process')
            .address,
        renderReset =
            find<NativeFunction<_ResetNative>>(lib, 'commet_dsp_render_reset')
                .address,
        feedReference = find<NativeFunction<_FeedReferenceNative>>(
                lib, 'commet_dsp_feed_reference')
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
  /// Merged into the microphone test's capture constraints, for the native
  /// noise loop (integration_test/voice_dsp/native_noise_test.dart).
  @visibleForTesting
  static Map<String, dynamic> debugMicTestConstraints = {};

  /// Where the DSP's C ABI comes from: librust_lib_commet in the app, the
  /// crate's own cdylib in tests.
  final DynamicLibrary? Function() _openLibrary;
  final DspSymbolLookup _symbols;

  NativeAudioProcessingManager(
      {DynamicLibrary? Function()? openLibrary, DspSymbolLookup? symbols})
      : _openLibrary = openLibrary ?? openRustLibrary,
        _symbols = symbols ?? _lookup;

  _Bindings? _bindings;
  bool _loadAttempted = false;

  Pointer<Void>? _handle;
  Pointer<DspParams>? _params;
  Pointer<DspReport>? _report;
  Timer? _pollTimer;
  bool _installed = false;

  /// Whether the flutter-webrtc loopback is feeding the system mix to the
  /// bleed detector. Start and stop are serialized through [_referenceOps].
  bool _referenceRunning = false;
  Future<void> _referenceOps = Future.value();

  _MicLoopback? _loopback;
  bool _monitor = false;

  /// Calls starting and ending, and the microphone test starting, stopping
  /// and restarting, change what is installed one at a time. Nobody awaits
  /// them (CallManager, the settings page), and a leave's teardown that
  /// interleaved with the next join's install ended with the hook cleared
  /// and its handle freed while the manager believed the DSP installed.
  Future<void> _ops = Future.value();

  Future<T> _serially<T>(Future<T> Function() op) {
    final result = _ops.then((_) => op());
    _ops = result.then<void>((_) {}, onError: (Object _) {});
    return result;
  }

  static const _pollInterval = Duration(milliseconds: 100);

  String? _unavailableReason;

  _Bindings? get bindings {
    if (_loadAttempted) return _bindings;
    _loadAttempted = true;
    final lib = _openLibrary();
    if (lib == null) {
      _unavailableReason = "the voice library (librust_lib_commet) is missing";
      return null;
    }
    try {
      final b = _Bindings(lib, _symbols);
      final abi = b.abiVersion();
      if (abi != _Bindings.expectedAbi) {
        _unavailableReason = "the voice library is ABI $abi, "
            "this build expects ${_Bindings.expectedAbi}";
        Log.w("Voice DSP: $_unavailableReason");
        return null;
      }
      if (b.paramsSize() != sizeOf<DspParams>() ||
          b.reportSize() != sizeOf<DspReport>()) {
        _unavailableReason =
            "the voice library's structures do not match this build";
        Log.w("Voice DSP: struct size mismatch between Dart and Rust");
        return null;
      }
      _bindings = b;
    } catch (e, s) {
      _unavailableReason = "the voice library is incomplete ($e)";
      Log.onError(e, s, content: "Voice DSP: symbol lookup failed");
      return null;
    }
    return _bindings;
  }

  @override
  bool get isSupported => bindings != null;

  @override
  String? get unavailableReason => isSupported ? null : _unavailableReason;

  @override
  bool get isActive => _installed;

  @override
  bool get isTesting => _loopback != null;

  @override
  bool get micTestMonitor => _monitor;

  @override
  Future<void> onSessionStarted(VoipSession session) => _serially(() async {
        addSession(session);
        // The loopback holds the microphone; the call needs it.
        if (_loopback != null) {
          Log.i("Voice DSP: stopping the microphone test, a call started");
          await _stopLoopback();
        }
        await _install();
        notifyStateChanged();
      });

  @override
  Future<void> onSessionEnded(VoipSession session) => _serially(() async {
        if (!removeSession(session)) return;
        if (!isInCall && _loopback == null) await _uninstall();
        notifyStateChanged();
      });

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
  Future<void> onNoiseSuppressionChanged(bool enabled) => _serially(() async {
        // The WebRTC suppressor is chosen when the capture starts: restart
        // the test capture so what the user hears matches the setting.
        if (_loopback == null) return;
        await _stopLoopback();
        if (!await _startLoopback() && !isInCall) await _uninstall();
        notifyStateChanged();
      });

  @override
  Future<bool> startMicTest() async {
    if (!isSupported || isInCall) return false;
    if (isTesting) return true;
    return _serially(() async {
      if (isInCall) return false;
      if (isTesting) return true;
      await _install();
      if (!_installed) return false;
      final started = await _startLoopback();
      await _syncReference();
      if (!started) await _uninstall();
      notifyStateChanged();
      return started;
    });
  }

  Future<bool> _startLoopback() async {
    try {
      final lb = await _MicLoopback.start(
          noiseSuppression: MicrophoneNoiseSuppression.webrtcSuppressorFor(this,
              preference: settings.noiseSuppression),
          monitor: _monitor);
      _loopback = lb;
      Log.i("Voice DSP: microphone test running");
      return true;
    } catch (e, s) {
      Log.onError(e, s, content: "Voice DSP: microphone test failed to start");
      return false;
    }
  }

  @override
  Future<void> stopMicTest() => _serially(() async {
        if (_loopback == null) return;
        await _stopLoopback();
        if (!isInCall) await _uninstall();
        notifyStateChanged();
      });

  Future<void> _stopLoopback() async {
    final lb = _loopback;
    if (lb == null) return;
    _loopback = null;
    await lb.dispose();
    Log.i("Voice DSP: microphone test stopped");
  }

  /// The microphone test's WebRTC statistics, sending side then receiving
  /// side, for the native noise loop: a sender's `media-source` energy is
  /// measured on what leaves the audio processing module, our hook included,
  /// which is what gets encoded.
  @visibleForTesting
  Future<List<webrtc.StatsReport>> debugMicTestStats() async {
    final lb = _loopback;
    if (lb == null) return [];
    return [...await lb.send.getStats(), ...await lb.recv.getStats()];
  }

  /// The microphone test's capture track, for the native noise loop.
  @visibleForTesting
  webrtc.MediaStreamTrack? get debugMicTestMicrophone =>
      _loopback?.mic.getAudioTracks().firstOrNull;

  /// The sender of the microphone test's capture, for the native noise
  /// loop's microphone watch.
  @visibleForTesting
  Future<webrtc.RTCRtpSender?> debugMicTestSender() async {
    final lb = _loopback;
    final mic = debugMicTestMicrophone;
    if (lb == null || mic == null) return null;
    return (await lb.send.getSenders())
        .firstWhereOrNull((s) => s.track?.id == mic.id);
  }

  /// Sends [track] next to the microphone test's microphone, as a call
  /// sends the DJ booth's music or a screen share's audio next to it, for
  /// the native noise loop.
  @visibleForTesting
  Future<void> debugMicTestAddTrack(
      webrtc.MediaStreamTrack track, webrtc.MediaStream stream) async {
    await _loopback?.addTrack(track, stream);
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

    // Captured like a call's microphone: the same processing, WebRTC's own
    // suppressor only when ours is off, and the device the user picked (it
    // used to be `deviceId: {exact}`, which desktop WebRTC ignores: the
    // test listened to device 0).
    final constraints = microphoneConstraints(
      webrtcNoiseSuppression: noiseSuppression,
      deviceId: await WebrtcDefaultDevices.getDefaultMicrophoneId(),
    )..addAll(NativeAudioProcessingManager.debugMicTestConstraints);

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
        // The first audio track is the microphone's.
        if (track.kind != 'audio' || lb._remote != null) return;
        lb._remote = track;
        lb._applyMonitor();
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

  /// Another track on the sending side, negotiated like the first.
  Future<void> addTrack(
      webrtc.MediaStreamTrack track, webrtc.MediaStream stream) async {
    await send.addTrack(track, stream);
    final offer = await send.createOffer({});
    await send.setLocalDescription(offer);
    await recv.setRemoteDescription(offer);
    final answer = await recv.createAnswer({});
    await recv.setLocalDescription(answer);
    await send.setRemoteDescription(answer);
  }

  void setMonitor(bool enabled) {
    _monitor = enabled;
    _applyMonitor();
  }

  /// By playout volume, not by disabling the received track: it carries the
  /// id of the microphone track it was sent from (both ends are in this
  /// process), and flutter-webrtc resolves ids among local tracks first. So
  /// "disabling the playback" disabled the microphone: WebRTC stopped
  /// processing the capture, the DSP got no audio and the meter stayed dead
  /// whenever "Hear myself" was off. setVolume finds the received track
  /// through its peer connection.
  void _applyMonitor() {
    final remote = _remote;
    if (remote == null) return;
    webrtc.Helper.setVolume(_monitor ? 1.0 : 0.0, remote).catchError(
        (Object e, StackTrace s) =>
            Log.onError(e, s, content: "Voice DSP: microphone test playback"));
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
