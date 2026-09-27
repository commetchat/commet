//! Commet voice DSP core.
//!
//! One `Dsp` instance processes the local microphone in 10 ms blocks:
//!
//! 1. optional resample to 48 kHz (WebRTC may run its pipeline at 16 or 32 kHz),
//! 2. noise suppression by DeepFilterNet3 (`dfn`) and a 70 Hz high-pass
//!    (`highpass`), with RNNoise (nnnoiseless) judging speech probability on
//!    what they leave and, for opening the gate, on the microphone too;
//!    RNNoise alone suppresses while the model is loading or when it cannot
//!    run,
//! 3. an input gate (manual threshold or VAD driven) plus a far-end ducker,
//!    both told by `bleed` when the microphone holds nothing but what the
//!    loudspeakers are playing,
//! 4. resample back.
//!
//! The loudspeakers are known from two references: WebRTC's playout
//! (`feed_render`) and, where the platform can capture it, the whole system
//! mix (`feed_reference`). Both may be called from their own threads; they
//! only publish a level through an atomic that the capture side collects
//! once per block.
//!
//! Samples are floats in int16 scale (-32768..32767), which is what WebRTC's
//! audio processing module hands to custom processors. Callers with unit-scale
//! audio (the browser AudioWorklet) set `Params::input_scale` to 32768.
//!
//! The audio-thread entry points (`process_block`, `process_stream`,
//! `feed_render`, `feed_reference`) never allocate after construction,
//! except inside DeepFilterNet's inference (see `dfn`).
//! Parameters and the report are exchanged through atomics so the UI thread
//! can poke at a running instance.

pub mod bleed;
pub mod dfn;
pub mod ffi;
pub mod gate;
pub mod highpass;
pub mod resample;

use std::sync::atomic::{AtomicU32, Ordering};
use std::sync::{Arc, Mutex};

use bleed::{BandLevel, BleedEstimator, Verdict};
use dfn::DeepFilter;
use gate::{BleedState, Gate, GateConfig, GateMode};
use highpass::HighPass;
use nnnoiseless::DenoiseState;
use resample::Resampler;

pub const FRAME_SIZE: usize = DenoiseState::FRAME_SIZE; // 480 samples = 10 ms at 48 kHz
pub const NATIVE_RATE: usize = 48_000;
/// The gate opens only when DeepFilterNet estimated speech this far above
/// the noise in one of its last four blocks (`Dsp::gate_vad`).
const OPEN_SNR_DB: f32 = 0.0;
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
    /// 0 = off, 1 = close the gate on loudspeaker bleed (see `bleed`). Was
    /// padding before ABI 2, which is why it is last among the bytes.
    pub speaker_bleed: u8,
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
            speaker_bleed: 1,
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
/// The microphone held only loudspeaker bleed and the gate was kept shut.
pub const REPORT_FLAG_SPEAKER_BLEED: u32 = 1 << 4;
/// System audio (`feed_reference`) arrived during the last block.
pub const REPORT_FLAG_REFERENCE: u32 = 1 << 5;
/// DeepFilterNet suppressed noise in the last block. Noise suppression
/// without it is RNNoise alone.
pub const REPORT_FLAG_DEEP_FILTER: u32 = 1 << 6;
/// State that went bad (a sample that was not a number got in) was rebuilt
/// at least once since the DSP was made (`Dsp::recoveries`).
pub const REPORT_FLAG_RECOVERED: u32 = 1 << 7;

/// The largest magnitude a sample may have at int16 scale, a little over
/// 12 dB above full scale. A sample that is not a finite number is taken as
/// silence, and larger ones are clipped here: one NaN or infinity used to
/// spread into every recursive state of the DSP for good (the model's
/// normalisation, RNNoise, the filters, the gate), and the call went silent
/// until the user rejoined it.
pub const INPUT_LIMIT: f32 = 4.0 * 32768.0;

/// Rebuilds after which DeepFilterNet is given up on, and after which noise
/// suppression is (the gate still runs, on levels).
const RECOVERIES_BEFORE_NO_MODEL: u32 = 3;
const RECOVERIES_BEFORE_NO_SUPPRESSION: u32 = 10;

/// `x` as a sample the DSP can take: finite and within `limit`.
#[inline]
fn sane(x: f32, limit: f32) -> f32 {
    if x.is_finite() {
        x.clamp(-limit, limit)
    } else {
        0.0
    }
}

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
    speaker_bleed: AtomicU32,
    input_scale: AtomicU32,
    gate_threshold_db: AtomicU32,
    gate_floor_db: AtomicU32,
    duck_depth_db: AtomicU32,
    duck_far_threshold_db: AtomicU32,
    /// 0 once DeepFilterNet has been given up on (`Dsp::disable_deep_filter`).
    deep_filter_allowed: AtomicU32,

    /// Loudest render / reference block since the capture side last looked,
    /// as `level_mailbox_encode`; 0 when nothing arrived.
    render_mailbox: AtomicU32,
    /// Same for the band-limited render level the bleed detector uses.
    render_band_mailbox: AtomicU32,
    reference_mailbox: AtomicU32,

    level_db: AtomicU32,
    vad: AtomicU32,
    far_level_db: AtomicU32,
    gain_db: AtomicU32,
    sample_rate: AtomicU32,
    frames: AtomicU32,
    flags: AtomicU32,
    /// How many times state that went bad was rebuilt.
    recoveries: AtomicU32,
}

fn f2u(f: f32) -> u32 {
    f.to_bits()
}
fn u2f(u: u32) -> f32 {
    f32::from_bits(u)
}

/// Levels in the mailboxes are centi-dB offset to be positive, so
/// `fetch_max` keeps the loudest and 0 can mean "nothing arrived".
fn level_mailbox_encode(db: f32) -> u32 {
    ((db.clamp(-150.0, 50.0) + 200.0) * 100.0) as u32
}

fn level_mailbox_take(slot: &AtomicU32) -> Option<f32> {
    match slot.swap(0, Ordering::Relaxed) {
        0 => None,
        v => Some(v as f32 / 100.0 - 200.0),
    }
}

impl Shared {
    fn new(p: &Params) -> Shared {
        let s = Shared {
            noise_suppression: AtomicU32::new(0),
            gate_mode: AtomicU32::new(0),
            far_end_ducking: AtomicU32::new(0),
            speaker_bleed: AtomicU32::new(0),
            input_scale: AtomicU32::new(f2u(1.0)),
            gate_threshold_db: AtomicU32::new(0),
            gate_floor_db: AtomicU32::new(0),
            duck_depth_db: AtomicU32::new(0),
            duck_far_threshold_db: AtomicU32::new(0),
            deep_filter_allowed: AtomicU32::new(1),
            render_mailbox: AtomicU32::new(0),
            render_band_mailbox: AtomicU32::new(0),
            reference_mailbox: AtomicU32::new(0),
            level_db: AtomicU32::new(f2u(-120.0)),
            vad: AtomicU32::new(0),
            far_level_db: AtomicU32::new(f2u(-120.0)),
            gain_db: AtomicU32::new(0),
            sample_rate: AtomicU32::new(0),
            frames: AtomicU32::new(0),
            flags: AtomicU32::new(0),
            recoveries: AtomicU32::new(0),
        };
        s.set_params(p);
        s
    }

    fn set_params(&self, p: &Params) {
        // A parameter that is not a number used to stick in the gate's gain
        // even after it was corrected: the default stands in for it.
        let d = Params::default();
        let or = |v: f32, default: f32| if v.is_finite() { v } else { default };
        let p = &Params {
            input_scale: if p.input_scale.is_finite() && p.input_scale > 0.0 {
                p.input_scale
            } else {
                d.input_scale
            },
            gate_threshold_db: or(p.gate_threshold_db, d.gate_threshold_db),
            gate_floor_db: or(p.gate_floor_db, d.gate_floor_db),
            duck_depth_db: or(p.duck_depth_db, d.duck_depth_db),
            duck_far_threshold_db: or(p.duck_far_threshold_db, d.duck_far_threshold_db),
            ..*p
        };
        self.noise_suppression.store(p.noise_suppression as u32, Ordering::Relaxed);
        self.gate_mode.store(p.gate_mode as u32, Ordering::Relaxed);
        self.far_end_ducking.store(p.far_end_ducking as u32, Ordering::Relaxed);
        self.speaker_bleed.store(p.speaker_bleed as u32, Ordering::Relaxed);
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
            speaker_bleed: self.speaker_bleed.load(Ordering::Relaxed) as u8,
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

/// Render and reference blocks are not aligned with capture blocks: some
/// capture blocks see two, some none, and WASAPI loopback stalls for tens of
/// milliseconds and then delivers a burst. A block with nothing new repeats
/// the last level for this many blocks before the source counts as gone.
const RENDER_HOLD_FRAMES: u32 = 3;
const REFERENCE_HOLD_FRAMES: u32 = 10;

struct LevelHold {
    last_db: f32,
    missed: u32,
    max_missed: u32,
}

impl LevelHold {
    fn new(max_missed: u32) -> LevelHold {
        LevelHold { last_db: -120.0, missed: u32::MAX, max_missed }
    }

    /// The level for this block, or None when the source has gone quiet for
    /// longer than the hold.
    fn next(&mut self, arrived: Option<f32>) -> Option<f32> {
        match arrived {
            Some(db) => {
                self.last_db = db;
                self.missed = 0;
                Some(db)
            }
            None if self.missed < self.max_missed => {
                self.missed += 1;
                Some(self.last_db)
            }
            None => None,
        }
    }

    fn reset(&mut self) {
        *self = LevelHold::new(self.max_missed);
    }
}

/// RMS of int16-scale samples after multiplying by `scale`, in dBFS.
fn scaled_level_dbfs(buf: &[f32], scale: f32) -> f32 {
    if scale == 1.0 {
        return level_dbfs(buf);
    }
    // Avoid a temp buffer: scale the mean square instead.
    let mean_sq = buf.iter().map(|s| s * s).sum::<f32>() / buf.len().max(1) as f32;
    let rms = mean_sq.sqrt() * scale / I16_SCALE;
    if rms <= 1e-6 {
        -120.0
    } else {
        (20.0 * rms.log10()).max(-120.0)
    }
}

/// When DeepFilterNet's model is built. Building takes about half a second
/// natively and allocates a lot.
#[derive(Clone, Copy, Debug, PartialEq, Eq)]
pub enum ModelLoad {
    /// In the constructor.
    Now,
    /// On a thread of its own; RNNoise suppresses until the model is there.
    /// For callers on a UI thread. The same as `Now` where there are no
    /// threads (wasm).
    Background,
    /// Never: RNNoise alone.
    Never,
}

/// A model built off the audio thread, or why it could not be.
struct LoadedModel(Result<Box<DeepFilter>, String>);

type ModelSlot = Arc<Mutex<Option<LoadedModel>>>;

/// DeepFilterNet's model as `load` says: built now, or on its way from a
/// thread of its own.
fn load_model(load: ModelLoad) -> (Option<Box<DeepFilter>>, Option<ModelSlot>) {
    match load {
        ModelLoad::Never => (None, None),
        ModelLoad::Now => (DeepFilter::new().ok().map(Box::new), None),
        ModelLoad::Background if cfg!(target_arch = "wasm32") => {
            (DeepFilter::new().ok().map(Box::new), None)
        }
        ModelLoad::Background => {
            let slot = Arc::new(Mutex::new(None));
            let loaded = Arc::clone(&slot);
            let spawned = std::thread::Builder::new()
                .name("commet-dsp-model".into())
                .spawn(move || {
                    let model = LoadedModel(DeepFilter::new().map(Box::new));
                    if let Ok(mut s) = loaded.lock() {
                        *s = Some(model);
                    }
                });
            match spawned {
                Ok(_) => (None, Some(slot)),
                Err(_) => (DeepFilter::new().ok().map(Box::new), None),
            }
        }
    }
}
// SAFETY: tract's tensors are reference counted with `Rc`. The loading
// thread builds the model, moves all of it into the slot and keeps no
// reference; from then on one thread at a time owns it.
unsafe impl Send for LoadedModel {}

pub struct Dsp {
    shared: Shared,
    /// How the model was built, to build it again after its state went bad.
    model_load: ModelLoad,
    /// Suppresses noise when the model is not running, and judges speech on
    /// the model's output when it is.
    denoise: Box<DenoiseState<'static>>,
    /// Judges speech on the microphone itself while the model suppresses:
    /// the gate opens only when both instances hear speech.
    denoise_raw: Box<DenoiseState<'static>>,
    /// What noise suppression leaves below the voice (`highpass`).
    highpass: HighPass,
    deep_filter: Option<Box<DeepFilter>>,
    /// The model's estimate of the speech-to-noise ratio of its last four
    /// blocks, oldest first (`dfn::DeepFilter::process`).
    recent_snr_db: [f32; 4],
    /// Where a model loading in the background arrives.
    pending_model: Option<ModelSlot>,
    /// Blocks the model still runs beside RNNoise before its output is used.
    /// Its lookahead and overlap hold the last audio it heard: a model that
    /// arrives mid-stream, is switched back on, or follows the capture to
    /// another device would play that first.
    deep_filter_warmup: u32,
    /// Noise suppression was on for the last block.
    suppressing: bool,
    /// Suppression kept producing NaN however often it was rebuilt: off for
    /// the rest of this DSP's life (`recover`).
    suppression_broken: bool,
    /// How long the model takes per block, to give way to RNNoise on a
    /// machine too slow for it (`watch_deep_filter_cost`).
    #[cfg(not(target_arch = "wasm32"))]
    deep_filter_cost: Option<dfn::CostMeter>,
    gate: Gate,
    /// Bleed against WebRTC's playout and against the system mix.
    bleed_render: BleedEstimator,
    bleed_reference: BleedEstimator,
    render_hold: LevelHold,
    reference_hold: LevelHold,
    render_band_hold: LevelHold,
    /// Band-limited level meters (`bleed::BandLevel`). The render and
    /// reference ones belong to the threads that feed them; the locks are
    /// never contended.
    mic_band: BandLevel,
    render_band: Mutex<BandLevel>,
    reference_band: Mutex<BandLevel>,
    /// Rate of the blocks the capture side hands us.
    capture_rate: usize,
    up: Option<Resampler>,
    down: Option<Resampler>,
    /// Scratch buffers at 48 kHz.
    scratch_in: Vec<f32>,
    scratch_out: Vec<f32>,
    /// RNNoise's output while it only judges speech.
    scratch_vad: Vec<f32>,
    scratch_discard: Vec<f32>,
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
    /// A DSP with DeepFilterNet built in the constructor.
    pub fn new(params: Params) -> Box<Dsp> {
        Dsp::with_model(params, ModelLoad::Now)
    }

    pub fn with_model(params: Params, load: ModelLoad) -> Box<Dsp> {
        let (deep_filter, pending_model) = load_model(load);
        let mut dsp = Box::new(Dsp {
            model_load: load,
            shared: Shared::new(&params),
            denoise: DenoiseState::new(),
            denoise_raw: DenoiseState::new(),
            highpass: HighPass::new(highpass::CUTOFF_HZ, NATIVE_RATE as f32),
            deep_filter,
            recent_snr_db: [f32::NEG_INFINITY; 4],
            pending_model,
            deep_filter_warmup: 0,
            suppressing: true,
            suppression_broken: false,
            #[cfg(not(target_arch = "wasm32"))]
            deep_filter_cost: None,
            gate: Gate::new(NATIVE_RATE),
            bleed_render: BleedEstimator::new(),
            bleed_reference: BleedEstimator::new(),
            render_hold: LevelHold::new(RENDER_HOLD_FRAMES),
            reference_hold: LevelHold::new(REFERENCE_HOLD_FRAMES),
            render_band_hold: LevelHold::new(RENDER_HOLD_FRAMES),
            mic_band: BandLevel::new(),
            render_band: Mutex::new(BandLevel::new()),
            reference_band: Mutex::new(BandLevel::new()),
            capture_rate: NATIVE_RATE,
            up: None,
            down: None,
            scratch_in: vec![0.0; FRAME_SIZE],
            scratch_out: vec![0.0; FRAME_SIZE],
            scratch_vad: vec![0.0; FRAME_SIZE],
            scratch_discard: vec![0.0; FRAME_SIZE],
            scratch_back: vec![0.0; FRAME_SIZE],
            stream_in: vec![0.0; FRAME_SIZE],
            stream_in_len: 0,
            stream_out: vec![0.0; FRAME_SIZE + MAX_STREAM_BLOCK],
            stream_out_head: 0,
            stream_out_len: 0,
            stream_primed: false,
        });
        dsp.warm_up_rnnoise();
        dsp.shared.sample_rate.store(NATIVE_RATE as u32, Ordering::Relaxed);
        dsp
    }

    /// The first RNNoise frame builds its FFT plan. Done up front so the
    /// audio thread never allocates.
    fn warm_up_rnnoise(&mut self) {
        let mut warm = [0.0f32; FRAME_SIZE];
        let warm_in = [0.0f32; FRAME_SIZE];
        for _ in 0..3 {
            self.denoise.process_frame(&mut warm, &warm_in);
            self.denoise_raw.process_frame(&mut warm, &warm_in);
        }
    }

    /// How many times state that went bad was rebuilt ([`REPORT_FLAG_RECOVERED`]).
    pub fn recoveries(&self) -> u32 {
        self.shared.recoveries.load(Ordering::Relaxed)
    }

    /// Rebuilds every stage that carries state from block to block, after
    /// a block came out that was not a number. The input is checked, so
    /// this is for what that check did not foresee; it allocates, which the
    /// audio thread otherwise never does, and only happens then. The model
    /// is built again the way it first was; RNNoise suppresses meanwhile.
    fn recover(&mut self) {
        let recoveries = self.shared.recoveries.fetch_add(1, Ordering::Relaxed) + 1;
        // A stage that keeps producing NaN would have everything rebuilt
        // every block. The model goes for good after a few rebuilds, and
        // after more RNNoise too: the gate alone keeps the voice going.
        if recoveries >= RECOVERIES_BEFORE_NO_MODEL {
            self.disable_deep_filter();
        }
        if recoveries >= RECOVERIES_BEFORE_NO_SUPPRESSION {
            self.suppression_broken = true;
        }
        self.denoise = DenoiseState::new();
        self.denoise_raw = DenoiseState::new();
        self.warm_up_rnnoise();
        self.highpass.reset();
        self.gate.reset();
        self.gate.set_rate(NATIVE_RATE);
        self.mic_band.reset();
        self.bleed_render.reset();
        self.bleed_reference.reset();
        self.render_hold.reset();
        self.render_band_hold.reset();
        self.reference_hold.reset();
        self.recent_snr_db = [f32::NEG_INFINITY; 4];
        if let Some(up) = self.up.as_mut() {
            up.reset();
        }
        if let Some(down) = self.down.as_mut() {
            down.reset();
        }
        let allowed = self.shared.deep_filter_allowed.load(Ordering::Relaxed) != 0;
        if allowed && (self.deep_filter.is_some() || self.pending_model.is_some()) {
            let (model, pending) = load_model(self.model_load);
            self.deep_filter = model;
            self.pending_model = pending;
            self.deep_filter_warmup = dfn::WARMUP_BLOCKS;
        } else {
            self.deep_filter = None;
            self.pending_model = None;
        }
    }

    /// Runs a block that is not a number through the stages ahead of
    /// RNNoise that keep state (the model, the high-pass), past the input
    /// check, the way a bug in one of them would spread it. For tests of
    /// the recovery.
    #[doc(hidden)]
    pub fn debug_poison_state(&mut self) {
        let nan = [f32::NAN; FRAME_SIZE];
        let mut out = [0.0f32; FRAME_SIZE];
        let mut buf = nan;
        self.highpass.process(&mut buf);
        if let Some(model) = self.deep_filter.as_mut() {
            model.process(&nan, &mut out);
        }
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

    /// Whether DeepFilterNet is built and allowed to run (it suppresses
    /// whenever noise suppression is on).
    pub fn has_deep_filter(&self) -> bool {
        self.deep_filter.is_some() && self.shared.deep_filter_allowed.load(Ordering::Relaxed) != 0
    }

    /// Times DeepFilterNet from now on and hands noise suppression to
    /// RNNoise for good if it takes more than `dfn::BUDGET` per block on
    /// average: the capture thread would miss its deadlines. For real-time
    /// callers (the app); a test or a tool on a busy machine would only lose
    /// the model it means to measure.
    #[cfg(not(target_arch = "wasm32"))]
    pub fn watch_deep_filter_cost(&mut self) {
        self.deep_filter_cost = Some(dfn::CostMeter::new());
    }

    /// Hands noise suppression to RNNoise alone for good, for a caller that
    /// finds the model too slow (the browser worker times it). Any thread.
    pub fn disable_deep_filter(&self) {
        self.shared.deep_filter_allowed.store(0, Ordering::Relaxed);
    }

    /// Picks up a model that finished loading in the background. Never
    /// waits: if the loading thread holds the slot, next block.
    fn collect_model(&mut self) {
        let Some(slot) = self.pending_model.as_ref() else { return };
        let loaded = match slot.try_lock() {
            Ok(mut s) => s.take(),
            Err(_) => None,
        };
        if let Some(LoadedModel(result)) = loaded {
            self.deep_filter = result.ok();
            self.pending_model = None;
            if self.shared.frames.load(Ordering::Relaxed) > 0 {
                self.deep_filter_warmup = dfn::WARMUP_BLOCKS;
            }
        }
    }

    /// DeepFilterNet on `scratch_in`, into `scratch_out` once warmed up (or
    /// `scratch_vad` while warming up). Whether `scratch_out` holds its
    /// output.
    fn run_deep_filter(&mut self) -> bool {
        if self.shared.deep_filter_allowed.load(Ordering::Relaxed) == 0 {
            return false;
        }
        let Some(model) = self.deep_filter.as_mut() else { return false };
        #[cfg(not(target_arch = "wasm32"))]
        let started = std::time::Instant::now();
        let warming = self.deep_filter_warmup > 0;
        let out = if warming { &mut self.scratch_vad } else { &mut self.scratch_out };
        let snr_db = model.process(&self.scratch_in, out);
        let ok = snr_db.is_some();
        self.recent_snr_db.rotate_left(1);
        self.recent_snr_db[3] = snr_db.unwrap_or(f32::NEG_INFINITY);
        #[cfg(not(target_arch = "wasm32"))]
        if let Some(cost) = self.deep_filter_cost.as_mut() {
            if cost.too_slow(started.elapsed()) {
                self.disable_deep_filter();
            }
        }
        if !ok {
            self.disable_deep_filter();
            return false;
        }
        if warming {
            self.deep_filter_warmup -= 1;
            return false;
        }
        true
    }

    /// The model's speech-to-noise estimate of the last block, in dB; `None`
    /// when it did not run. For tools and tests: the report has no room.
    pub fn speech_to_noise_db(&self) -> Option<f32> {
        Some(self.recent_snr_db[3]).filter(|v| v.is_finite())
    }

    /// The speech probability the gate goes by while the model suppresses.
    ///
    /// Staying open takes RNNoise's probability on what the model left:
    /// on the raw microphone RNNoise calls a knock on the table speech.
    /// Opening takes more, because what the model leaves of some noises
    /// sounds like speech to RNNoise too (other people's chatter made
    /// cleaner, the flicker left of a loud fan): RNNoise on the microphone
    /// has to hear speech as well, and the model has to have estimated
    /// speech above the noise in one of its last four blocks (its estimate
    /// runs 30 ms ahead of its output, which covers an onset). Measured
    /// against 18 noises (`tests/background_noise.rs`).
    fn gate_vad(&self, clean: f32, raw: Option<f32>) -> f32 {
        let Some(raw) = raw else { return clean };
        if self.gate.is_open() {
            return clean;
        }
        let speech_ahead = self.recent_snr_db.iter().any(|&db| db > OPEN_SNR_DB);
        if speech_ahead {
            clean.min(raw)
        } else {
            0.0
        }
    }

    /// Called when the capture side (re)starts at `sample_rate`.
    pub fn reset(&mut self, sample_rate: usize) {
        if self.shared.frames.load(Ordering::Relaxed) > 0 {
            self.deep_filter_warmup = dfn::WARMUP_BLOCKS;
        }
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
        self.highpass.reset();
        // A capture restart is usually a device change: a different
        // microphone hears the loudspeakers differently.
        self.bleed_render.reset();
        self.bleed_reference.reset();
        self.render_hold.reset();
        self.render_band_hold.reset();
        self.reference_hold.reset();
        self.mic_band.reset();
        self.stream_in_len = 0;
        self.stream_out_head = 0;
        self.stream_out_len = 0;
        self.stream_primed = false;
        self.shared.frames.store(0, Ordering::Relaxed);
    }

    /// Far-end (playout) audio, mono, any block size; we only take levels
    /// from it. Safe to call from the render thread while the capture thread
    /// processes. The rate is inferred from 10 ms blocks (what the APM hands
    /// the render hook) and taken as 48 kHz otherwise (AudioWorklet quanta).
    pub fn feed_render(&self, buf: &[f32]) {
        let scale = u2f(self.shared.input_scale.load(Ordering::Relaxed));
        let level = scaled_level_dbfs(buf, scale);
        self.shared.render_mailbox.fetch_max(level_mailbox_encode(level), Ordering::Relaxed);
        let rate = if SUPPORTED_RATES.contains(&(buf.len() * 100)) { buf.len() * 100 } else { NATIVE_RATE };
        if let Ok(mut band) = self.render_band.lock() {
            // Its filters keep state too: nothing that is not a number.
            let db = band.measure(rate, buf.iter().map(|s| sane(s * scale, INPUT_LIMIT)));
            self.shared.render_band_mailbox.fetch_max(level_mailbox_encode(db), Ordering::Relaxed);
        }
    }

    /// What the loudspeakers are playing, from outside WebRTC: the system mix
    /// captured by loopback. Mono int16-scale floats at `sample_rate`, any
    /// block size; only a level is taken. Safe to call from the capturer's
    /// own thread.
    pub fn feed_reference(&self, buf: &[f32], sample_rate: usize) {
        if let Ok(mut band) = self.reference_band.lock() {
            let db = band.measure(sample_rate, buf.iter().map(|s| sane(*s, INPUT_LIMIT)));
            self.shared.reference_mailbox.fetch_max(level_mailbox_encode(db), Ordering::Relaxed);
        }
    }

    /// `feed_reference` for interleaved int16 PCM straight from a capturer.
    /// `None` is a block the capturer reported as silent.
    pub fn feed_reference_i16(&self, buf: Option<&[i16]>, channels: usize, sample_rate: usize) {
        let channels = channels.max(1);
        let db = match buf {
            Some(b) if b.len() >= channels => match self.reference_band.lock() {
                Ok(mut band) => band.measure(
                    sample_rate,
                    b.chunks_exact(channels)
                        .map(|f| f.iter().map(|&s| s as f32).sum::<f32>() / channels as f32),
                ),
                Err(_) => return,
            },
            _ => -120.0,
        };
        self.shared.reference_mailbox.fetch_max(level_mailbox_encode(db), Ordering::Relaxed);
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

        // 0. only finite samples in a sane range get anywhere (INPUT_LIMIT).
        let scale = p.input_scale;
        let limit = INPUT_LIMIT / scale;
        for x in buf.iter_mut() {
            *x = sane(*x, limit);
        }

        if !SUPPORTED_RATES.contains(&rate) {
            flags |= REPORT_FLAG_UNSUPPORTED_RATE;
            self.shared.flags.store(flags, Ordering::Relaxed);
            self.shared.frames.fetch_add(1, Ordering::Relaxed);
            return;
        }

        // 1. bring to int16 scale at 48 kHz
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

        // 2. what the loudspeakers are doing. The microphone level is taken
        // before noise suppression, which treats bleed and the user alike.
        let render_db = self.render_hold.next(level_mailbox_take(&self.shared.render_mailbox));
        let render_band_db = self.render_band_hold.next(level_mailbox_take(&self.shared.render_band_mailbox));
        let reference_db = self.reference_hold.next(level_mailbox_take(&self.shared.reference_mailbox));
        if let Some(db) = render_db {
            self.gate.observe_far_end(db);
        }
        self.gate.tick_far_end();
        self.shared.far_level_db.store(f2u(self.gate.far_level_db()), Ordering::Relaxed);
        if reference_db.is_some() {
            flags |= REPORT_FLAG_REFERENCE;
        }
        let bleed = if p.speaker_bleed != 0 {
            let mic_db = self.mic_band.measure(NATIVE_RATE, self.scratch_in.iter().copied());
            let from_render = self.bleed_render.update(mic_db, render_band_db.unwrap_or(-120.0));
            let from_reference = self.bleed_reference.update(mic_db, reference_db.unwrap_or(-120.0));
            BleedState {
                suppress: from_render == Verdict::Bleed || from_reference == Verdict::Bleed,
                far_talk: match from_render {
                    Verdict::Idle => None,
                    v => Some(v == Verdict::Talk),
                },
            }
        } else {
            BleedState::default()
        };

        // 3. noise suppression
        let mut poisoned = false;
        self.collect_model();
        if p.noise_suppression != 0 && !self.suppressing {
            self.deep_filter_warmup = dfn::WARMUP_BLOCKS;
        }
        self.suppressing = p.noise_suppression != 0;
        let (vad, have_vad) = if p.noise_suppression != 0 && !self.suppression_broken {
            flags |= REPORT_FLAG_NS_ACTIVE;
            // Heard beside the model from the moment there is one, so that
            // its state is current when it counts.
            let raw_vad = if self.has_deep_filter() {
                Some(self.denoise_raw.process_frame(&mut self.scratch_discard, &self.scratch_in))
            } else {
                None
            };
            let v = if self.run_deep_filter() {
                flags |= REPORT_FLAG_DEEP_FILTER;
                self.highpass.process(&mut self.scratch_out);
                // RNNoise must never see what is not a number: its FFT
                // assumes it never does (undefined behaviour, an abort in
                // debug builds).
                if !self.scratch_out.iter().all(|x| x.is_finite()) {
                    self.scratch_out.fill(0.0);
                    poisoned = true;
                }
                let clean = self.denoise.process_frame(&mut self.scratch_vad, &self.scratch_out);
                self.gate_vad(clean, raw_vad)
            } else {
                let v = self.denoise.process_frame(&mut self.scratch_out, &self.scratch_in);
                self.highpass.process(&mut self.scratch_out);
                v
            };
            (v, true)
        } else {
            self.scratch_out.copy_from_slice(&self.scratch_in);
            (0.0, false)
        };

        // 4. gate + ducker
        let level = level_dbfs(&self.scratch_out);
        let cfg = gate_config(&p);
        self.gate.process(&cfg, level, vad, have_vad, bleed, &mut self.scratch_out);
        if self.gate.is_open() {
            flags |= REPORT_FLAG_GATE_OPEN;
        }
        if bleed.suppress && cfg.mode != GateMode::Off {
            flags |= REPORT_FLAG_SPEAKER_BLEED;
        }
        let gain_db = self.gate.current_gain_db();
        if gain_db < -0.5 && self.gate.is_open() {
            flags |= REPORT_FLAG_DUCKING;
        }

        // Something the input check did not foresee made a stage produce
        // what is not a number: that stage's state is poisoned for good, and
        // everything after it. This block goes out silent and every stage
        // is rebuilt.
        if poisoned || !self.scratch_out.iter().all(|x| x.is_finite()) || !gain_db.is_finite() {
            self.scratch_out.fill(0.0);
            self.recover();
        }
        if self.recoveries() > 0 {
            flags |= REPORT_FLAG_RECOVERED;
        }

        // 5. back to caller rate and scale
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

        // The report is read by meters that cannot draw what is not a number.
        let finite = |v: f32, otherwise: f32| if v.is_finite() { v } else { otherwise };
        self.shared.level_db.store(f2u(finite(level, -120.0)), Ordering::Relaxed);
        self.shared.vad.store(f2u(finite(vad, 0.0)), Ordering::Relaxed);
        self.shared.gain_db.store(f2u(finite(gain_db, 0.0)), Ordering::Relaxed);
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
        // Everything but DeepFilterNet's inference, which allocates (tract).
        let mut dsp = Dsp::with_model(Params::default(), ModelLoad::Never);
        let mut sig = white_noise(FRAME_SIZE * 10, 1000.0, 3);
        let mut render = white_noise(FRAME_SIZE, 1000.0, 4);
        let mut stream = white_noise(128 * 40, 0.01, 5);
        let mut p = Params::default();
        p.input_scale = I16_SCALE;
        COUNT.with(|c| c.set(0));
        ARMED.with(|a| a.set(true));
        for block in sig.chunks_mut(FRAME_SIZE) {
            dsp.feed_render(&render);
            dsp.feed_reference(&render, 48_000);
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
    fn a_model_loading_in_the_background_takes_over_after_warming_up() {
        let mut dsp = Dsp::with_model(Params::default(), ModelLoad::Background);
        let noise = coloured_noise(FRAME_SIZE * 1000, 300.0, 23);
        let mut blocks = noise.chunks(FRAME_SIZE);
        let mut block = || {
            let mut b = blocks.next().expect("the model never arrived").to_vec();
            dsp.process_block(&mut b);
            dsp.report().flags
        };
        // RNNoise from the first block: nobody waits for the model.
        let first = block();
        assert_eq!(first & REPORT_FLAG_NS_ACTIVE, REPORT_FLAG_NS_ACTIVE);
        assert_eq!(first & REPORT_FLAG_DEEP_FILTER, 0);
        let mut rnnoise_blocks = 1;
        while block() & REPORT_FLAG_DEEP_FILTER == 0 {
            rnnoise_blocks += 1;
            std::thread::sleep(std::time::Duration::from_millis(5));
        }
        assert!(rnnoise_blocks > dfn::WARMUP_BLOCKS as usize, "took over after {rnnoise_blocks} blocks");
        for _ in 0..50 {
            assert_ne!(block() & REPORT_FLAG_DEEP_FILTER, 0);
        }
    }

    #[test]
    fn switched_back_on_the_model_warms_up_before_it_is_heard() {
        let mut dsp = Dsp::new(Params::default());
        let noise = coloured_noise(FRAME_SIZE * 100, 300.0, 31);
        let mut blocks = noise.chunks(FRAME_SIZE).map(|b| b.to_vec());
        let mut block = |dsp: &mut Dsp| {
            let mut b = blocks.next().unwrap();
            dsp.process_block(&mut b);
            dsp.report().flags & REPORT_FLAG_DEEP_FILTER != 0
        };
        assert!(block(&mut dsp), "a new DSP starts on the model");
        dsp.set_params(&Params { noise_suppression: 0, ..Default::default() });
        for _ in 0..10 {
            assert!(!block(&mut dsp));
        }
        dsp.set_params(&Params::default());
        for i in 0..dfn::WARMUP_BLOCKS {
            assert!(!block(&mut dsp), "the model was heard after {i} blocks back on");
        }
        assert!(block(&mut dsp));
    }

    #[test]
    fn a_disabled_model_leaves_rnnoise_suppressing() {
        let mut dsp = Dsp::new(Params { gate_mode: 0, far_end_ducking: 0, ..Default::default() });
        assert!(dsp.has_deep_filter());
        dsp.disable_deep_filter();
        assert!(!dsp.has_deep_filter());
        let noise = coloured_noise(FRAME_SIZE * 100, 300.0, 29);
        let mut out = noise.clone();
        for block in out.chunks_mut(FRAME_SIZE) {
            dsp.process_block(block);
            assert_eq!(dsp.report().flags & REPORT_FLAG_DEEP_FILTER, 0);
        }
        assert!(rms_db(&noise) - rms_db(&out[FRAME_SIZE * 50..]) > 15.0);
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
