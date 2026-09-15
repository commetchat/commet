// Commet voice DSP AudioWorklet.
//
// Runs rust/audio_dsp (compiled to audio_dsp.wasm) on the audio rendering
// thread. Input 0 is the local microphone, input 1 is the mix of remote
// participants (used only to measure far-end level for ducking). Output 0 is
// the processed microphone, mono.
//
// The wasm module is handed over as bytes in processorOptions because
// worklets cannot fetch. Until it is instantiated the node passes audio
// through untouched.

const PARAMS_SIZE = 24;
const REPORT_SIZE = 28;
const REPORT_EVERY_QUANTA = 38; // 38 * 128 / 48000 = ~100 ms
const I16_SCALE = 32768;

class CommetDspProcessor extends AudioWorkletProcessor {
  constructor(options) {
    super();
    const opts = (options && options.processorOptions) || {};
    this.params = opts.params || {};
    this.ready = false;
    this.destroyed = false;
    this.quanta = 0;
    this.exports = null;

    this.port.onmessage = (e) => {
      const msg = e.data || {};
      if (msg.type === "params") {
        this.params = msg.params || {};
        this.applyParams();
      } else if (msg.type === "destroy") {
        this.teardown();
      }
    };

    if (!opts.wasm) {
      this.port.postMessage({ type: "error", message: "no wasm bytes" });
      return;
    }

    WebAssembly.instantiate(opts.wasm, {})
      .then(({ instance }) => {
        if (this.destroyed) return;
        const ex = instance.exports;
        const abi = ex.commet_dsp_abi_version();
        if (abi !== 1) {
          this.port.postMessage({ type: "error", message: "audio_dsp ABI " + abi + " unsupported" });
          return;
        }
        if (ex.commet_dsp_params_size() !== PARAMS_SIZE || ex.commet_dsp_report_size() !== REPORT_SIZE) {
          this.port.postMessage({ type: "error", message: "audio_dsp struct size mismatch" });
          return;
        }
        this.exports = ex;
        this.handle = ex.commet_dsp_create(0);
        this.micBuf = ex.commet_dsp_alloc_f32(4096);
        this.farBuf = ex.commet_dsp_alloc_f32(4096);
        this.paramsPtr = ex.commet_dsp_params_alloc();
        this.reportPtr = ex.commet_dsp_report_alloc();
        this.applyParams();
        this.ready = true;
        this.port.postMessage({ type: "ready", sampleRate: sampleRate });
      })
      .catch((err) => {
        this.port.postMessage({ type: "error", message: String(err) });
      });
  }

  applyParams() {
    if (!this.exports) return;
    const p = this.params;
    const view = new DataView(this.exports.memory.buffer, this.paramsPtr, PARAMS_SIZE);
    view.setUint8(0, p.noiseSuppression ? 1 : 0);
    view.setUint8(1, p.gateMode | 0);
    view.setUint8(2, p.farEndDucking ? 1 : 0);
    view.setUint8(3, 0);
    view.setFloat32(4, I16_SCALE, true);
    view.setFloat32(8, num(p.gateThresholdDb, -50), true);
    view.setFloat32(12, num(p.gateFloorDb, -40), true);
    view.setFloat32(16, num(p.duckDepthDb, -20), true);
    view.setFloat32(20, num(p.duckFarThresholdDb, -45), true);
    this.exports.commet_dsp_set_params(this.handle, this.paramsPtr);
  }

  teardown() {
    this.destroyed = true;
    this.ready = false;
    const ex = this.exports;
    if (!ex) return;
    this.exports = null;
    try {
      ex.commet_dsp_destroy(this.handle);
      ex.commet_dsp_free_f32(this.micBuf, 4096);
      ex.commet_dsp_free_f32(this.farBuf, 4096);
      ex.commet_dsp_params_free(this.paramsPtr);
      ex.commet_dsp_report_free(this.reportPtr);
    } catch (e) {
      // nothing useful to do on the audio thread
    }
  }

  postReport() {
    const ex = this.exports;
    ex.commet_dsp_get_report(this.handle, this.reportPtr);
    const v = new DataView(ex.memory.buffer, this.reportPtr, REPORT_SIZE);
    this.port.postMessage({
      type: "report",
      report: {
        levelDb: v.getFloat32(0, true),
        vad: v.getFloat32(4, true),
        farLevelDb: v.getFloat32(8, true),
        gainDb: v.getFloat32(12, true),
        sampleRate: v.getInt32(16, true),
        frames: v.getUint32(20, true),
        flags: v.getUint32(24, true),
      },
    });
  }

  process(inputs, outputs) {
    if (this.destroyed) return false;
    const mic = inputs[0] && inputs[0][0];
    const out = outputs[0];
    if (!mic || !out || out.length === 0) return true;
    const n = mic.length;

    if (!this.ready) {
      for (let c = 0; c < out.length; c++) out[c].set(mic);
      return true;
    }

    const ex = this.exports;

    const far = inputs[1] && inputs[1][0];
    if (far && far.length > 0) {
      const farView = new Float32Array(ex.memory.buffer, this.farBuf, far.length);
      farView.set(far);
      ex.commet_dsp_feed_render(this.handle, this.farBuf, far.length);
    }

    let micView = new Float32Array(ex.memory.buffer, this.micBuf, n);
    micView.set(mic);
    ex.commet_dsp_process_stream(this.handle, this.micBuf, n);
    // memory.buffer may have been replaced if the module grew memory.
    micView = new Float32Array(ex.memory.buffer, this.micBuf, n);
    for (let c = 0; c < out.length; c++) out[c].set(micView);

    if (++this.quanta % REPORT_EVERY_QUANTA === 0) {
      this.postReport();
    }
    return true;
  }
}

function num(v, fallback) {
  return typeof v === "number" && isFinite(v) ? v : fallback;
}

registerProcessor("commet-dsp", CommetDspProcessor);
