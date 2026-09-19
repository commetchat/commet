//! The player: control calls from Dart, a decoder thread per loaded
//! position, and `pull` from the WebRTC pacing thread.
//!
//! Every open or seek builds a new `Session` (its own ring and decoder
//! thread) and hands it to `pull` through a generation-stamped slot, so a
//! seek never has to flush a ring the consumer is reading. `pull` fades the
//! old session out before switching. Control keeps every session `pull`
//! might still hold alive in `live`, so the pacing thread never frees one.

use std::path::{Path, PathBuf};
use std::sync::atomic::{AtomicBool, AtomicI32, AtomicU32, AtomicU64, Ordering};
use std::sync::{Arc, Mutex, MutexGuard, TryLockError};
use std::thread::{self, JoinHandle};
use std::time::Duration;

use crate::resample::Resampler;
use crate::ring::{Frame, Ring};
use crate::source::{self, Source};
use crate::{ERR_ARGS, ERR_DECODER, ERR_UNSUPPORTED};

pub const OUTPUT_RATE: u32 = 48_000;
const RING_FRAMES: usize = 3 * OUTPUT_RATE as usize;
/// Pause/resume fade (20 ms).
const SLOW_STEP: f32 = 1.0 / 960.0;
/// Fade for stop/open/seek and after an underrun (5 ms).
const FAST_STEP: f32 = 1.0 / 240.0;
/// Per-frame smoothing of gain changes (about 10 ms time constant).
const GAIN_COEF: f32 = 0.002;
const MAX_GAIN: f32 = 16.0;
const CHUNK: usize = 256;

#[derive(Clone, Copy, Debug, PartialEq, Eq)]
#[repr(u32)]
pub enum State {
    Idle = 0,
    Playing = 1,
    Paused = 2,
    Ended = 3,
    Error = 4,
    Buffering = 5,
}

#[derive(Clone, Copy, Debug, PartialEq, Eq)]
pub struct Status {
    pub state: State,
    pub underruns: u32,
    pub track_id: u64,
    pub position_ms: u64,
    pub duration_ms: u64,
    pub error: i32,
}

struct Session {
    track_id: u64,
    path: PathBuf,
    start_ms: u64,
    duration_ms: u64,
    ring: Ring,
    /// Frames `pull` has taken from `ring`.
    consumed: AtomicU64,
    /// Decoder thread finished (end of file, error or stopped).
    done: AtomicBool,
    error: AtomicI32,
    stop: AtomicBool,
}

impl Session {
    fn new(
        track_id: u64,
        path: PathBuf,
        start_ms: u64,
        duration_ms: u64,
        ring_frames: usize,
    ) -> Self {
        Session {
            track_id,
            path,
            start_ms,
            duration_ms,
            ring: Ring::new(ring_frames),
            consumed: AtomicU64::new(0),
            done: AtomicBool::new(false),
            error: AtomicI32::new(0),
            stop: AtomicBool::new(false),
        }
    }
}

struct Worker {
    handle: JoinHandle<()>,
    session: Arc<Session>,
}

#[derive(Default)]
struct Control {
    current: Option<Arc<Session>>,
    worker: Option<Worker>,
    live: Vec<Arc<Session>>,
    generation: u64,
    error: i32,
    /// Track id of a failed open; state reads Error until the next call.
    failed: Option<u64>,
}

#[derive(Default)]
struct Slot {
    generation: u64,
    session: Option<Arc<Session>>,
}

struct Consumer {
    generation: u64,
    cur: Option<Arc<Session>>,
    next: Option<Arc<Session>>,
    switching: bool,
    /// Fade level, 0..1.
    level: f32,
    in_step: f32,
    gain: f32,
}

pub struct Player {
    ctrl: Mutex<Control>,
    slot: Mutex<Slot>,
    consumer: Mutex<Consumer>,
    paused: AtomicBool,
    gain_bits: AtomicU32,
    underruns: AtomicU32,
}

fn lock<T>(m: &Mutex<T>) -> MutexGuard<'_, T> {
    m.lock().unwrap_or_else(|e| e.into_inner())
}

fn try_lock<T>(m: &Mutex<T>) -> Option<MutexGuard<'_, T>> {
    match m.try_lock() {
        Ok(g) => Some(g),
        Err(TryLockError::Poisoned(e)) => Some(e.into_inner()),
        Err(TryLockError::WouldBlock) => None,
    }
}

/// Transparent below 0.85, then bends smoothly towards full scale.
fn soft_clip(x: f32) -> f32 {
    const KNEE: f32 = 0.85;
    let a = x.abs();
    if a <= KNEE {
        x
    } else {
        (KNEE + (1.0 - KNEE) * ((a - KNEE) / (1.0 - KNEE)).tanh()).copysign(x)
    }
}

fn to_i16(x: f32) -> i16 {
    // NaN casts to 0; soft_clip keeps everything else within full scale.
    (soft_clip(x) * 32767.0).round() as i16
}

fn decode_thread(session: &Session, mut src: Source) -> Result<(), i32> {
    let mut resampler: Option<(u32, Resampler)> = None;
    let mut stereo: Vec<Frame> = Vec::new();
    let mut out: Vec<Frame> = Vec::new();
    let mut out_pos = 0usize;
    let mut eof = false;
    loop {
        if session.stop.load(Ordering::Acquire) {
            return Ok(());
        }
        if out_pos < out.len() {
            out_pos += session.ring.push(&out[out_pos..]);
            if out_pos < out.len() {
                // Ring full; control unparks us to stop.
                thread::park_timeout(Duration::from_millis(10));
                continue;
            }
            out.clear();
            out_pos = 0;
        }
        if eof {
            return Ok(());
        }
        match src.decode_next(&mut stereo)? {
            None => {
                if let Some((_, r)) = resampler.as_mut() {
                    r.flush(&mut out);
                }
                eof = true;
            }
            Some(0) => {}
            Some(rate) => {
                if resampler.as_ref().map(|(r, _)| *r) != Some(rate) {
                    // First buffer, or a chained stream changed rate.
                    if let Some((_, r)) = resampler.as_mut() {
                        r.flush(&mut out);
                    }
                    resampler = Some((rate, Resampler::new(rate, OUTPUT_RATE)));
                }
                if let Some((_, r)) = resampler.as_mut() {
                    r.process(&stereo, &mut out);
                }
            }
        }
    }
}

impl Default for Player {
    fn default() -> Self {
        Self::new()
    }
}

impl Player {
    pub fn new() -> Self {
        Player {
            ctrl: Mutex::new(Control::default()),
            slot: Mutex::new(Slot::default()),
            consumer: Mutex::new(Consumer {
                generation: 0,
                cur: None,
                next: None,
                switching: false,
                level: 0.0,
                in_step: FAST_STEP,
                gain: 1.0,
            }),
            paused: AtomicBool::new(false),
            gain_bits: AtomicU32::new(1.0f32.to_bits()),
            underruns: AtomicU32::new(0),
        }
    }

    fn stop_worker(ctrl: &mut Control) {
        if let Some(w) = ctrl.worker.take() {
            w.session.stop.store(true, Ordering::Release);
            w.handle.thread().unpark();
            let _ = w.handle.join();
        }
    }

    fn publish(&self, ctrl: &mut Control, session: Option<Arc<Session>>) {
        ctrl.generation += 1;
        {
            let mut slot = lock(&self.slot);
            slot.generation = ctrl.generation;
            slot.session = session.clone();
        }
        if let Some(s) = &session {
            ctrl.live.push(s.clone());
        }
        ctrl.current = session;
        // Only `live` holds it: neither the slot, the consumer nor a thread.
        ctrl.live.retain(|s| Arc::strong_count(s) > 1);
    }

    /// Replaces the current session with one built from `opened`.
    fn start(
        &self,
        ctrl: &mut Control,
        track_id: u64,
        path: PathBuf,
        start_ms: u64,
        opened: source::Opened,
    ) -> i32 {
        Self::stop_worker(ctrl);
        let session = Arc::new(Session::new(
            track_id,
            path,
            start_ms,
            opened.duration_ms,
            RING_FRAMES,
        ));
        match opened.source {
            None => session.done.store(true, Ordering::Release),
            Some(src) => {
                let s = session.clone();
                let spawned = thread::Builder::new()
                    .name("commet-dj-decode".into())
                    .spawn(move || {
                        let r = std::panic::catch_unwind(std::panic::AssertUnwindSafe(|| {
                            decode_thread(&s, src)
                        }));
                        let code = match r {
                            Ok(Ok(())) => 0,
                            Ok(Err(code)) => code,
                            Err(_) => ERR_DECODER,
                        };
                        if code != 0 {
                            s.error.store(code, Ordering::Release);
                        }
                        s.done.store(true, Ordering::Release);
                    });
                match spawned {
                    Ok(handle) => {
                        ctrl.worker = Some(Worker {
                            handle,
                            session: session.clone(),
                        })
                    }
                    Err(_) => {
                        session.error.store(ERR_DECODER, Ordering::Release);
                        session.done.store(true, Ordering::Release);
                    }
                }
            }
        }
        self.publish(ctrl, Some(session));
        ctrl.error = 0;
        ctrl.failed = None;
        0
    }

    /// Stops whatever is loaded and opens `path` at `start_ms`. The paused
    /// flag is kept. Returns 0 or a negative error code.
    pub fn open(&self, path: &Path, start_ms: u64, track_id: u64) -> i32 {
        let mut ctrl = lock(&self.ctrl);
        let opened = std::panic::catch_unwind(std::panic::AssertUnwindSafe(|| {
            source::open(path, start_ms, None)
        }))
        .unwrap_or(Err(ERR_UNSUPPORTED));
        match opened {
            Ok(opened) => {
                self.underruns.store(0, Ordering::Relaxed);
                self.start(&mut ctrl, track_id, path.to_path_buf(), start_ms, opened)
            }
            Err(code) => {
                Self::stop_worker(&mut ctrl);
                self.publish(&mut ctrl, None);
                ctrl.error = code;
                ctrl.failed = Some(track_id);
                code
            }
        }
    }

    /// Restarts the loaded track at `ms`. On failure the current playback
    /// carries on untouched.
    pub fn seek(&self, ms: u64) -> i32 {
        let mut ctrl = lock(&self.ctrl);
        let Some(cur) = ctrl.current.clone() else {
            return ERR_ARGS;
        };
        let opened = std::panic::catch_unwind(std::panic::AssertUnwindSafe(|| {
            source::open(&cur.path, ms, Some(cur.duration_ms))
        }))
        .unwrap_or(Err(ERR_DECODER));
        match opened {
            Ok(opened) => self.start(&mut ctrl, cur.track_id, cur.path.clone(), ms, opened),
            Err(code) => code,
        }
    }

    pub fn stop(&self) {
        let mut ctrl = lock(&self.ctrl);
        Self::stop_worker(&mut ctrl);
        self.publish(&mut ctrl, None);
        ctrl.error = 0;
        ctrl.failed = None;
    }

    pub fn set_paused(&self, paused: bool) {
        self.paused.store(paused, Ordering::Relaxed);
    }

    pub fn set_gain(&self, gain: f32) {
        let g = if gain.is_finite() {
            gain.clamp(0.0, MAX_GAIN)
        } else {
            1.0
        };
        self.gain_bits.store(g.to_bits(), Ordering::Relaxed);
    }

    pub fn status(&self) -> Status {
        let ctrl = lock(&self.ctrl);
        let underruns = self.underruns.load(Ordering::Relaxed);
        let Some(s) = &ctrl.current else {
            return Status {
                state: if ctrl.failed.is_some() {
                    State::Error
                } else {
                    State::Idle
                },
                underruns,
                track_id: ctrl.failed.unwrap_or(0),
                position_ms: 0,
                duration_ms: 0,
                error: ctrl.error,
            };
        };
        let empty = s.ring.available() == 0;
        let done = s.done.load(Ordering::Acquire);
        let err = s.error.load(Ordering::Acquire);
        let state = if done && empty && err != 0 {
            State::Error
        } else if done && empty {
            State::Ended
        } else if self.paused.load(Ordering::Relaxed) {
            State::Paused
        } else if empty {
            State::Buffering
        } else {
            State::Playing
        };
        let consumed = s.consumed.load(Ordering::Relaxed);
        Status {
            state,
            underruns,
            track_id: s.track_id,
            position_ms: s.start_ms + consumed * 1000 / OUTPUT_RATE as u64,
            duration_ms: s.duration_ms,
            error: if err != 0 { err } else { ctrl.error },
        }
    }

    /// Frames waiting in the current session's ring, and whether its
    /// decoder has finished. For tests.
    #[doc(hidden)]
    pub fn buffer_state(&self) -> (usize, bool) {
        lock(&self.ctrl).current.as_ref().map_or((0, true), |s| {
            (s.ring.available(), s.done.load(Ordering::Acquire))
        })
    }

    /// Fills `out` (interleaved, `channels` per frame) with the next block
    /// at 48 kHz. Returns the frames that carried track audio. Never blocks:
    /// if the consumer state is busy the block is silence.
    pub fn pull(&self, out: &mut [i16], channels: usize, sample_rate: i32) -> usize {
        out.fill(0);
        if channels == 0 || sample_rate != OUTPUT_RATE as i32 {
            return 0;
        }
        let frames = out.len() / channels;
        let Some(mut guard) = try_lock(&self.consumer) else {
            return 0;
        };
        let c = &mut *guard;
        if let Some(slot) = try_lock(&self.slot) {
            if slot.generation != c.generation {
                c.generation = slot.generation;
                c.next = slot.session.clone();
                c.switching = true;
            }
        }
        let paused = self.paused.load(Ordering::Relaxed);
        let target_gain = f32::from_bits(self.gain_bits.load(Ordering::Relaxed));
        let mut scratch = [[0.0f32; 2]; CHUNK];
        let mut done = 0usize;
        let mut audio = 0usize;
        let mut underrun = false;
        while done < frames {
            if c.switching && (c.cur.is_none() || c.level <= 0.0) {
                // Dropping the old session here never frees it: `live` has it.
                c.cur = c.next.take();
                c.switching = false;
                c.level = 0.0;
                c.in_step = FAST_STEP;
                continue;
            }
            let Some(sess) = c.cur.as_ref() else { break };
            let fading_out = c.switching || paused;
            let out_step = if c.switching { FAST_STEP } else { SLOW_STEP };
            if fading_out && c.level <= 0.0 {
                break;
            }
            let mut want = CHUNK.min(frames - done);
            if fading_out {
                want = want.min((c.level / out_step).ceil().max(1.0) as usize);
            }
            let got = sess.ring.pop(&mut scratch[..want]);
            for (i, f) in scratch[..got].iter().enumerate() {
                if fading_out {
                    c.level = (c.level - out_step).max(0.0);
                } else if c.level < 1.0 {
                    c.level = (c.level + c.in_step).min(1.0);
                }
                c.gain += (target_gain - c.gain) * GAIN_COEF;
                let g = c.level * c.gain;
                let (l, r) = (f[0] * g, f[1] * g);
                let at = (done + i) * channels;
                if channels == 1 {
                    out[at] = to_i16((l + r) * 0.5);
                } else {
                    out[at] = to_i16(l);
                    out[at + 1] = to_i16(r);
                }
            }
            sess.consumed.fetch_add(got as u64, Ordering::Relaxed);
            done += got;
            audio += got;
            if got < want {
                if c.switching {
                    c.level = 0.0;
                    continue;
                }
                if !paused && !sess.done.load(Ordering::Acquire) {
                    underrun = true;
                    // Fade back in when data returns instead of clicking.
                    c.level = 0.0;
                    c.in_step = FAST_STEP;
                }
                break;
            }
        }
        if paused {
            c.in_step = SLOW_STEP;
        }
        if underrun {
            self.underruns.fetch_add(1, Ordering::Relaxed);
        }
        audio
    }
}

impl Drop for Player {
    fn drop(&mut self) {
        let ctrl = self.ctrl.get_mut().unwrap_or_else(|e| e.into_inner());
        Self::stop_worker(ctrl);
    }
}
