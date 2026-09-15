//! Input gate (Discord-style "input sensitivity") and far-end ducker.
//!
//! Both produce a per-frame target gain; a single smoother with separate
//! attack and release times turns that into per-sample gains so nothing
//! clicks. All time constants are expressed in 10 ms frames.

#[derive(Clone, Copy, Debug, PartialEq, Eq)]
pub enum GateMode {
    Off,
    /// Open when the frame level exceeds `threshold_db`.
    Manual,
    /// Open when RNNoise's voice probability says there is speech.
    Auto,
}

#[derive(Clone, Copy, Debug)]
pub struct GateConfig {
    pub mode: GateMode,
    pub threshold_db: f32,
    /// Gain applied while closed, in dB (negative). Never a hard mute so
    /// residual room tone stays natural.
    pub floor_db: f32,
    pub duck_enabled: bool,
    /// Extra attenuation applied while the far end is loud and we are not
    /// speaking, in dB (negative).
    pub duck_depth_db: f32,
    /// Far-end level (dBFS) above which ducking engages.
    pub duck_far_threshold_db: f32,
}

impl Default for GateConfig {
    fn default() -> Self {
        GateConfig {
            mode: GateMode::Auto,
            threshold_db: -50.0,
            floor_db: -40.0,
            duck_enabled: true,
            duck_depth_db: -20.0,
            duck_far_threshold_db: -45.0,
        }
    }
}

pub const VAD_OPEN: f32 = 0.5;
pub const VAD_CLOSE: f32 = 0.3;
/// Below this level nothing opens the gate, whatever the VAD says.
pub const SILENCE_FLOOR_DB: f32 = -70.0;
/// Frames the gate stays open after the last open condition.
pub const HOLD_FRAMES: u32 = 15; // 150 ms
/// Ducking releases faster than the gate so the ramp is not noticeable.
pub const DUCK_HOLD_FRAMES: u32 = 30; // 300 ms peak hold on far-end level
/// Local speech probability above which we refuse to duck (double talk).
pub const DUCK_VAD_VETO: f32 = 0.4;

pub fn db_to_gain(db: f32) -> f32 {
    10f32.powf(db / 20.0)
}

pub fn gain_to_db(g: f32) -> f32 {
    if g <= 1e-9 {
        -180.0
    } else {
        20.0 * g.log10()
    }
}

pub struct Gate {
    open: bool,
    hold: u32,
    current_gain: f32,
    /// per-sample one-pole coefficients
    attack_coef: f32,
    release_coef: f32,
    far_hold: u32,
    far_peak_db: f32,
}

impl Gate {
    pub fn new(sample_rate: usize) -> Gate {
        let mut g = Gate {
            open: false,
            hold: 0,
            current_gain: 1.0,
            attack_coef: 0.0,
            release_coef: 0.0,
            far_hold: 0,
            far_peak_db: -120.0,
        };
        g.set_rate(sample_rate);
        g
    }

    pub fn set_rate(&mut self, sample_rate: usize) {
        // 5 ms attack, 200 ms release. `time_constant` takes the time to
        // settle within 1 % of the target, not the exponential tau.
        self.attack_coef = time_constant(0.005, sample_rate);
        self.release_coef = time_constant(0.2, sample_rate);
    }

    pub fn reset(&mut self) {
        self.open = false;
        self.hold = 0;
        self.current_gain = 1.0;
        self.far_hold = 0;
        self.far_peak_db = -120.0;
    }

    /// Called from the render side with the far-end level of one block.
    pub fn observe_far_end(&mut self, level_db: f32) {
        if level_db >= self.far_peak_db || self.far_hold == 0 {
            self.far_peak_db = level_db;
            self.far_hold = DUCK_HOLD_FRAMES;
        }
    }

    pub fn far_level_db(&self) -> f32 {
        if self.far_hold == 0 {
            -120.0
        } else {
            self.far_peak_db
        }
    }

    pub fn is_open(&self) -> bool {
        self.open
    }

    pub fn current_gain_db(&self) -> f32 {
        gain_to_db(self.current_gain)
    }

    /// Decide the target gain for this frame and apply smoothed gain in place.
    /// `level_db` is the frame level before gating, `vad` RNNoise's speech
    /// probability (0 when noise suppression is off: we then fall back to the
    /// level threshold in Auto mode too).
    pub fn process(&mut self, cfg: &GateConfig, level_db: f32, vad: f32, have_vad: bool, buf: &mut [f32]) {
        if self.far_hold > 0 {
            self.far_hold -= 1;
        }

        let mut target = 1.0f32;

        if cfg.mode != GateMode::Off {
            let open_cond = match cfg.mode {
                GateMode::Manual => level_db > cfg.threshold_db,
                GateMode::Auto => {
                    if have_vad {
                        // hysteresis on the probability
                        let thr = if self.open { VAD_CLOSE } else { VAD_OPEN };
                        vad > thr && level_db > SILENCE_FLOOR_DB
                    } else {
                        level_db > cfg.threshold_db
                    }
                }
                GateMode::Off => true,
            };
            if open_cond {
                self.open = true;
                self.hold = HOLD_FRAMES;
            } else if self.hold > 0 {
                self.hold -= 1;
            } else {
                self.open = false;
            }
            if !self.open {
                target *= db_to_gain(cfg.floor_db);
            }
        } else {
            self.open = true;
        }

        if cfg.duck_enabled && self.far_hold > 0 && self.far_peak_db > cfg.duck_far_threshold_db {
            let speaking = if have_vad { vad > DUCK_VAD_VETO } else { level_db > cfg.threshold_db };
            if !speaking {
                target *= db_to_gain(cfg.duck_depth_db);
            }
        }

        // Smooth towards target per sample.
        let mut g = self.current_gain;
        for s in buf.iter_mut() {
            let coef = if target > g { self.attack_coef } else { self.release_coef };
            g += (target - g) * coef;
            *s *= g;
        }
        self.current_gain = g;
    }
}

fn time_constant(seconds: f32, sample_rate: usize) -> f32 {
    // Settle to within 1 % (about 4.6 time constants) in `seconds`.
    let n = seconds * sample_rate as f32 / 4.6;
    if n <= 1.0 {
        1.0
    } else {
        1.0 - (-1.0 / n).exp()
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    fn frame(v: f32) -> Vec<f32> {
        vec![v; 480]
    }

    #[test]
    fn manual_gate_closes_below_threshold_and_opens_above() {
        let cfg = GateConfig { mode: GateMode::Manual, threshold_db: -30.0, ..Default::default() };
        let mut g = Gate::new(48000);
        // 60 quiet frames: hold expires, gain reaches the floor.
        let mut b = frame(1000.0);
        for _ in 0..60 {
            b = frame(1000.0);
            g.process(&cfg, -50.0, 0.0, false, &mut b);
        }
        assert!(!g.is_open());
        let floor = db_to_gain(cfg.floor_db);
        assert!((b[479] / 1000.0 - floor).abs() < 0.02, "closed gain {}", b[479] / 1000.0);
        // Loud frame: opens within the frame (5 ms attack).
        let mut b = frame(1000.0);
        g.process(&cfg, -10.0, 0.0, false, &mut b);
        assert!(g.is_open());
        assert!(b[479] / 1000.0 > 0.9, "open gain {}", b[479] / 1000.0);
    }

    #[test]
    fn auto_gate_uses_vad_with_hysteresis_and_hold() {
        let cfg = GateConfig { mode: GateMode::Auto, ..Default::default() };
        let mut g = Gate::new(48000);
        let mut b = frame(1.0);
        g.process(&cfg, -20.0, 0.9, true, &mut b);
        assert!(g.is_open());
        // vad drops to 0.4: above close threshold, stays open.
        g.process(&cfg, -20.0, 0.4, true, &mut b);
        assert!(g.is_open());
        // vad 0.1 for fewer than HOLD_FRAMES frames keeps it open (hold).
        for _ in 0..(HOLD_FRAMES - 1) {
            g.process(&cfg, -20.0, 0.1, true, &mut b);
        }
        assert!(g.is_open());
        g.process(&cfg, -20.0, 0.1, true, &mut b);
        g.process(&cfg, -20.0, 0.1, true, &mut b);
        assert!(!g.is_open());
    }

    #[test]
    fn ducking_only_when_far_end_loud_and_we_are_silent() {
        let cfg = GateConfig { mode: GateMode::Off, ..Default::default() };
        let mut g = Gate::new(48000);
        g.observe_far_end(-20.0);
        let mut b = frame(1000.0);
        for _ in 0..40 {
            b = frame(1000.0);
            g.observe_far_end(-20.0);
            g.process(&cfg, -30.0, 0.05, true, &mut b);
        }
        let ducked = b[479] / 1000.0;
        assert!((gain_to_db(ducked) - cfg.duck_depth_db).abs() < 1.0, "ducked {}", gain_to_db(ducked));
        // Local speech vetoes ducking.
        for _ in 0..40 {
            b = frame(1000.0);
            g.observe_far_end(-20.0);
            g.process(&cfg, -20.0, 0.9, true, &mut b);
        }
        assert!(b[479] / 1000.0 > 0.95);
    }
}
