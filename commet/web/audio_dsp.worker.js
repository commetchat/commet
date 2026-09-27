// Commet voice DSP worker.
//
// Runs rust/audio_dsp (audio_dsp.wasm) for the AudioWorklet in
// audio_dsp.worklet.js, off the audio rendering thread. DeepFilterNet, the
// noise suppressor, takes about 4 ms of every 10 ms block in wasm on a 2017
// laptop, and a worklet has 2.67 ms per 128-sample quantum: run there, one
// quantum in four would miss its deadline. The worklet sends each 10 ms
// block here and plays what comes back a block later.
//
// From the page (audio_dsp.js):
//   {type: "init", wasm, params, port}  instantiate, create the DSP (which
//                                       builds the model, about half a
//                                       second), then serve the worklet's
//                                       blocks arriving on port
//   {type: "probe", wasm}               check the wasm and answer
//   {type: "params", params}
// To the page: {type: "ready"}, {type: "report", report},
// {type: "error", message}, {type: "probe", ok, reason},
// {type: "deepFilterOff", averageMs}.
//
// On port, from the worklet: {buf, far}, buf an ArrayBuffer of 2 * BLOCK
// floats (the microphone, then the far end), far whether the far end was
// connected. Answered with {buf}, the same buffer, its microphone half
// processed. To the worklet once the DSP runs: {type: "ready"}.

// Mirrors rust/audio_dsp/src/ffi.rs, like audio_dsp.js does.
const ABI_VERSION = 2;
const PARAMS_SIZE = 24;
const REPORT_SIZE = 28;
const BLOCK = 480;
const I16_SCALE = 32768;
const REPORT_EVERY_BLOCKS = 10; // 100 ms
// DeepFilterNet gives way to RNNoise when a block takes longer than this on
// average (RNNoise takes a tenth of it). A block has 10 ms before the next
// one arrives; the worklet plays late blocks late, so a slow one costs a
// little delay, but a worker that is slow on average falls further and
// further behind. About 4 ms on a 2017 laptop, 6.5 ms with two more
// browsers busy on it.
const BUDGET_MS = 8;
// Blocks the average spans, about 2.5 s: a moment's contention for the CPU
// does not cost the call its suppressor.
const AVERAGE_BLOCKS = 256;
// Blocks timed before the average is judged: the first ones compile and
// allocate.
const SETTLE_BLOCKS = 100;

// Every export this worker calls. tools/voice_dsp/check_contracts.py keeps
// the list in step with the calls below and with ffi.rs.
const EXPORTS = [
  "commet_dsp_abi_version",
  "commet_dsp_params_size",
  "commet_dsp_report_size",
  "commet_dsp_create",
  "commet_dsp_set_params",
  "commet_dsp_get_report",
  "commet_dsp_process_block",
  "commet_dsp_feed_render",
  "commet_dsp_disable_deep_filter",
  "commet_dsp_alloc_f32",
  "commet_dsp_params_alloc",
  "commet_dsp_report_alloc",
];

// Why these exports cannot run the DSP, or null.
function incompatible(ex) {
  for (const name of EXPORTS) {
    if (typeof ex[name] !== "function") return "audio_dsp.wasm has no " + name;
  }
  const abi = ex.commet_dsp_abi_version();
  if (abi !== ABI_VERSION) return "audio_dsp.wasm is ABI " + abi + ", expected " + ABI_VERSION;
  if (ex.commet_dsp_params_size() !== PARAMS_SIZE || ex.commet_dsp_report_size() !== REPORT_SIZE) {
    return "audio_dsp.wasm struct sizes do not match";
  }
  return null;
}

let ex = null;
let handle = 0;
let micPtr = 0;
let farPtr = 0;
let paramsPtr = 0;
let reportPtr = 0;
let params = {};
let blocks = 0;
let averageMs = 0;
let deepFilterOn = true;

function fail(message) {
  self.postMessage({ type: "error", message: String(message) });
}

function num(v, fallback) {
  return typeof v === "number" && isFinite(v) ? v : fallback;
}

function applyParams() {
  if (!ex) return;
  const p = params;
  const view = new DataView(ex.memory.buffer, paramsPtr, PARAMS_SIZE);
  view.setUint8(0, p.noiseSuppression ? 1 : 0);
  view.setUint8(1, p.gateMode | 0);
  view.setUint8(2, p.farEndDucking ? 1 : 0);
  // Only WebRTC playout is visible to a browser, so this acts on the remote
  // participants coming back out of the speakers, not on anything else
  // playing on the machine.
  view.setUint8(3, p.speakerBleed ? 1 : 0);
  view.setFloat32(4, I16_SCALE, true);
  view.setFloat32(8, num(p.gateThresholdDb, -50), true);
  view.setFloat32(12, num(p.gateFloorDb, -40), true);
  view.setFloat32(16, num(p.duckDepthDb, -20), true);
  view.setFloat32(20, num(p.duckFarThresholdDb, -45), true);
  ex.commet_dsp_set_params(handle, paramsPtr);
}

function postReport() {
  ex.commet_dsp_get_report(handle, reportPtr);
  const v = new DataView(ex.memory.buffer, reportPtr, REPORT_SIZE);
  self.postMessage({
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

// A DSP that throws (a wasm trap) must not take the microphone with it:
// the block goes back as it came, the frame counter stops, and the app's
// microphone watch sees that and builds a new graph. Told at most once
// every ERROR_EVERY_MS: a trap on every block is a hundred a second.
const ERROR_EVERY_MS = 5000;
let lastErrorAt = -Infinity;

// One block from the worklet: processed in place and sent back.
function processBlock(port, msg) {
  const buf = msg.buf;
  if (!ex || !(buf instanceof ArrayBuffer)) return;
  const block = new Float32Array(buf);
  let took;
  try {
    if (msg.far) {
      new Float32Array(ex.memory.buffer, farPtr, BLOCK).set(block.subarray(BLOCK));
      ex.commet_dsp_feed_render(handle, farPtr, BLOCK);
    }
    new Float32Array(ex.memory.buffer, micPtr, BLOCK).set(block.subarray(0, BLOCK));
    const started = performance.now();
    ex.commet_dsp_process_block(handle, micPtr, BLOCK);
    took = performance.now() - started;
    // memory.buffer is replaced when the module grows its memory.
    block.set(new Float32Array(ex.memory.buffer, micPtr, BLOCK));
  } catch (err) {
    port.postMessage({ buf }, [buf]);
    const now = performance.now();
    if (now - lastErrorAt >= ERROR_EVERY_MS) {
      lastErrorAt = now;
      self.postMessage({ type: "error", message: "processing a block: " + ((err && err.message) || err) });
    }
    return;
  }
  port.postMessage({ buf }, [buf]);

  blocks++;
  averageMs += (took - averageMs) / Math.min(blocks, AVERAGE_BLOCKS);
  if (deepFilterOn && blocks >= SETTLE_BLOCKS && averageMs > BUDGET_MS) {
    deepFilterOn = false;
    ex.commet_dsp_disable_deep_filter(handle);
    self.postMessage({ type: "deepFilterOff", averageMs: averageMs });
  }
  if (blocks % REPORT_EVERY_BLOCKS === 0) postReport();
}

async function init(msg) {
  const { instance } = await WebAssembly.instantiate(msg.wasm, {});
  const exports = instance.exports;
  const why = incompatible(exports);
  if (why) throw new Error(why);
  params = msg.params || {};
  paramsPtr = exports.commet_dsp_params_alloc();
  reportPtr = exports.commet_dsp_report_alloc();
  micPtr = exports.commet_dsp_alloc_f32(BLOCK);
  farPtr = exports.commet_dsp_alloc_f32(BLOCK);
  // Builds DeepFilterNet's model: this is why it happens here and not on
  // the audio thread.
  handle = exports.commet_dsp_create(0);
  ex = exports;
  applyParams();
  const port = msg.port;
  port.onmessage = (e) => processBlock(port, e.data || {});
  port.postMessage({ type: "ready" });
  self.postMessage({ type: "ready" });
}

self.onmessage = (e) => {
  const msg = e.data || {};
  if (msg.type === "init") {
    init(msg).catch((err) => fail((err && err.message) || err));
  } else if (msg.type === "probe") {
    WebAssembly.instantiate(msg.wasm, {})
      .then(({ instance }) => {
        const why = incompatible(instance.exports);
        self.postMessage({ type: "probe", ok: !why, reason: why || "" });
      })
      .catch((err) => self.postMessage({ type: "probe", ok: false, reason: String((err && err.message) || err) }));
  } else if (msg.type === "params") {
    params = msg.params || {};
    applyParams();
  }
};
