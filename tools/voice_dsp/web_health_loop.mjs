#!/usr/bin/env node
// The web voice DSP when something under it fails, in Chrome
// (docs/voice-call-health.md). The DSP sits between the microphone and what
// the call sends, so a failure of its own used to send silence until the
// user rejoined: the worker's wasm trapping on every block, the worker
// hanging, the browser suspending the audio context. It must keep the
// microphone going out (unprocessed if need be) and stop its frame counter,
// which the app's microphone watch reads to build a new graph.
//
//   node tools/voice_dsp/web_health_loop.mjs [--web-root commet/web] [--chrome <path>]
//
// Serves the glue (audio_dsp.js, the worklet, the worker) and audio_dsp.wasm
// from --web-root (commet/scripts/build-audio-dsp-wasm.sh puts the wasm
// there), builds a graph on Chrome's fake microphone, sends its processed
// track over a loopback peer connection and reads WebRTC's statistics while
// each fault is injected. Needs Node 22 or later (global WebSocket).
import { spawn } from "node:child_process";
import { mkdtempSync, readFileSync, rmSync, writeFileSync } from "node:fs";
import { createServer } from "node:http";
import { tmpdir } from "node:os";
import { join, resolve } from "node:path";

const args = process.argv.slice(2);
const opt = (name, fallback) => {
  const i = args.indexOf(name);
  return i >= 0 ? args[i + 1] : fallback;
};
const repo = resolve(new URL("../..", import.meta.url).pathname);
const webRoot = resolve(opt("--web-root", join(repo, "commet/web")));
const chrome = opt("--chrome", process.env.CHROME || "google-chrome-stable");
const work = mkdtempSync(join(tmpdir(), "voice-health-"));

// Chrome's fake microphone: a 4 Hz modulated harmonic tone, a voice's
// envelope without the voice.
const wav = join(work, "tone.wav");
{
  const rate = 48000, n = rate * 4;
  const buf = Buffer.alloc(44 + n * 2);
  buf.write("RIFF", 0); buf.writeUInt32LE(36 + n * 2, 4); buf.write("WAVE", 8); buf.write("fmt ", 12);
  buf.writeUInt32LE(16, 16); buf.writeUInt16LE(1, 20); buf.writeUInt16LE(1, 22); buf.writeUInt32LE(rate, 24);
  buf.writeUInt32LE(rate * 2, 28); buf.writeUInt16LE(2, 32); buf.writeUInt16LE(16, 34); buf.write("data", 36);
  buf.writeUInt32LE(n * 2, 40);
  for (let i = 0; i < n; i++) {
    const t = i / rate;
    const env = 0.5 + 0.5 * Math.sin(2 * Math.PI * 4 * t);
    let v = 0;
    for (let h = 1; h <= 8; h++) v += Math.sin(2 * Math.PI * 180 * h * t) / h;
    buf.writeInt16LE(Math.round(Math.max(-1, Math.min(1, 0.12 * env * v)) * 32767), 44 + i * 2);
  }
  writeFileSync(wav, buf);
}

const FAULT_BLOCK = 300; // three seconds in

// The worker with a fault, injected where the DSP runs.
function workerSource(fault) {
  const src = readFileSync(join(webRoot, "audio_dsp.worker.js"), "utf8");
  const call = "ex.commet_dsp_process_block(handle, micPtr, BLOCK);";
  if (!src.includes(call)) throw new Error("audio_dsp.worker.js no longer calls " + call);
  if (fault === "trap") {
    // A real wasm trap (out of bounds) from the block on.
    return src.replace(call, `self.__n = (self.__n || 0) + 1;
    if (self.__n >= ${FAULT_BLOCK}) ex.commet_dsp_process_block(handle, 0xFFFFFE00, BLOCK);
    ${call}`);
  }
  if (fault === "stall") {
    return src.replace(call, `self.__n = (self.__n || 0) + 1;
    if (self.__n === ${FAULT_BLOCK}) { for (;;) {} }
    ${call}`);
  }
  return src;
}

const page = `<!doctype html><script src="audio_dsp.js"></script><script>
(async function () {
  const q = new URLSearchParams(location.search);
  const fault = q.get("fault");
  const t0 = performance.now();
  const now = () => Math.round(performance.now() - t0);
  const rows = [], errors = [];
  window.__out = null;
  try {
    const stream = await navigator.mediaDevices.getUserMedia({
      audio: { echoCancellation: true, noiseSuppression: false, autoGainControl: false } });
    const raw = stream.getAudioTracks()[0];
    if (fault === "ended") {
      raw.stop();
      try {
        await window.commetAudioDsp.create(raw, {});
        window.__out = { rejected: false };
      } catch (e) {
        window.__out = { rejected: true, message: String(e && e.message || e) };
      }
      return;
    }
    const graph = await window.commetAudioDsp.create(raw, { noiseSuppression: false, gateMode: 0 });
    let last = null;
    graph.onReport = (r) => { last = r; };
    graph.onError = (m) => errors.push({ t: now(), m: String(m) });
    const pt = graph.processedTrack;
    const pc1 = new RTCPeerConnection(), pc2 = new RTCPeerConnection();
    pc1.onicecandidate = (e) => e.candidate && pc2.addIceCandidate(e.candidate);
    pc2.onicecandidate = (e) => e.candidate && pc1.addIceCandidate(e.candidate);
    const sender = pc1.addTrack(pt, new MediaStream([pt]));
    const offer = await pc1.createOffer();
    await pc1.setLocalDescription(offer);
    await pc2.setRemoteDescription(offer);
    const answer = await pc2.createAnswer();
    await pc2.setLocalDescription(answer);
    await pc1.setRemoteDescription(answer);
    const sample = async () => {
      const row = { t: now(), ctx: graph.context.state, frames: last ? last.frames : 0 };
      (await sender.getStats()).forEach((s) => {
        if (s.type === "media-source") { row.e = s.totalAudioEnergy; row.d = s.totalSamplesDuration; }
      });
      rows.push(row);
    };
    const timer = setInterval(sample, 500);
    if (fault === "suspend") setTimeout(() => graph.context.suspend(), 3000);
    setTimeout(async () => {
      clearInterval(timer);
      await sample();
      window.__out = { rows, errors };
    }, 10000);
  } catch (e) {
    window.__out = { fatal: String(e && e.stack || e) };
  }
})();
</script>`;

function serve(fault) {
  const server = createServer((req, res) => {
    const p = new URL(req.url, "http://x").pathname;
    const send = (body, type) => { res.writeHead(200, { "content-type": type }); res.end(body); };
    try {
      if (p === "/" || p === "/index.html") return send(page, "text/html");
      if (p === "/audio_dsp.worker.js") return send(workerSource(fault), "text/javascript");
      if (p === "/audio_dsp.js" || p === "/audio_dsp.worklet.js") {
        return send(readFileSync(join(webRoot, p.slice(1))), "text/javascript");
      }
      if (p === "/audio_dsp.wasm") return send(readFileSync(join(webRoot, "audio_dsp.wasm")), "application/wasm");
    } catch (e) {
      res.writeHead(500); res.end(String(e)); return;
    }
    res.writeHead(404); res.end();
  });
  return new Promise((r) => server.listen(0, "127.0.0.1", () => r(server)));
}

function cdp(url) {
  const ws = new WebSocket(url);
  let id = 0;
  const pending = new Map();
  ws.onmessage = (e) => {
    const m = JSON.parse(e.data);
    if (m.id && pending.has(m.id)) { pending.get(m.id)(m); pending.delete(m.id); }
  };
  const ready = new Promise((r, j) => { ws.onopen = r; ws.onerror = j; });
  const send = (method, params = {}) => new Promise((r) => {
    const mid = ++id; pending.set(mid, r); ws.send(JSON.stringify({ id: mid, method, params }));
  });
  return { ready, send, close: () => ws.close() };
}

async function scenario(fault) {
  const server = await serve(fault);
  const origin = `http://127.0.0.1:${server.address().port}`;
  const profile = mkdtempSync(join(work, "chrome-"));
  const proc = spawn(chrome, [
    "--headless=new", "--no-sandbox", "--no-first-run", "--no-default-browser-check",
    `--user-data-dir=${profile}`, "--remote-debugging-port=0",
    "--use-fake-ui-for-media-stream", "--use-fake-device-for-media-stream",
    `--use-file-for-fake-audio-capture=${wav}`, "--autoplay-policy=no-user-gesture-required", "about:blank",
  ], { stdio: ["ignore", "ignore", "pipe"] });
  let stderr = "";
  proc.stderr.on("data", (d) => (stderr += d));
  try {
    const port = await new Promise((res, rej) => {
      const t = setTimeout(() => rej(new Error("Chrome did not start: " + stderr)), 20000);
      proc.stderr.on("data", () => {
        const m = stderr.match(/DevTools listening on ws:\/\/[^:]+:(\d+)\//);
        if (m) { clearTimeout(t); res(Number(m[1])); }
      });
    });
    const targets = await (await fetch(`http://127.0.0.1:${port}/json/list`)).json();
    const tab = cdp(targets.find((t) => t.type === "page").webSocketDebuggerUrl);
    await tab.ready;
    await tab.send("Page.navigate", { url: `${origin}/?fault=${fault}` });
    const deadline = Date.now() + 40000;
    while (Date.now() < deadline) {
      await new Promise((r) => setTimeout(r, 500));
      const r = await tab.send("Runtime.evaluate", { expression: "JSON.stringify(window.__out)", returnByValue: true });
      const v = r.result?.result?.value;
      if (v && v !== "null") { tab.close(); return JSON.parse(v); }
    }
    tab.close();
    throw new Error(`${fault}: the page did not finish`);
  } finally {
    proc.kill("SIGKILL");
    server.close();
  }
}

/// What the sender got between [from] and [to] ms: seconds of audio per
/// second, its level in dB, and how many DSP frames went by.
function window_(rows, from, to) {
  const inside = rows.filter((r) => r.t >= from && r.t <= to);
  const a = inside[0], b = inside[inside.length - 1];
  const d = (b.d ?? 0) - (a.d ?? 0), e = (b.e ?? 0) - (a.e ?? 0);
  return {
    rate: d / ((b.t - a.t) / 1000),
    db: d > 0 ? 10 * Math.log10(e / d + 1e-12) : -120,
    frames: b.frames - a.frames,
    ctx: b.ctx,
  };
}

const failures = [];
const check = (ok, what) => { console.log(`  ${ok ? "ok  " : "FAIL"} ${what}`); if (!ok) failures.push(what); };
const fmt = (w) => `${w.rate.toFixed(2)} s/s at ${w.db.toFixed(1)} dB, ${w.frames} DSP frames`;

try {
  for (const fault of ["trap", "stall"]) {
    const out = await scenario(fault);
    if (out.fatal) throw new Error(`${fault}: ${out.fatal}`);
    const before = window_(out.rows, 1000, 2900), after = window_(out.rows, 5000, 10000);
    console.log(`${fault}: before ${fmt(before)}; after ${fmt(after)}; ${out.errors.length} error report(s)`);
    check(before.frames >= 50, `${fault}: the DSP ran before the fault`);
    check(after.db > before.db - 6,
      `${fault}: the microphone keeps going out (${after.db.toFixed(1)} dB, was ${before.db.toFixed(1)})`);
    check(after.rate > 0.9, `${fault}: the sender keeps getting audio`);
    check(after.frames === 0, `${fault}: the frame counter stops, for the app to build a new graph`);
    if (fault === "trap") {
      check(out.errors.length >= 1 && out.errors.length <= 3,
        `trap: told, but not a hundred times a second (${out.errors.length})`);
    }
  }

  {
    const out = await scenario("suspend");
    if (out.fatal) throw new Error(`suspend: ${out.fatal}`);
    const after = window_(out.rows, 4500, 10000);
    console.log(`suspend: after ${fmt(after)}, context ${after.ctx}`);
    check(after.ctx === "running", "suspend: the audio context is resumed");
    check(after.frames > 400, "suspend: the DSP runs again");
    check(after.rate > 0.9, "suspend: the sender gets audio again");
  }

  {
    const out = await scenario("ended");
    console.log(`ended: ${JSON.stringify(out)}`);
    check(out.rejected === true && /CaptureEnded/.test(out.message),
      "ended: a graph is not built on a capture that already ended");
  }
} finally {
  try { rmSync(work, { recursive: true, force: true, maxRetries: 5 }); } catch {}
}

if (failures.length) {
  console.log(`\n${failures.length} check(s) failed`);
  process.exit(1);
}
console.log("\nthe web voice DSP keeps the microphone going through its own failures");
