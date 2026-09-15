//! Commet voice DSP core.
//!
//! One `Dsp` instance processes the local microphone in 10 ms blocks:
//!
//! 1. optional resample to 48 kHz (WebRTC may run its pipeline at 16 or 32 kHz),
//! 2. RNNoise noise suppression (nnnoiseless), which also yields a speech
//!    probability,
//! 3. an input gate (manual threshold or VAD driven) plus a far-end ducker,
//! 4. resample back.
//!
//! Samples are floats in int16 scale (-32768..32767), which is what WebRTC's
//! audio processing module hands to custom processors. Callers with unit-scale
//! audio (the browser AudioWorklet) set `Params::input_scale` to 32768.
//!
//! The audio-thread entry points (`process_block`, `process_stream`,
//! `feed_render`) never allocate after construction. Parameters and the
//! report are exchanged through atomics so the UI thread can poke at a
//! running instance.

pub mod ffi;
pub mod gate;
pub mod resample;

use std::sync::atomic::{AtomicU32, Ordering};

use gate::{Gate, GateConfig, GateMode};
use nnnoiseless::DenoiseState;
use resample::Resampler;

pub const FRAME_SIZE: usize = DenoiseState::FRAME_SIZE; // 480 samples = 10 ms at 48 kHz
pub const NATIVE_RATE: usize = 48_000;
/// Rates WebRTC's APM can run at. Anything else is passed through untouched.
pub const SUPPORTED_RATES: [usize; 3] = [16_000, 32_000, 48_000];
/// Maximum number of samples a single `process_stream` call may pass.
pub const MAX_STREAM_BLOCK: usize = 4096;

const I16_SCALE: f32 = 32768.0;

/// Tunables. Plain data so it can cross the C ABI.
#[repr(C)]
#[derive(Clone, Copy, Debug)]
pub struct Params {
    /// 0 = off, 1 = on.
    pub noise_suppression: u8,
    /// 0 = off, 1 = manual threshold, 2 = automatic (VAD).
    pub gate_mode: u8,
    /// 0 = off, 1 = on.
    pub far_end_ducking: u8,
    pub _pad: u8,
    /// Multiply input by this before processing (and divide on output).
    /// 1.0 for int16-scale audio, 32768.0 for unit-scale audio.
    pub input_scale: f32,
    pub gate_threshold_db: f32,
    pub gate_floor_db: f32,
    pub duck_depth_db: f32,
    pub duck_far_threshold_db: f32,
}

impl Default for Params {
    fn default() -> Self {
        let g = GateConfig::default();
        Params {
            noise_suppression: 1,
            gate_mode: 2,
            far_end_ducking: 1,
            _pad: 0,
            input_scale: 1.0,
            gate_threshold_db: g.threshold_db,
            gate_floor_db: g.floor_db,
            duck_depth_db: g.duck_depth_db,
            duck_far_threshold_db: g.duck_far_threshold_db,
        }
    }
}

pub const REPORT_FLAG_GATE_OPEN: u32 = 1 << 0;
pub const REPORT_FLAG_NS_ACTIVE: u32 = 1 << 1;
pub const REPORT_FLAG_UNSUPPORTED_RATE: u32 = 1 << 2;
pub const REPORT_FLAG_DUCKING: u32 = 1 << 3;

/// Snapshot for meters and debugging. Written by the audio thread, read by
/// anyone.
#[repr(C)]
#[derive(Clone, Copy, Debug, Default)]
pub struct Report {
    /// Level of the last block after noise suppression, before gating, dBFS.
    pub level_db: f32,
    /// RNNoise speech probability of the last block (0 when NS is off).
    pub vad: f32,
    /// Far-end (playout) level with 300 ms peak hold, dBFS.
    pub far_level_db: f32,
    /// Gain currently applied by gate + ducker, dB.
    pub gain_db: f32,
    /// Sample rate the capture side is running at.
    pub sample_rate: i32,
    /// Capture blocks processed so far.
    pub frames: u32,
    pub flags: u32,
}

/// Atomic mirrors of `Params` and `Report`.
struct Shared {
    noise_suppression: AtomicU32,
    gate_mode: AtomicU32,
    far_end_ducking: AtomicU32,
    input_scale: AtomicU32,
    gate_threshold_db: AtomicU32,
    gate_floor_db: AtomicU32,
    duck_depth_db: AtomicU32,
    duck_far_threshold_db: AtomicU32,

    level_db: AtomicU32,
    vad: AtomicU32,
    far_level_db: AtomicU32,
    gain_db: AtomicU32,
    sample_rate: AtomicU32,
    frames: AtomicU32,
    flags: AtomicU32,
}

fn f2u(f: f32) -> u32 {
    f.to_bits()
}
fn u2f(u: u32) -> f32 {
    f32::from_bits(u)
}

impl Shared {
    fn new(p: &Params) -> Shared {
        let s = Shared {
            noise_suppression: AtomicU32::new(0),
            gate_mode: AtomicU32::new(0),
            far_end_ducking: AtomicU32::new(0),
            input_scale: AtomicU32::new(f2u(1.0)),
            gate_threshold_db: AtomicU32::new(0),
            gate_floor_db: AtomicU32::new(0),
            duck_depth_db: AtomicU32::new(0),
            duck_far_threshold_db: AtomicU32::new(0),
            level_db: AtomicU32::new(f2u(-120.0)),
            vad: AtomicU32::new(0),
            far_level_db: AtomicU32::new(f2u(-120.0)),
            gain_db: AtomicU32::new(0),
            sample_rate: AtomicU32::new(0),
            frames: AtomicU32::new(0),
            flags: AtomicU32::new(0),
        };
        s.set_params(p);
        s
    }

    fn set_params(&self, p: &Params) {
        self.noise_suppression.store(p.noise_suppression as u32, Ordering::Relaxed);
        self.gate_mode.store(p.gate_mode as u32, Ordering::Relaxed);
        self.far_end_ducking.store(p.far_end_ducking as u32, Ordering::Relaxed);
        self.input_scale.store(f2u(p.input_scale), Ordering::Relaxed);
        self.gate_threshold_db.store(f2u(p.gate_threshold_db), Ordering::Relaxed);
        self.gate_floor_db.store(f2u(p.gate_floor_db), Ordering::Relaxed);
        self.duck_depth_db.store(f2u(p.duck_depth_db), Ordering::Relaxed);
        self.duck_far_threshold_db.store(f2u(p.duck_far_threshold_db), Ordering::Relaxed);
    }

    fn params(&self) -> Params {
        Params {
            noise_suppression: self.noise_suppression.load(Ordering::Relaxed) as u8,
            gate_mode: self.gate_mode.load(Ordering::Relaxed) as u8,
            far_end_ducking: self.far_end_ducking.load(Ordering::Relaxed) as u8,
            _pad: 0,
            input_scale: u2f(self.input_scale.load(Ordering::Relaxed)),
            gate_threshold_db: u2f(self.gate_threshold_db.load(Ordering::Relaxed)),
            gate_floor_db: u2f(self.gate_floor_db.load(Ordering::Relaxed)),
            duck_depth_db: u2f(self.duck_depth_db.load(Ordering::Relaxed)),
            duck_far_threshold_db: u2f(self.duck_far_threshold_db.load(Ordering::Relaxed)),
        }
    }

    fn report(&self) -> Report {
        Report {
            level_db: u2f(self.level_db.load(Ordering::Relaxed)),
            vad: u2f(self.vad.load(Ordering::Relaxed)),
            far_level_db: u2f(self.far_level_db.load(Ordering::Relaxed)),
            gain_db: u2f(self.gain_db.load(Ordering::Relaxed)),
            sample_rate: self.sample_rate.load(Ordering::Relaxed) as i32,
            frames: self.frames.load(Ordering::Relaxed),
            flags: self.flags.load(Ordering::Relaxed),
        }
    }
}

fn gate_config(p: &Params) -> GateConfig {
    GateConfig {
        mode: match p.gate_mode {
            1 => GateMode::Manual,
            2 => GateMode::Auto,
            _ => GateMode::Off,
        },
        threshold_db: p.gate_threshold_db,
        floor_db: p.gate_floor_db,
        duck_enabled: p.far_end_ducking != 0,
        duck_depth_db: p.duck_depth_db,
        duck_far_threshold_db: p.duck_far_threshold_db,
    }
}

/// RMS level of int16-scale samples in dBFS.
pub fn level_dbfs(buf: &[f32]) -> f32 {
    if buf.is_empty() {
        return -120.0;
    }
    let mean_sq = buf.iter().map(|s| s * s).sum::<f32>() / buf.len() as f32;
    let rms = mean_sq.sqrt() / I16_SCALE;
    if rms <= 1e-6 {
        -120.0
    } else {
        (20.0 * rms.log10()).max(-120.0)
    }
}

pub struct Dsp {
    shared: Shared,
    denoise: Box<DenoiseState<'static>>,
    gate: Gate,
    /// Rate of the blocks the capture side hands us.
    capture_rate: usize,
    up: Option<Resampler>,
    down: Option<Resampler>,
    /// Scratch buffers at 48 kHz.
    scratch_in: Vec<f32>,
    scratch_out: Vec<f32>,
    /// Scratch at capture rate for the resampled-back result.
    scratch_back: Vec<f32>,
    // Streaming FIFO (used by `process_stream`).
    stream_in: Vec<f32>,
    stream_in_len: usize,
    stream_out: Vec<f32>,
    stream_out_head: usize,
    stream_out_len: usize,
    stream_primed: bool,
}

impl Dsp {
    pub fn new(params: Params) -> Box<Dsp> {
        let mut dsp = Box::new(Dsp {
            shared: Shared::new(&params),
            denoise: DenoiseState::new(),
            gate: Gate::new(NATIVE_RATE),
            capture_rate: NATIVE_RATE,
            up: None,
            down: None,
            scratch_in: vec![0.0; FRAME_SIZE],
            scratch_out: vec![0.0; FRAME_SIZE],
            scratch_back: vec![0.0; FRAME_SIZE],
            stream_in: vec![0.0; FRAME_SIZE],
            stream_in_len: 0,
            stream_out: vec![0.0; FRAME_SIZE + MAX_STREAM_BLOCK],
            stream_out_head: 0,
            stream_out_len: 0,
            stream_primed: false,
        });
        // Warm up: the first RNNoise frame builds its FFT plan. Do it here so
        // the audio thread never allocates.
        let mut warm = [0.0f32; FRAME_SIZE];
        let warm_in = [0.0f32; FRAME_SIZE];
        for _ in 0..3 {
            dsp.denoise.process_frame(&mut warm, &warm_in);
        }
        dsp.shared.sample_rate.store(NATIVE_RATE as u32, Ordering::Relaxed);
        dsp
    }

    pub fn set_params(&mut self, p: &Params) {
        self.shared.set_params(p);
    }

    pub fn params(&self) -> Params {
        self.shared.params()
    }

    pub fn report(&self) -> Report {
        self.shared.report()
    }

    /// Called when the capture side (re)starts at `sample_rate`.
    pub fn reset(&mut self, sample_rate: usize) {
        self.capture_rate = sample_rate;
        self.shared.sample_rate.store(sample_rate as u32, Ordering::Relaxed);
        if sample_rate != NATIVE_RATE && SUPPORTED_RATES.contains(&sample_rate) {
            // Reallocation is acceptable here: reset happens off the hot path
            // (device change), and libwebrtc itself reallocates at that point.
            self.up = Some(Resampler::new(sample_rate, NATIVE_RATE));
            self.down = Some(Resampler::new(NATIVE_RATE, sample_rate));
        } else {
            self.up = None;
            self.down = None;
        }
        self.gate.reset();
        self.gate.set_rate(NATIVE_RATE);
        self.stream_in_len = 0;
        self.stream_out_head = 0;
        self.stream_out_len = 0;
        self.stream_primed = false;
        self.shared.frames.store(0, Ordering::Relaxed);
    }

    /// Far-end (playout) audio. Any rate, any block size, mono or interleaved;
    /// we only take a level from it.
    pub fn feed_render(&mut self, buf: &[f32]) {
        let scale = u2f(self.shared.input_scale.load(Ordering::Relaxed));
        let level = if scale == 1.0 {
            level_dbfs(buf)
        } else {
            // Avoid a temp buffer: scale the mean square instead.
            let mean_sq = buf.iter().map(|s| s * s).sum::<f32>() / buf.len().max(1) as f32;
            let rms = mean_sq.sqrt() * scale / I16_SCALE;
            if rms <= 1e-6 { -120.0 } else { (20.0 * rms.log10()).max(-120.0) }
        };
        self.gate.observe_far_end(level);
        self.shared.far_level_db.store(f2u(self.gate.far_level_db()), Ordering::Relaxed);
    }

    /// Process exactly one 10 ms block at the current capture rate, in place.
    /// `buf.len()` must be `capture_rate / 100`. Blocks at an unsupported
    /// rate are passed through unchanged (and flagged in the report).
    pub fn process_block(&mut self, buf: &mut [f32]) {
        let rate = buf.len() * 100;
        if rate != self.capture_rate {
            self.reset(rate);
        }
        let p = self.shared.params();
        let mut flags = 0u32;

        if !SUPPORTED_RATES.contains(&rate) {
            flags |= REPORT_FLAG_UNSUPPORTED_RATE;
            self.shared.flags.store(flags, Ordering::Relaxed);
            self.shared.frames.fetch_add(1, Ordering::Relaxed);
            return;
        }

        // 1. bring to int16 scale at 48 kHz
        let scale = p.input_scale;
        if let Some(up) = self.up.as_mut() {
            if scale != 1.0 {
                for (d, s) in self.scratch_back[..buf.len()].iter_mut().zip(buf.iter()) {
                    *d = *s * scale;
                }
                up.process(&self.scratch_back[..buf.len()], &mut self.scratch_in);
            } else {
                up.process(buf, &mut self.scratch_in);
            }
        } else {
            for (d, s) in self.scratch_in.iter_mut().zip(buf.iter()) {
                *d = *s * scale;
            }
        }

        // 2. noise suppression
        let (vad, have_vad) = if p.noise_suppression != 0 {
            flags |= REPORT_FLAG_NS_ACTIVE;
            let v = self.denoise.process_frame(&mut self.scratch_out, &self.scratch_in);
            (v, true)
        } else {
            self.scratch_out.copy_from_slice(&self.scratch_in);
            (0.0, false)
        };

        // 3. gate + ducker
        let level = level_dbfs(&self.scratch_out);
        let cfg = gate_config(&p);
        self.gate.process(&cfg, level, vad, have_vad, &mut self.scratch_out);
        if self.gate.is_open() {
            flags |= REPORT_FLAG_GATE_OPEN;
        }
        let gain_db = self.gate.current_gain_db();
        if gain_db < -0.5 && self.gate.is_open() {
            flags |= REPORT_FLAG_DUCKING;
        }

        // 4. back to caller rate and scale
        let inv = 1.0 / scale;
        if let Some(down) = self.down.as_mut() {
            down.process(&self.scratch_out, &mut self.scratch_back[..buf.len()]);
            for (d, s) in buf.iter_mut().zip(self.scratch_back.iter()) {
                *d = *s * inv;
            }
        } else {
            for (d, s) in buf.iter_mut().zip(self.scratch_out.iter()) {
                *d = *s * inv;
            }
        }

        self.shared.level_db.store(f2u(level), Ordering::Relaxed);
        self.shared.vad.store(f2u(vad), Ordering::Relaxed);
        self.shared.gain_db.store(f2u(gain_db), Ordering::Relaxed);
        self.shared.flags.store(flags, Ordering::Relaxed);
        self.shared.frames.fetch_add(1, Ordering::Relaxed);
    }

    /// Streaming variant for callers that cannot deliver whole 10 ms blocks
    /// (an AudioWorklet delivers 128-sample quanta). Input is consumed into a
    /// FIFO and output is produced with a fixed latency of one block; the
    /// first block's worth of output is silence. Only valid at 48 kHz.
    /// `buf.len()` must not exceed `MAX_STREAM_BLOCK`.
    pub fn process_stream(&mut self, buf: &mut [f32]) {
        if self.capture_rate != NATIVE_RATE {
            self.reset(NATIVE_RATE);
        }
        let n = buf.len().min(MAX_STREAM_BLOCK);
        if !self.stream_primed {
            // one block of silence so output never starves
            for s in self.stream_out.iter_mut().take(FRAME_SIZE) {
                *s = 0.0;
            }
            self.stream_out_head = 0;
            self.stream_out_len = FRAME_SIZE;
            self.stream_primed = true;
        }
        let mut i = 0;
        while i < n {
            let take = (FRAME_SIZE - self.stream_in_len).min(n - i);
            self.stream_in[self.stream_in_len..self.stream_in_len + take].copy_from_slice(&buf[i..i + take]);
            self.stream_in_len += take;
            i += take;
            if self.stream_in_len == FRAME_SIZE {
                // Process the full frame in place, then append to the output ring.
                let mut frame = std::mem::take(&mut self.stream_in);
                self.process_block(&mut frame);
                self.push_out(&frame);
                self.stream_in = frame;
                self.stream_in_len = 0;
            }
        }
        // Pop n samples (always available: latency of one block keeps the
        // ring ahead of the reader).
        let cap = self.stream_out.len();
        for s in buf[..n].iter_mut() {
            if self.stream_out_len == 0 {
                *s = 0.0;
                continue;
            }
            *s = self.stream_out[self.stream_out_head];
            self.stream_out_head = (self.stream_out_head + 1) % cap;
            self.stream_out_len -= 1;
        }
    }

    fn push_out(&mut self, frame: &[f32]) {
        let cap = self.stream_out.len();
        for &s in frame {
            if self.stream_out_len == cap {
                // overflow: drop oldest
                self.stream_out_head = (self.stream_out_head + 1) % cap;
                self.stream_out_len -= 1;
            }
            let idx = (self.stream_out_head + self.stream_out_len) % cap;
            self.stream_out[idx] = s;
            self.stream_out_len += 1;
        }
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use std::alloc::{GlobalAlloc, Layout, System};
    use std::cell::Cell;

    /// Counts allocations on the current thread so the hot path can be
    /// asserted allocation free while other tests run in parallel.
    struct Counting;
    thread_local! {
        static COUNT: Cell<usize> = const { Cell::new(0) };
        static ARMED: Cell<bool> = const { Cell::new(false) };
    }
    unsafe impl GlobalAlloc for Counting {
        unsafe fn alloc(&self, l: Layout) -> *mut u8 {
            let _ = ARMED.try_with(|armed| {
                if armed.get() {
                    COUNT.with(|c| c.set(c.get() + 1));
                }
            });
            System.alloc(l)
        }
        unsafe fn dealloc(&self, p: *mut u8, l: Layout) {
            System.dealloc(p, l)
        }
    }
    #[global_allocator]
    static A: Counting = Counting;

    struct Lcg(u64);
    impl Lcg {
        fn next(&mut self) -> f32 {
            self.0 = self.0.wrapping_mul(6364136223846793005).wrapping_add(1442695040888963407);
            ((self.0 >> 33) as f32 / (1u64 << 31) as f32) * 2.0 - 1.0
        }
    }

    fn white_noise(n: usize, amp: f32, seed: u64) -> Vec<f32> {
        let mut r = Lcg(seed);
        (0..n).map(|_| r.next() * amp).collect()
    }

    /// Low-passed noise. RNNoise is trained on real-world (coloured) noise
    /// and does little against pure full-band white noise, so fixtures use
    /// this instead.
    fn coloured_noise(n: usize, amp: f32, seed: u64) -> Vec<f32> {
        let mut r = Lcg(seed);
        let mut y = 0.0f32;
        (0..n)
            .map(|_| {
                y += (r.next() - y) * 0.1;
                y * 3.0 * amp
            })
            .collect()
    }

    /// Minimal PCM16 mono WAV reader for the test fixture.
    fn read_wav_pcm16(bytes: &[u8]) -> (usize, Vec<f32>) {
        assert_eq!(&bytes[0..4], b"RIFF");
        let mut pos = 12;
        let mut rate = 0usize;
        let mut data = Vec::new();
        while pos + 8 <= bytes.len() {
            let id = &bytes[pos..pos + 4];
            let len = u32::from_le_bytes(bytes[pos + 4..pos + 8].try_into().unwrap()) as usize;
            let body = &bytes[pos + 8..(pos + 8 + len).min(bytes.len())];
            if id == b"fmt " {
                assert_eq!(u16::from_le_bytes(body[2..4].try_into().unwrap()), 1, "channels");
                rate = u32::from_le_bytes(body[4..8].try_into().unwrap()) as usize;
                assert_eq!(u16::from_le_bytes(body[14..16].try_into().unwrap()), 16, "bits");
            } else if id == b"data" {
                data = body.chunks_exact(2).map(|c| i16::from_le_bytes([c[0], c[1]]) as f32).collect();
            }
            pos += 8 + len + (len & 1);
        }
        (rate, data)
    }

    fn speech_fixture() -> Vec<f32> {
        let (rate, data) = read_wav_pcm16(include_bytes!("../testdata/speech_48k.wav"));
        assert_eq!(rate, 48000);
        data
    }

    fn rms_db(x: &[f32]) -> f32 {
        level_dbfs(x)
    }

    #[test]
    fn background_noise_is_attenuated_and_gate_stays_closed() {
        let mut dsp = Dsp::new(Params { gate_mode: 0, far_end_ducking: 0, ..Default::default() });
        let noise = coloured_noise(FRAME_SIZE * 100, 300.0, 7);
        let input_db = rms_db(&noise);
        let mut out = noise.clone();
        for block in out.chunks_mut(FRAME_SIZE) {
            dsp.process_block(block);
        }
        let out_db = rms_db(&out[FRAME_SIZE * 50..]);
        assert!(input_db - out_db > 15.0, "NS-only attenuation {} dB", input_db - out_db);
        let r = dsp.report();
        assert_eq!(r.flags & REPORT_FLAG_NS_ACTIVE, REPORT_FLAG_NS_ACTIVE);
        assert!(r.vad < 0.3, "vad {}", r.vad);
        assert_eq!(r.frames, 100);

        // With the automatic gate on top, the closed gate adds its floor.
        let mut dsp = Dsp::new(Params::default());
        let mut out = noise.clone();
        for block in out.chunks_mut(FRAME_SIZE) {
            dsp.process_block(block);
        }
        let out_db = rms_db(&out[FRAME_SIZE * 50..]);
        assert!(input_db - out_db > 30.0, "NS+gate attenuation {} dB", input_db - out_db);
        assert_eq!(dsp.report().flags & REPORT_FLAG_GATE_OPEN, 0);
    }

    #[test]
    fn speech_survives_and_noise_around_it_is_removed() {
        // 1 s of noise, then speech with the same noise mixed in.
        let speech = speech_fixture();
        let lead = FRAME_SIZE * 100;
        let total = lead + speech.len();
        let noise = coloured_noise(total, 250.0, 17);
        let mut mix = noise.clone();
        for (i, s) in speech.iter().enumerate() {
            mix[lead + i] += s;
        }
        let noise_in_db = rms_db(&noise[..lead]);

        // Noise suppression only.
        let mut dsp = Dsp::new(Params { gate_mode: 0, far_end_ducking: 0, ..Default::default() });
        let mut out = mix.clone();
        let mut vad_noise = Vec::new();
        let mut vad_speech = Vec::new();
        for (i, block) in out.chunks_mut(FRAME_SIZE).enumerate() {
            dsp.process_block(block);
            let v = dsp.report().vad;
            if i >= 30 && i < 100 {
                vad_noise.push(v);
            }
            if i >= 100 + 20 && i < total / FRAME_SIZE {
                vad_speech.push(v);
            }
        }
        let noise_out_db = rms_db(&out[FRAME_SIZE * 30..lead]);
        assert!(noise_in_db - noise_out_db > 15.0, "noise region attenuation {} dB", noise_in_db - noise_out_db);

        let clean_db = rms_db(&speech);
        let speech_out_db = rms_db(&out[lead..]);
        assert!(clean_db - speech_out_db < 4.0 && speech_out_db - clean_db < 3.0,
            "speech level clean {clean_db} out {speech_out_db}");

        let vn: f32 = vad_noise.iter().sum::<f32>() / vad_noise.len() as f32;
        let vs: f32 = vad_speech.iter().sum::<f32>() / vad_speech.len() as f32;
        assert!(vn < 0.3, "vad in noise {vn}");
        assert!(vs > 0.4, "vad in speech {vs}");

        // Automatic gate: closed during the noise-only lead, open on speech.
        let mut dsp = Dsp::new(Params::default());
        let mut out = mix.clone();
        let mut open_noise = 0;
        let mut open_speech = 0;
        for (i, block) in out.chunks_mut(FRAME_SIZE).enumerate() {
            dsp.process_block(block);
            let open = dsp.report().flags & REPORT_FLAG_GATE_OPEN != 0;
            if i >= 30 && i < 100 && open { open_noise += 1; }
            if i >= 120 && i < total / FRAME_SIZE && open { open_speech += 1; }
        }
        assert!(open_noise < 10, "gate open in noise for {open_noise} frames");
        assert!(open_speech > (total / FRAME_SIZE - 120) / 2, "gate open in speech for {open_speech} frames");
    }

    #[test]
    fn hot_path_does_not_allocate() {
        let mut dsp = Dsp::new(Params::default());
        let mut sig = white_noise(FRAME_SIZE * 10, 1000.0, 3);
        let mut render = white_noise(FRAME_SIZE, 1000.0, 4);
        let mut stream = white_noise(128 * 40, 0.01, 5);
        let mut p = Params::default();
        p.input_scale = I16_SCALE;
        COUNT.with(|c| c.set(0));
        ARMED.with(|a| a.set(true));
        for block in sig.chunks_mut(FRAME_SIZE) {
            dsp.feed_render(&render);
            dsp.process_block(block);
        }
        dsp.set_params(&p);
        for block in stream.chunks_mut(128) {
            dsp.process_stream(block);
        }
        let _ = dsp.report();
        ARMED.with(|a| a.set(false));
        render.clear();
        assert_eq!(COUNT.with(|c| c.get()), 0, "allocations on the hot path");
    }

    #[test]
    fn passthrough_when_everything_is_off() {
        let p = Params { noise_suppression: 0, gate_mode: 0, far_end_ducking: 0, ..Default::default() };
        let mut dsp = Dsp::new(p);
        let sig = white_noise(FRAME_SIZE * 4, 1000.0, 9);
        let mut out = sig.clone();
        for block in out.chunks_mut(FRAME_SIZE) {
            dsp.process_block(block);
        }
        for (a, b) in sig.iter().zip(out.iter()) {
            assert!((a - b).abs() < 1e-3);
        }
    }

    #[test]
    fn sixteen_khz_blocks_are_resampled_and_returned_at_size() {
        let mut dsp = Dsp::new(Params::default());
        let mut sig = coloured_noise(160 * 60, 300.0, 11);
        let input_db = rms_db(&sig);
        for block in sig.chunks_mut(160) {
            dsp.process_block(block);
        }
        let r = dsp.report();
        assert_eq!(r.sample_rate, 16000);
        assert_eq!(r.flags & REPORT_FLAG_UNSUPPORTED_RATE, 0);
        assert!(input_db - rms_db(&sig[160 * 30..]) > 10.0);
    }

    #[test]
    fn unsupported_rate_is_flagged_and_passed_through() {
        let mut dsp = Dsp::new(Params::default());
        let sig = white_noise(441 * 3, 300.0, 13);
        let mut out = sig.clone();
        for block in out.chunks_mut(441) {
            dsp.process_block(block);
        }
        assert_eq!(dsp.report().flags & REPORT_FLAG_UNSUPPORTED_RATE, REPORT_FLAG_UNSUPPORTED_RATE);
        assert_eq!(sig, out);
    }

    #[test]
    fn stream_variant_delays_by_one_block_and_processes() {
        let p = Params { noise_suppression: 0, gate_mode: 0, far_end_ducking: 0, input_scale: I16_SCALE, ..Default::default() };
        let mut dsp = Dsp::new(p);
        // A ramp makes the delay measurable.
        let total = 128 * 30;
        let sig: Vec<f32> = (0..total).map(|i| i as f32 / total as f32).collect();
        let mut out = sig.clone();
        for block in out.chunks_mut(128) {
            dsp.process_stream(block);
        }
        // First 480 samples are silence, then the input follows delayed by 480.
        assert!(out[..FRAME_SIZE].iter().all(|&s| s == 0.0));
        for i in FRAME_SIZE..total {
            assert!((out[i] - sig[i - FRAME_SIZE]).abs() < 1e-4, "at {i}");
        }
    }

    #[test]
    fn unit_scale_input_scaled_correctly() {
        let p = Params { noise_suppression: 0, gate_mode: 0, far_end_ducking: 0, input_scale: I16_SCALE, ..Default::default() };
        let mut dsp = Dsp::new(p);
        let mut sig = white_noise(FRAME_SIZE, 0.1, 21);
        let orig = sig.clone();
        dsp.process_block(&mut sig);
        for (a, b) in sig.iter().zip(orig.iter()) {
            assert!((a - b).abs() < 1e-5);
        }
        let r = dsp.report();
        // 0.1 amplitude white noise is about -25 dBFS RMS
        assert!(r.level_db > -30.0 && r.level_db < -20.0, "level {}", r.level_db);
    }
}
