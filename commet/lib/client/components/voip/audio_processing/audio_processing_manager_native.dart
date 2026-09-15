import 'dart:async';
import 'dart:ffi';
import 'dart:io';

import 'package:commet/client/components/voip/audio_processing/audio_dsp_settings.dart';
import 'package:commet/client/components/voip/audio_processing/audio_processing_manager.dart';
import 'package:commet/client/components/voip/audio_processing/audio_processing_manager_stub.dart'
    show UnsupportedAudioProcessingManager;
import 'package:commet/client/components/voip/voip_session.dart';
import 'package:commet/config/platform_utils.dart';
import 'package:commet/debug/log.dart';
import 'package:livekit_client/livekit_client.dart' as lk;
import 'package:path/path.dart' as p;

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
  @Uint8()
  external int pad;
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

class _Bindings {
  final DynamicLibrary lib;
  _Bindings(this.lib);

  static const expectedAbi = 1;

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
}

/// Linux and Windows: hooks rust/audio_dsp (shipped inside
/// librust_lib_commet) into WebRTC's audio processing module via the
/// vendored LiveKit plugin.
class NativeAudioProcessingManager extends AudioProcessingManager {
  _Bindings? _bindings;
  bool _loadAttempted = false;
  String? _loadError;

  Pointer<Void>? _handle;
  Pointer<DspParams>? _params;
  Pointer<DspReport>? _report;
  Timer? _pollTimer;
  bool _installed = false;

  static const _pollInterval = Duration(milliseconds: 100);

  _Bindings? get bindings {
    if (_loadAttempted) return _bindings;
    _loadAttempted = true;
    final lib = _openLibrary();
    if (lib == null) {
      Log.w("Voice DSP: could not load the Rust library: $_loadError");
      return null;
    }
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

  DynamicLibrary? _openLibrary() {
    final name =
        Platform.isWindows ? 'rust_lib_commet.dll' : 'librust_lib_commet.so';
    final exeDir = p.dirname(Platform.resolvedExecutable);
    final candidates = [
      // packaged builds and `flutter run` bundles
      p.join(exeDir, 'lib', name),
      p.join(exeDir, name),
      // already loaded by the runner / flutter_rust_bridge
      name,
      // flutter_rust_bridge's dev location
      p.join('..', 'rust', 'rust', 'target', 'release', name),
      p.join('rust', 'rust', 'target', 'release', name),
    ];
    final errors = <String>[];
    for (final candidate in candidates) {
      try {
        return DynamicLibrary.open(candidate);
      } catch (e) {
        errors.add("$candidate: $e");
      }
    }
    _loadError = errors.join("; ");
    return null;
  }

  @override
  bool get isSupported => bindings != null;

  @override
  bool get isActive => _installed;

  @override
  Future<void> onSessionStarted(VoipSession session) async {
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
  }

  @override
  Future<void> onSessionEnded() async {
    if (!_installed) return;
    _installed = false;
    _pollTimer?.cancel();
    _pollTimer = null;
    // Detach from the audio thread before freeing the Rust state.
    await lk.Native.clearExternalAudioProcessing();
    _teardown();
    Log.i("Voice DSP: removed from the WebRTC audio pipeline");
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
  }

  void _writeParams(AudioDspSettings s) {
    final params = _params!.ref;
    params.noiseSuppression = s.noiseSuppression ? 1 : 0;
    params.gateMode = s.gateMode;
    params.farEndDucking = s.farEndDucking ? 1 : 0;
    params.pad = 0;
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
