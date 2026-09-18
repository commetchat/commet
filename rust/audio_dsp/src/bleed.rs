//! Loudspeaker bleed detection against a reference signal.
//!
//! RNNoise's voice probability cannot tell the user's voice from a voice
//! coming out of their loudspeakers, so the gate alone lets a video playing
//! next to the microphone straight through (see `tests/speaker_bleed.rs`).
//! What can tell them apart is a copy of what the loudspeakers are playing:
//! the system mix (WASAPI loopback, PulseAudio monitor) or WebRTC's own
//! playout. Given that reference, bleed is whatever part of the microphone
//! the reference explains.
//!
//! The model is deliberately simple, on 10 ms levels in dB, measured between
//! `BAND_HZ` and `BAND_TOP_HZ` on both sides (small loudspeakers do not
//! reproduce either end faithfully, so a reference level dominated by bass
//! or cymbals would not match the microphone):
//!
//! * bleed sits `coupling` dB relative to the reference (speaker volume,
//!   distance, room and mic gain all folded in), `lag` frames behind it;
//! * the lag is a physical constant (device buffers plus air), so it is
//!   established over many 300 ms windows: each window correlates the
//!   microphone's envelope with the reference's at every candidate lag, and
//!   a running average per lag has to single one out. Two unrelated signals
//!   (the user talking over a film) correlate by chance now and then, but
//!   not consistently at the same lag. The average is symmetric on purpose:
//!   one that rose faster than it fell would settle on a high percentile of
//!   those chance correlations and, given time, establish a lag for a
//!   headset;
//! * while a lag is established, windows that correlate at it are bleed and
//!   teach the coupling (their peak difference; the estimate is the median).
//!   Windows where the user talks do not follow the reference and never move
//!   it; windows after a volume change still follow it, so the estimate
//!   tracks volume;
//! * a frame is the user talking if the microphone is `TALK_MARGIN_DB`
//!   above the bleed the reference predicts, otherwise it is bleed.
//!
//! No reference, a silent reference, no established lag or no estimate yet
//! all report `Idle` and leave the gate to its usual rules. That covers a
//! headset (nothing in the microphone follows the reference), the speakers
//! being unplugged (the lag fades within a few windows) and the user talking
//! without a break (same: their voice does not follow the reference, the
//! detector steps aside, the voice goes through; the lag comes back within a
//! second of them stopping, the coupling is kept).
//!
//! Everything is fixed size; nothing here allocates after construction.

/// Reference level (dBFS) below which the loudspeakers count as silent.
pub const REF_ACTIVE_DB: f32 = -50.0;
/// Frames per learning window, and the span of the reference peak used for
/// prediction.
pub const WINDOW_FRAMES: usize = 30;
/// Largest reference-to-microphone delay searched, frames. Covers device
/// buffers plus air on every platform we feed.
pub const MAX_LAG_FRAMES: usize = 12;
/// How far above the predicted bleed the microphone has to be to count as
/// the user talking.
pub const TALK_MARGIN_DB: f32 = 6.0;
/// A lower bar for "the loudspeakers do not explain this frame" when deciding
/// whether a window may vote on the lag: the user's quieter syllables mixed
/// into the bleed do not make a frame `Talk`, but they do spoil the window's
/// correlation, and letting such windows vote erodes the lag in every
/// conversation.
const UNEXPLAINED_MARGIN_DB: f32 = 3.0;
/// Envelope correlation, at the established lag, above which a window is
/// treated as bleed.
pub const BLEED_CORRELATION: f32 = 0.6;
/// The same, for a window mostly judged `Talk`: only bleed that got louder
/// (speakers turned up) follows the reference that closely.
pub const LOUDER_BLEED_CORRELATION: f32 = 0.85;
/// Running average correlation a lag needs before it counts as established.
pub const LAG_CONFIDENCE: f32 = 0.5;
/// Weight of each new window in the per-lag running averages.
const LAG_SMOOTHING: f32 = 0.25;
/// How fast the prediction decays after the reference stops, dB per frame.
/// 1 dB / 10 ms is slower than any room people sit in (a 0.4 s RT60 is
/// 1.5), so the reverb tail stays inside the prediction.
const TAIL_DECAY_DB: f32 = 1.0;
/// Levels are measured above this frequency on both sides ...
pub const BAND_HZ: f32 = 250.0;
/// ... and below this one: desktop speakers and rooms are least faithful at
/// the ends, and a hi-hat above the speaker's range would otherwise read as a
/// reference the microphone cannot follow.
pub const BAND_TOP_HZ: f32 = 4000.0;
/// A window whose reference envelope moves less than this (dB standard
/// deviation) carries no shape to correlate against and is skipped.
const MIN_REF_SPREAD_DB: f32 = 2.0;
/// Frames of a window the reference has to be playing in before the window
/// says anything about the lag.
const MIN_ACTIVE_FRAMES: usize = WINDOW_FRAMES / 3;
/// Learned windows kept; the estimate is their median.
const HISTORY: usize = 16;
/// Windows needed before the estimate is used.
const MIN_WINDOWS: usize = 1;
/// Levels are floored here before any statistics, so digital silence does
/// not dominate a correlation.
const FLOOR_DB: f32 = -90.0;

#[derive(Clone, Copy, Debug, PartialEq, Eq)]
pub enum Verdict {
    /// No reference, reference silent, or nothing learned yet.
    Idle,
    /// The microphone holds nothing the reference does not explain.
    Bleed,
    /// The microphone is well above the predicted bleed: the user.
    Talk,
}

const RING: usize = WINDOW_FRAMES + MAX_LAG_FRAMES;
const LAGS: usize = MAX_LAG_FRAMES + 1;

pub struct BleedEstimator {
    /// Reference levels, the last `RING` frames.
    ref_ring: [f32; RING],
    /// Microphone levels of the current window.
    mic_win: [f32; WINDOW_FRAMES],
    pos: usize,
    win_n: usize,
    /// Frames of the current window louder than the last learned coupling
    /// explains.
    win_unexplained: usize,
    /// Frames seen in total, so the lag search never reads frames that were
    /// never written.
    seen: usize,
    /// Running average correlation per candidate lag.
    lag_score: [f32; LAGS],
    history: [f32; HISTORY],
    hist_len: usize,
    hist_pos: usize,
    scratch: [f32; HISTORY],
    coupling_db: Option<f32>,
    /// Reference level the prediction uses: the recent peak, decaying like
    /// a room once the reference stops.
    tail_db: f32,
}

impl Default for BleedEstimator {
    fn default() -> Self {
        Self::new()
    }
}

impl BleedEstimator {
    pub fn new() -> BleedEstimator {
        BleedEstimator {
            ref_ring: [FLOOR_DB; RING],
            mic_win: [FLOOR_DB; WINDOW_FRAMES],
            pos: 0,
            win_n: 0,
            win_unexplained: 0,
            seen: 0,
            lag_score: [0.0; LAGS],
            history: [0.0; HISTORY],
            hist_len: 0,
            hist_pos: 0,
            scratch: [0.0; HISTORY],
            coupling_db: None,
            tail_db: FLOOR_DB,
        }
    }

    pub fn reset(&mut self) {
        *self = BleedEstimator::new();
    }

    /// The established reference-to-microphone lag in frames, if any.
    pub fn lag(&self) -> Option<usize> {
        let (best, score) = self
            .lag_score
            .iter()
            .enumerate()
            .fold((0, f32::MIN), |acc, (i, &s)| if s > acc.1 { (i, s) } else { acc });
        (score > LAG_CONFIDENCE).then_some(best)
    }

    /// Learned reference-to-microphone coupling in dB, while it is usable
    /// (a lag is established).
    pub fn coupling_db(&self) -> Option<f32> {
        self.lag().and(self.coupling_db)
    }

    /// Reference level `back` frames ago (0 = this frame).
    fn ref_at(&self, back: usize) -> f32 {
        self.ref_ring[(self.pos + RING - 1 - back) % RING]
    }

    /// Feed one 10 ms frame: the microphone level before any processing and
    /// the reference level for the same period, both from a `BandLevel`
    /// (dBFS; anything at or below -120 means no reference audio arrived).
    pub fn update(&mut self, mic_db: f32, ref_db: f32) -> Verdict {
        let mic_db = mic_db.max(FLOOR_DB);
        let ref_db = ref_db.max(FLOOR_DB);
        self.ref_ring[self.pos] = ref_db;
        self.pos = (self.pos + 1) % RING;
        self.seen += 1;

        // The loudest reference in the last window covers the lag; after the
        // reference stops, the room keeps ringing, so the prediction decays
        // instead of dropping.
        let mut ref_peak = FLOOR_DB;
        for back in 0..WINDOW_FRAMES {
            ref_peak = ref_peak.max(self.ref_at(back));
        }
        self.tail_db = if ref_peak >= self.tail_db {
            ref_peak
        } else {
            (self.tail_db - TAIL_DECAY_DB).max(ref_peak)
        };

        let verdict = if self.tail_db <= REF_ACTIVE_DB {
            Verdict::Idle
        } else {
            match self.coupling_db() {
                None => Verdict::Idle,
                Some(c) if mic_db > self.tail_db + c + TALK_MARGIN_DB => Verdict::Talk,
                Some(_) => Verdict::Bleed,
            }
        };

        // Judged against the last coupling learned even while the lag is not
        // confirmed: once the user's voice has eroded the lag, every frame
        // is Idle, and counting only Talk verdicts would let their voice keep
        // it eroded.
        let unexplained = self.tail_db > REF_ACTIVE_DB
            && self.coupling_db.is_some_and(|c| mic_db > self.tail_db + c + UNEXPLAINED_MARGIN_DB);

        self.mic_win[self.win_n] = mic_db;
        self.win_n += 1;
        if unexplained {
            self.win_unexplained += 1;
        }
        if self.win_n == WINDOW_FRAMES {
            self.learn_window();
            self.win_n = 0;
            self.win_unexplained = 0;
        }
        verdict
    }

    /// Correlation of the current window's microphone envelope with the
    /// reference `lag` frames earlier, over the frames where the reference
    /// is playing: below that the microphone sits on its own noise floor and
    /// cannot follow the reference down, which would read as "unrelated".
    /// None when too few frames are playing or the reference is too flat to
    /// say anything.
    fn correlation(&self, lag: usize) -> Option<f32> {
        const W: usize = WINDOW_FRAMES;
        // mic_win[i] pairs with ref_at(W - 1 - i + lag)
        let active = |i: usize| self.ref_at(W - 1 - i + lag) > REF_ACTIVE_DB;
        let (mut sm, mut sr, mut n) = (0.0f32, 0.0f32, 0usize);
        for i in (0..W).filter(|&i| active(i)) {
            sm += self.mic_win[i];
            sr += self.ref_at(W - 1 - i + lag);
            n += 1;
        }
        if n < MIN_ACTIVE_FRAMES {
            return None;
        }
        let (mm, mr) = (sm / n as f32, sr / n as f32);
        let (mut cov, mut vm, mut vr) = (0.0f32, 0.0f32, 0.0f32);
        for i in (0..W).filter(|&i| active(i)) {
            let dm = self.mic_win[i] - mm;
            let dr = self.ref_at(W - 1 - i + lag) - mr;
            cov += dm * dr;
            vm += dm * dm;
            vr += dr * dr;
        }
        if (vr / n as f32).sqrt() < MIN_REF_SPREAD_DB {
            return None;
        }
        if vm <= 0.0 {
            return Some(0.0);
        }
        Some(cov / (vm.sqrt() * vr.sqrt()))
    }

    /// Called when a window of `WINDOW_FRAMES` microphone frames is complete.
    fn learn_window(&mut self) {
        if self.seen < RING {
            return;
        }
        const W: usize = WINDOW_FRAMES;

        let mut ref_max = FLOOR_DB;
        for i in 0..W {
            ref_max = ref_max.max(self.ref_at(W - 1 - i));
        }
        if ref_max <= REF_ACTIVE_DB {
            return;
        }
        let mut at_lag = [None; LAGS];
        for (lag, r) in at_lag.iter_mut().enumerate() {
            *r = self.correlation(lag);
        }

        // Every lag's running average moves, so a lag that stops explaining
        // the microphone fades out. Except in a window the user talked
        // through (a quarter of it louder than the loudspeakers account for):
        // that says nothing about whether the loudspeakers still reach the
        // microphone, and letting it vote would erode the lag in every
        // conversation and let the video through the gaps between sentences.
        let talked_through = self.win_unexplained * 4 > W;
        if !talked_through {
            for (score, r) in self.lag_score.iter_mut().zip(at_lag.iter()) {
                if let Some(r) = r {
                    *score += (r - *score) * LAG_SMOOTHING;
                }
            }
        }

        // Learn the coupling from windows that follow the reference at the
        // established lag. That includes "talk" windows that do: bleed that
        // got louder (the speakers were turned up) still follows the
        // reference, a voice does not.
        let Some(lag) = self.lag() else { return };
        let needed = if talked_through { LOUDER_BLEED_CORRELATION } else { BLEED_CORRELATION };
        match at_lag[lag] {
            Some(r) if r >= needed => {}
            _ => return,
        }

        let mut mic_max = FLOOR_DB;
        let mut ref_max_lagged = FLOOR_DB;
        for i in 0..W {
            mic_max = mic_max.max(self.mic_win[i]);
            ref_max_lagged = ref_max_lagged.max(self.ref_at(W - 1 - i + lag));
        }
        self.history[self.hist_pos] = mic_max - ref_max_lagged;
        self.hist_pos = (self.hist_pos + 1) % HISTORY;
        self.hist_len = (self.hist_len + 1).min(HISTORY);
        if self.hist_len >= MIN_WINDOWS {
            let s = &mut self.scratch[..self.hist_len];
            s.copy_from_slice(&self.history[..self.hist_len]);
            s.sort_unstable_by(|a, b| a.partial_cmp(b).unwrap_or(std::cmp::Ordering::Equal));
            self.coupling_db = Some(s[s.len() / 2]);
        }
    }
}

/// Level of a signal between `BAND_HZ` and `BAND_TOP_HZ`: second order
/// Butterworth high- and low-pass in front of an RMS meter. One per signal,
/// state carried across blocks.
pub struct BandLevel {
    rate: usize,
    hp: Biquad,
    lp: Biquad,
}

#[derive(Clone, Copy, Default)]
struct Biquad {
    b: [f32; 3],
    a: [f32; 2],
    z: [f32; 2],
}

impl Biquad {
    fn butterworth(rate: usize, hz: f32, high_pass: bool) -> Biquad {
        let w = 2.0 * std::f32::consts::PI * hz / rate as f32;
        let (sin, cos) = w.sin_cos();
        let alpha = sin / std::f32::consts::SQRT_2; // Q = 1/sqrt(2)
        let a0 = 1.0 + alpha;
        let b = if high_pass {
            [(1.0 + cos) / 2.0, -(1.0 + cos), (1.0 + cos) / 2.0]
        } else {
            [(1.0 - cos) / 2.0, 1.0 - cos, (1.0 - cos) / 2.0]
        };
        Biquad {
            b: [b[0] / a0, b[1] / a0, b[2] / a0],
            a: [-2.0 * cos / a0, (1.0 - alpha) / a0],
            z: [0.0; 2],
        }
    }

    #[inline]
    fn run(&mut self, x: f32) -> f32 {
        // transposed direct form II
        let y = self.b[0] * x + self.z[0];
        self.z[0] = self.b[1] * x - self.a[0] * y + self.z[1];
        self.z[1] = self.b[2] * x - self.a[1] * y;
        y
    }
}

impl Default for BandLevel {
    fn default() -> Self {
        Self::new()
    }
}

impl BandLevel {
    pub fn new() -> BandLevel {
        let mut b = BandLevel { rate: 0, hp: Biquad::default(), lp: Biquad::default() };
        b.set_rate(48_000);
        b
    }

    fn set_rate(&mut self, rate: usize) {
        if rate == self.rate || rate == 0 {
            return;
        }
        self.rate = rate;
        self.hp = Biquad::butterworth(rate, BAND_HZ, true);
        // Keep the top edge below Nyquist at 16 kHz.
        self.lp = Biquad::butterworth(rate, BAND_TOP_HZ.min(rate as f32 * 0.45), false);
    }

    /// dBFS of int16-scale samples inside the band. `samples` yields one
    /// mono value per frame at `rate`.
    pub fn measure(&mut self, rate: usize, samples: impl Iterator<Item = f32>) -> f32 {
        self.set_rate(rate);
        let (mut sum, mut n) = (0.0f32, 0usize);
        for x in samples {
            let y = self.lp.run(self.hp.run(x));
            sum += y * y;
            n += 1;
        }
        if n == 0 {
            return -120.0;
        }
        let rms = (sum / n as f32).sqrt() / 32768.0;
        if rms <= 1e-6 {
            -120.0
        } else {
            (20.0 * rms.log10()).max(-120.0)
        }
    }

    pub fn reset(&mut self) {
        self.hp.z = [0.0; 2];
        self.lp.z = [0.0; 2];
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    /// A reference envelope with syllable-like movement.
    fn envelope(i: usize) -> f32 {
        let t = i as f32 * 0.01;
        -25.0 + 10.0 * (t * 7.0).sin() + 5.0 * (t * 2.3).cos()
    }

    fn learn(e: &mut BleedEstimator, frames: std::ops::Range<usize>, coupling: f32) -> Verdict {
        let mut last = Verdict::Idle;
        for i in frames {
            // the microphone hears the reference `coupling` dB off, 3 frames late
            last = e.update(envelope(i.saturating_sub(3)) + coupling, envelope(i));
        }
        last
    }

    #[test]
    fn idle_without_a_reference() {
        let mut e = BleedEstimator::new();
        for _ in 0..500 {
            assert_eq!(e.update(-30.0, -120.0), Verdict::Idle);
        }
        assert_eq!(e.coupling_db(), None);
    }

    #[test]
    fn learns_the_lag_and_the_coupling_and_calls_it_bleed() {
        let mut e = BleedEstimator::new();
        let last = learn(&mut e, 0..600, -14.0);
        assert_eq!(e.lag(), Some(3));
        let c = e.coupling_db().expect("learned");
        assert!((c + 14.0).abs() < 2.0, "coupling {c}");
        assert_eq!(last, Verdict::Bleed);
    }

    #[test]
    fn the_user_talking_over_it_is_never_bleed_and_does_not_move_the_estimate() {
        let mut e = BleedEstimator::new();
        learn(&mut e, 0..600, -14.0);
        let before = e.coupling_db().unwrap();
        // 10 s of the user talking without a break: syllables at about 5 Hz
        // on a slow drift, clear of the loudest bleed (-24 dBFS here) by
        // more than the talk margin. How close to the bleed a real voice
        // gets is measured on recordings in tests/speaker_bleed.rs.
        for i in 600..1600 {
            let t = i as f32;
            let voice = -15.0 + 5.0 * (t * 0.16).sin().abs() + 2.0 * (t * 0.013).sin();
            assert_ne!(e.update(voice, envelope(i)), Verdict::Bleed, "frame {i}");
        }
        // They stop; the bleed is recognised again within a second, with
        // the coupling it had.
        let mut back = None;
        for i in 1600..2000 {
            let v = e.update(envelope(i - 3) - 14.0, envelope(i));
            if v == Verdict::Bleed && back.is_none() {
                back = Some(i - 1600);
            }
        }
        let back = back.expect("bleed never recognised again");
        assert!(back <= 100, "took {} ms to come back", back * 10);
        let after = e.coupling_db().unwrap();
        assert!((after - before).abs() < 1.0, "estimate moved {before} -> {after}");
    }

    #[test]
    fn follows_a_volume_change() {
        let mut e = BleedEstimator::new();
        learn(&mut e, 0..600, -20.0);
        learn(&mut e, 600..1200, -8.0);
        let c = e.coupling_db().unwrap();
        assert!((c + 8.0).abs() < 2.0, "coupling {c}");
    }

    #[test]
    fn a_headset_never_learns_anything() {
        // The reference plays, the microphone hears only its own noise floor.
        let mut e = BleedEstimator::new();
        let mut state = 1u32;
        for i in 0..1000 {
            state = state.wrapping_mul(1664525).wrapping_add(1013904223);
            let noise = -65.0 + (state >> 28) as f32 * 0.2;
            assert_eq!(e.update(noise, envelope(i)), Verdict::Idle);
        }
    }

    #[test]
    fn unplugging_the_speakers_goes_back_to_idle() {
        let mut e = BleedEstimator::new();
        learn(&mut e, 0..600, -14.0);
        let mut state = 7u32;
        let mut idle_from = None;
        for i in 600..1200 {
            state = state.wrapping_mul(1664525).wrapping_add(1013904223);
            let noise = -65.0 + (state >> 28) as f32 * 0.2;
            if e.update(noise, envelope(i)) == Verdict::Idle && idle_from.is_none() {
                idle_from = Some(i - 600);
            }
        }
        let t = idle_from.expect("never went idle");
        assert!(t <= 300, "still using the old coupling after {} ms", t * 10);
        assert_eq!(e.lag(), None);
    }

    #[test]
    fn band_level_ignores_bass() {
        let mut b = BandLevel::new();
        let tone = |hz: f32| (0..4800).map(move |i| (2.0 * std::f32::consts::PI * hz * i as f32 / 48_000.0).sin() * 10_000.0);
        let low = b.measure(48_000, tone(60.0));
        b.reset();
        let mid = b.measure(48_000, tone(1000.0));
        // two octaves below the edge at 12 dB per octave
        assert!(mid - low > 20.0, "60 Hz {low:.1} dBFS, 1 kHz {mid:.1} dBFS");
    }
}
