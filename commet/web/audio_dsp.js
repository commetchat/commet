// Main-thread glue for Commet's voice DSP in the browser.
//
// Builds the Web Audio graph around the AudioWorklet in audio_dsp.worklet.js:
//
//   mic track -> MediaStreamAudioSourceNode -+
//                                            +-> commet-dsp worklet -> MediaStreamAudioDestinationNode -> processedTrack
//   remote tracks -> MediaStreamAudioSourceNode (input 1, level only)
//
// The worklet only moves 10 ms blocks: the DSP (audio_dsp.wasm) runs in
// audio_dsp.worker.js, which this starts per graph and connects to the
// worklet with a MessageChannel. Parameters go to the worker, reports come
// from it.
//
// Dart talks to window.commetAudioDsp through dart:js_interop; keeping the
// Web Audio calls here means the graph can be poked at from devtools.
(function () {
  const WORKLET_URL = "audio_dsp.worklet.js";
  const WORKER_URL = "audio_dsp.worker.js";
  const WASM_URL = "audio_dsp.wasm";
  const TARGET_RATE = 48000;
  // The worker compiles the wasm and builds DeepFilterNet's model before
  // the DSP runs: about a second on a 2017 laptop.
  const READY_TIMEOUT_MS = 10000;
  const PROBE_TIMEOUT_MS = 10000;

  const supported =
    typeof AudioContext !== "undefined" &&
    typeof AudioWorkletNode !== "undefined" &&
    typeof WebAssembly !== "undefined" &&
    typeof Worker !== "undefined" &&
    typeof MessageChannel !== "undefined" &&
    typeof MediaStreamAudioDestinationNode !== "undefined";

  let wasmPromise = null;
  function loadWasm() {
    if (!wasmPromise) {
      wasmPromise = fetch(WASM_URL).then((r) => {
        if (!r.ok) throw new Error("audio_dsp.wasm: HTTP " + r.status);
        return r.arrayBuffer();
      });
      wasmPromise.catch(() => {
        wasmPromise = null;
      });
    }
    return wasmPromise;
  }

  // Starts audio_dsp.worker.js. [onMessage] gets what it posts; [onFail] a
  // worker script that did not load or threw.
  function startWorker(onMessage, onFail) {
    const worker = new Worker(WORKER_URL);
    worker.onmessage = (e) => onMessage(e.data || {});
    worker.onerror = (e) => {
      e.preventDefault();
      onFail(WORKER_URL + ": " + ((e && e.message) || "did not load"));
    };
    return worker;
  }

  // Asks a worker whether it can run [bytes]: the worker script loads, and
  // the wasm compiles and speaks its ABI.
  function probeWorker(bytes) {
    return new Promise((resolve) => {
      let worker = null;
      const done = (r) => {
        clearTimeout(timer);
        if (worker) worker.terminate();
        resolve(r);
      };
      const timer = setTimeout(
        () => done({ ok: false, reason: WORKER_URL + " did not answer in " + PROBE_TIMEOUT_MS + " ms" }),
        PROBE_TIMEOUT_MS,
      );
      try {
        worker = startWorker(
          (msg) => {
            if (msg.type === "probe") done({ ok: !!msg.ok, reason: msg.reason || "" });
          },
          (reason) => done({ ok: false, reason: reason }),
        );
        const copy = bytes.slice(0);
        worker.postMessage({ type: "probe", wasm: copy }, [copy]);
      } catch (e) {
        done({ ok: false, reason: String((e && e.message) || e) });
      }
    });
  }

  // Whether the DSP can run here: the worklet module loads, and in a worker
  // audio_dsp.wasm compiles and speaks the ABI the worker expects. The app
  // asks before a call decides who suppresses noise, so a missing or broken
  // file is known up front, instead of when the call's graph fails with the
  // browser's suppressor already turned off. Only a success is kept: a fetch
  // that failed is tried again.
  let probed = null;
  function probe() {
    if (probed) return probed;
    const attempt = (async () => {
      if (!supported) return { ok: false, reason: "this browser has no AudioWorklet or WebAssembly" };
      try {
        // The worklet module has to load too: a missing or broken
        // audio_dsp.worklet.js fails every call the same way.
        await new OfflineAudioContext(1, 128, TARGET_RATE).audioWorklet.addModule(WORKLET_URL);
        const bytes = await loadWasm();
        return await probeWorker(bytes);
      } catch (e) {
        return { ok: false, reason: String((e && e.message) || e) };
      }
    })();
    probed = attempt;
    attempt.then((r) => {
      if (!r.ok) {
        console.error("commetAudioDsp: " + r.reason);
        if (probed === attempt) probed = null;
      }
    });
    return attempt;
  }

  async function create(track, params) {
    if (!supported) throw new Error("AudioWorklet or WebAssembly not supported");
    if (!track || track.kind !== "audio") throw new Error("expected an audio MediaStreamTrack");
    // A capture that ended (a restart racing a device that went away) would
    // make a graph that runs and sends silence, and look like a success.
    if (track.readyState === "ended") {
      const e = new Error("CaptureEnded: the microphone track has already ended");
      e.name = "CaptureEnded";
      throw e;
    }

    // Own context: the DSP runs at 48 kHz and LiveKit's context runs at the
    // device rate.
    const ctx = new AudioContext({ sampleRate: TARGET_RATE, latencyHint: "interactive" });
    if (ctx.sampleRate !== TARGET_RATE) {
      console.warn("commetAudioDsp: context runs at " + ctx.sampleRate + " Hz, expected " + TARGET_RATE);
    }
    let worker = null;
    try {
      await ctx.audioWorklet.addModule(WORKLET_URL);
      const wasm = await loadWasm();

      const node = new AudioWorkletNode(ctx, "commet-dsp", {
        numberOfInputs: 2,
        numberOfOutputs: 1,
        outputChannelCount: [1],
        channelCount: 1,
        channelCountMode: "explicit",
        channelInterpretation: "speakers",
      });

      const source = ctx.createMediaStreamSource(new MediaStream([track]));
      const dest = ctx.createMediaStreamDestination();
      source.connect(node, 0, 0);
      node.connect(dest);

      const farEnd = new Map();
      // Microphone test: the processed signal can also go to the speakers.
      let monitoring = false;
      let destroyed = false;
      // The browser suspends or interrupts a context on its own (an output
      // device going away, the OS taking the audio session, Safari's
      // interruptions), and the processed track then carries nothing:
      // nothing resumed it but a rejoin.
      ctx.onstatechange = () => {
        if (destroyed) return;
        if (ctx.state === "suspended" || ctx.state === "interrupted") {
          console.warn("commetAudioDsp: the audio context is " + ctx.state + ", resuming it");
          ctx.resume().catch((e) => console.error("commetAudioDsp: could not resume: " + e));
        }
      };
      let readyResolve;
      let failure = null;
      const ready = new Promise((res) => (readyResolve = res));

      const graph = {
        context: ctx,
        node: node,
        processedTrack: dest.stream.getAudioTracks()[0],
        onReport: null,
        onError: null,
        ready: ready,
        setParams(p) {
          worker.postMessage({ type: "params", params: p || {} });
        },
        addFarEnd(t) {
          if (!t || farEnd.has(t.id)) return;
          const s = ctx.createMediaStreamSource(new MediaStream([t]));
          s.connect(node, 0, 1);
          farEnd.set(t.id, s);
        },
        removeFarEnd(t) {
          if (!t) return;
          const s = farEnd.get(t.id);
          if (s) {
            try { s.disconnect(); } catch (e) {}
            farEnd.delete(t.id);
          }
        },
        setMonitor(enabled) {
          enabled = !!enabled;
          if (enabled === monitoring) return;
          monitoring = enabled;
          try {
            if (enabled) node.connect(ctx.destination);
            else node.disconnect(ctx.destination);
          } catch (e) {}
        },
        resume() {
          return ctx.resume();
        },
        get state() {
          return ctx.state;
        },
        async destroy() {
          destroyed = true;
          monitoring = false;
          try { source.disconnect(); } catch (e) {}
          try { node.disconnect(); } catch (e) {}
          for (const s of farEnd.values()) {
            try { s.disconnect(); } catch (e) {}
          }
          farEnd.clear();
          try { node.port.postMessage({ type: "destroy" }); } catch (e) {}
          worker.terminate();
          try { await ctx.close(); } catch (e) {}
        },
      };

      const fail = (message) => {
        console.error("commetAudioDsp: " + message);
        failure = message;
        readyResolve(false);
        if (graph.onError) graph.onError(message);
      };
      // The worklet says when the DSP's blocks start coming back.
      node.port.onmessage = (e) => {
        if ((e.data || {}).type === "ready") readyResolve(true);
      };
      worker = startWorker((msg) => {
        if (msg.type === "report" && graph.onReport) graph.onReport(msg.report);
        else if (msg.type === "error") fail("worker: " + msg.message);
        else if (msg.type === "deepFilterOff") {
          console.warn("commetAudioDsp: DeepFilterNet took " + msg.averageMs.toFixed(1) +
            " ms a block, noise suppression continues with RNNoise");
        }
      }, fail);
      const channel = new MessageChannel();
      node.port.postMessage({ type: "worker", port: channel.port1 }, [channel.port1]);
      const copy = wasm.slice(0);
      worker.postMessage({ type: "init", wasm: copy, params: params || {}, port: channel.port2 }, [copy, channel.port2]);

      await ctx.resume();
      // Not before the worker's DSP runs: until then the worklet passes the
      // microphone through untouched, and whoever publishes processedTrack
      // has turned the browser's suppressor off because ours is on.
      const started = await Promise.race([
        ready,
        new Promise((res) => setTimeout(() => res(false), READY_TIMEOUT_MS)),
      ]);
      if (started !== true) {
        await graph.destroy();
        throw new Error("audio_dsp did not start: " + (failure || "no answer in " + READY_TIMEOUT_MS + " ms"));
      }
      return graph;
    } catch (err) {
      if (worker) worker.terminate();
      try { await ctx.close(); } catch (e) {}
      throw err;
    }
  }

  window.commetAudioDsp = { isSupported: supported, probe: probe, create: create };
})();
