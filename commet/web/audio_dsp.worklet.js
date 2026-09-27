// Commet voice DSP AudioWorklet.
//
// Input 0 is the local microphone, input 1 is the mix of remote
// participants (the DSP only takes its level, for ducking and loudspeaker
// bleed). Output 0 is the processed microphone, mono.
//
// The DSP itself runs in audio_dsp.worker.js: DeepFilterNet is too heavy
// for the audio rendering thread (see the worker). This node gathers the
// microphone into 10 ms blocks, sends each one to the worker as soon as its
// last sample is in, and plays the blocks that come back DELAY samples
// behind the input. A block that is late is played late: the gap is
// silence and the delay grows by it, up to MAX_QUEUED blocks.
//
// The page hands over the worker's port ({type: "worker", port}). Until the
// worker says the DSP runs, the node passes the microphone through
// untouched, and then tells the page {type: "ready"}.

const BLOCK = 480;
// One block to gather it, one for the round trip through the worker.
const DELAY = 2 * BLOCK;
// A worker that stalled and then caught up leaves blocks queued; beyond
// this many the oldest are dropped, so the delay does not stay long.
const MAX_QUEUED = 4;
// No block back from the worker for this long (it died, hung, or its
// context was lost): the microphone goes out unprocessed until blocks come
// back, rather than silence the user cannot hear. The app's microphone
// watch notices the DSP's frame counter stop and builds a new graph.
const STARVED_LIMIT = 20 * BLOCK;
// Buffers going back and forth; more are made if the worker holds on to
// these.
const POOL = 8;

class CommetDspProcessor extends AudioWorkletProcessor {
  constructor() {
    super();
    this.worker = null;
    this.running = false;
    this.destroyed = false;
    this.pool = [];
    for (let i = 0; i < POOL; i++) this.pool.push(new ArrayBuffer(2 * BLOCK * 4));
    // The block being gathered: microphone in [0, BLOCK), far end after.
    this.gather = null;
    this.gathered = 0;
    this.far = false;
    // Processed blocks waiting to be played, and how far into the first.
    this.queue = [];
    this.head = 0;
    // Silence still to play before the first block.
    this.silence = 0;
    // Samples played since the last block came back.
    this.starved = 0;

    this.port.onmessage = (e) => {
      const msg = e.data || {};
      if (msg.type === "worker" && msg.port) {
        this.worker = msg.port;
        this.worker.onmessage = (m) => this.fromWorker(m.data || {});
      } else if (msg.type === "destroy") {
        this.destroyed = true;
        this.running = false;
      }
    };
  }

  fromWorker(msg) {
    if (msg.buf instanceof ArrayBuffer) {
      if (!this.running) {
        this.pool.push(msg.buf);
        return;
      }
      this.queue.push(new Float32Array(msg.buf, 0, BLOCK));
      this.starved = 0;
      while (this.queue.length > MAX_QUEUED) {
        this.pool.push(this.queue.shift().buffer);
        this.head = 0;
      }
    } else if (msg.type === "ready" && !this.running && !this.destroyed) {
      this.running = true;
      this.silence = DELAY;
      this.port.postMessage({ type: "ready", sampleRate: sampleRate });
    }
  }

  // Adds a quantum of [n] samples to the blocks going to the worker; a
  // missing input counts as silence.
  send(mic, far, n) {
    let i = 0;
    while (i < n) {
      if (!this.gather) {
        this.gather = new Float32Array(this.pool.pop() || new ArrayBuffer(2 * BLOCK * 4));
        this.gathered = 0;
        this.far = false;
      }
      const take = Math.min(BLOCK - this.gathered, n - i);
      const at = this.gathered;
      if (mic) this.gather.set(mic.subarray(i, i + take), at);
      else this.gather.fill(0, at, at + take);
      if (far) {
        this.gather.set(far.subarray(i, i + take), BLOCK + at);
        this.far = true;
      } else {
        this.gather.fill(0, BLOCK + at, BLOCK + at + take);
      }
      this.gathered += take;
      i += take;
      if (this.gathered === BLOCK) {
        const buf = this.gather.buffer;
        this.gather = null;
        this.worker.postMessage({ buf: buf, far: this.far }, [buf]);
      }
    }
  }

  // Fills [out] from the processed blocks, or with [mic] once the worker
  // has sent nothing back for STARVED_LIMIT.
  play(out, mic) {
    const n = out.length;
    let k = 0;
    while (k < n) {
      if (this.silence > 0) {
        const t = Math.min(this.silence, n - k);
        out.fill(0, k, k + t);
        this.silence -= t;
        k += t;
        continue;
      }
      const front = this.queue[0];
      if (!front) {
        this.starved += n - k;
        if (this.starved > STARVED_LIMIT && mic) {
          out.set(mic.subarray(k, n), k);
          return;
        }
        // The worker is late: this is silence, and the delay grows by it.
        out.fill(0, k, n);
        return;
      }
      const t = Math.min(BLOCK - this.head, n - k);
      out.set(front.subarray(this.head, this.head + t), k);
      this.head += t;
      k += t;
      if (this.head === BLOCK) {
        this.pool.push(this.queue.shift().buffer);
        this.head = 0;
      }
    }
  }

  process(inputs, outputs) {
    if (this.destroyed) return false;
    const out = outputs[0];
    if (!out || out.length === 0) return true;
    const mic = inputs[0] && inputs[0][0];

    if (!this.running) {
      for (let c = 0; c < out.length; c++) {
        if (mic) out[c].set(mic);
        else out[c].fill(0);
      }
      return true;
    }

    this.send(mic, inputs[1] && inputs[1][0], out[0].length);
    this.play(out[0], mic);
    for (let c = 1; c < out.length; c++) out[c].set(out[0]);
    return true;
  }
}

registerProcessor("commet-dsp", CommetDspProcessor);
