// Main-thread glue for Commet's voice DSP in the browser.
//
// Builds the Web Audio graph around the AudioWorklet in audio_dsp.worklet.js:
//
//   mic track -> MediaStreamAudioSourceNode -+
//                                            +-> commet-dsp worklet -> MediaStreamAudioDestinationNode -> processedTrack
//   remote tracks -> MediaStreamAudioSourceNode (input 1, level only)
//
// Dart talks to window.commetAudioDsp through dart:js_interop; keeping the
// Web Audio calls here means the graph can be poked at from devtools.
(function () {
  const WORKLET_URL = "audio_dsp.worklet.js";
  const WASM_URL = "audio_dsp.wasm";
  const TARGET_RATE = 48000;

  const supported =
    typeof AudioContext !== "undefined" &&
    typeof AudioWorkletNode !== "undefined" &&
    typeof WebAssembly !== "undefined" &&
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

  async function create(track, params) {
    if (!supported) throw new Error("AudioWorklet or WebAssembly not supported");
    if (!track || track.kind !== "audio") throw new Error("expected an audio MediaStreamTrack");

    // Own context: RNNoise is trained at 48 kHz and LiveKit's context runs at
    // the device rate.
    const ctx = new AudioContext({ sampleRate: TARGET_RATE, latencyHint: "interactive" });
    if (ctx.sampleRate !== TARGET_RATE) {
      console.warn("commetAudioDsp: context runs at " + ctx.sampleRate + " Hz, expected " + TARGET_RATE);
    }
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
        // A copy per node: instantiate() may detach/neuter shared buffers in some engines.
        processorOptions: { wasm: wasm.slice(0), params: params || {} },
      });

      const source = ctx.createMediaStreamSource(new MediaStream([track]));
      const dest = ctx.createMediaStreamDestination();
      source.connect(node, 0, 0);
      node.connect(dest);

      const farEnd = new Map();
      let readyResolve;
      const ready = new Promise((res) => (readyResolve = res));

      const graph = {
        context: ctx,
        node: node,
        processedTrack: dest.stream.getAudioTracks()[0],
        onReport: null,
        onError: null,
        ready: ready,
        setParams(p) {
          node.port.postMessage({ type: "params", params: p || {} });
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
        resume() {
          return ctx.resume();
        },
        get state() {
          return ctx.state;
        },
        async destroy() {
          try { source.disconnect(); } catch (e) {}
          try { node.disconnect(); } catch (e) {}
          for (const s of farEnd.values()) {
            try { s.disconnect(); } catch (e) {}
          }
          farEnd.clear();
          try { node.port.postMessage({ type: "destroy" }); } catch (e) {}
          try { await ctx.close(); } catch (e) {}
        },
      };

      node.port.onmessage = (e) => {
        const msg = e.data || {};
        if (msg.type === "report" && graph.onReport) graph.onReport(msg.report);
        else if (msg.type === "ready") readyResolve(true);
        else if (msg.type === "error") {
          console.error("commetAudioDsp worklet: " + msg.message);
          readyResolve(false);
          if (graph.onError) graph.onError(msg.message);
        }
      };

      await ctx.resume();
      return graph;
    } catch (err) {
      try { await ctx.close(); } catch (e) {}
      throw err;
    }
  }

  window.commetAudioDsp = { isSupported: supported, create: create };
})();
