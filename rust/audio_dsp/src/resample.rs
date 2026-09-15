//! Small rational resampler (windowed-sinc FIR) used to move 10 ms blocks
//! between the rate WebRTC hands us (16 / 32 / 48 kHz) and the 48 kHz that
//! RNNoise was trained on.
//!
//! Everything is preallocated in `new`; `process` never allocates.

const TAPS_PER_PHASE: usize = 16;

fn gcd(a: usize, b: usize) -> usize {
    if b == 0 {
        a
    } else {
        gcd(b, a % b)
    }
}

pub struct Resampler {
    up: usize,
    down: usize,
    /// FIR coefficients at the intermediate rate, already scaled by `up`.
    taps: Vec<f32>,
    /// Delay line of input samples (most recent last).
    history: Vec<f32>,
    /// Phase accumulator into the intermediate (upsampled) stream.
    phase: usize,
}

impl Resampler {
    pub fn new(from_hz: usize, to_hz: usize) -> Resampler {
        let g = gcd(from_hz, to_hz);
        let up = to_hz / g;
        let down = from_hz / g;
        let n_taps = TAPS_PER_PHASE * up.max(down);
        let n_taps = if n_taps % 2 == 0 { n_taps + 1 } else { n_taps };
        // Cutoff at the lower Nyquist, expressed relative to the intermediate rate.
        let inter_hz = (from_hz * up) as f32;
        let cutoff = (from_hz.min(to_hz) as f32) * 0.5 * 0.92;
        let fc = cutoff / inter_hz; // cycles per sample at intermediate rate
        let mid = (n_taps / 2) as f32;
        let mut taps = Vec::with_capacity(n_taps);
        for i in 0..n_taps {
            let x = i as f32 - mid;
            let sinc = if x == 0.0 {
                2.0 * fc
            } else {
                (2.0 * std::f32::consts::PI * fc * x).sin() / (std::f32::consts::PI * x)
            };
            // Blackman window
            let w = 0.42 - 0.5 * (2.0 * std::f32::consts::PI * i as f32 / (n_taps - 1) as f32).cos()
                + 0.08 * (4.0 * std::f32::consts::PI * i as f32 / (n_taps - 1) as f32).cos();
            taps.push(sinc * w * up as f32);
        }
        let hist_len = n_taps / up + 2;
        Resampler {
            up,
            down,
            taps,
            history: vec![0.0; hist_len],
            phase: 0,
        }
    }

    pub fn reset(&mut self) {
        for h in self.history.iter_mut() {
            *h = 0.0;
        }
        self.phase = 0;
    }

    /// Number of output samples produced for `n_in` input samples, assuming the
    /// caller always feeds blocks for which the ratio is exact.
    pub fn output_len(&self, n_in: usize) -> usize {
        n_in * self.up / self.down
    }

    /// Resample `input` into `output`. `output.len()` must equal
    /// `output_len(input.len())`.
    pub fn process(&mut self, input: &[f32], output: &mut [f32]) {
        debug_assert_eq!(output.len(), self.output_len(input.len()));
        let hist_len = self.history.len();
        let n_taps = self.taps.len();
        let mut out_i = 0;
        // Intermediate index of the next output sample relative to the start of
        // this block, expressed as (input index, sub-phase).
        for &x in input.iter() {
            // push sample into delay line
            self.history.copy_within(1.., 0);
            self.history[hist_len - 1] = x;
            // The intermediate stream has `up` slots per input sample; slot 0 of
            // input sample in_i is intermediate index in_i*up. We emit an output
            // whenever the phase accumulator lands inside this input sample.
            while self.phase < self.up && out_i < output.len() {
                // Output sample at intermediate index t = in_i*up + phase.
                // Convolve: y = sum_j taps[j] * x_up[t - j], x_up nonzero only at
                // multiples of `up`. Nonzero j satisfy (phase - j) % up == 0.
                let mut acc = 0.0f32;
                let mut j = self.phase;
                let mut k = 0usize; // how many input samples back
                while j < n_taps && k < hist_len {
                    acc += self.taps[j] * self.history[hist_len - 1 - k];
                    j += self.up;
                    k += 1;
                }
                output[out_i] = acc;
                out_i += 1;
                self.phase += self.down;
            }
            self.phase -= self.up;
        }
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    fn sine(hz: f32, rate: usize, n: usize) -> Vec<f32> {
        (0..n)
            .map(|i| (2.0 * std::f32::consts::PI * hz * i as f32 / rate as f32).sin())
            .collect()
    }

    fn rms(x: &[f32]) -> f32 {
        (x.iter().map(|v| v * v).sum::<f32>() / x.len() as f32).sqrt()
    }

    #[test]
    fn lengths_are_exact_for_ten_ms_blocks() {
        let r = Resampler::new(16000, 48000);
        assert_eq!(r.output_len(160), 480);
        let r = Resampler::new(32000, 48000);
        assert_eq!(r.output_len(320), 480);
        let r = Resampler::new(48000, 32000);
        assert_eq!(r.output_len(480), 320);
        let r = Resampler::new(48000, 16000);
        assert_eq!(r.output_len(480), 160);
    }

    #[test]
    fn upsample_preserves_a_low_tone() {
        let mut r = Resampler::new(16000, 48000);
        let input = sine(440.0, 16000, 160 * 20);
        let mut out = vec![0.0; 480 * 20];
        for (i, block) in input.chunks(160).enumerate() {
            r.process(block, &mut out[i * 480..(i + 1) * 480]);
        }
        // skip the warm-up
        let tail = &out[480 * 5..];
        let ref_sig = sine(440.0, 48000, 480 * 20);
        let level = rms(tail) / rms(&ref_sig[480 * 5..]);
        assert!((level - 1.0).abs() < 0.05, "level ratio {level}");
    }

    #[test]
    fn round_trip_32k_keeps_level() {
        let mut up = Resampler::new(32000, 48000);
        let mut down = Resampler::new(48000, 32000);
        let input = sine(1000.0, 32000, 320 * 20);
        let mut mid = vec![0.0; 480];
        let mut out = vec![0.0; 320 * 20];
        for (i, block) in input.chunks(320).enumerate() {
            up.process(block, &mut mid);
            down.process(&mid, &mut out[i * 320..(i + 1) * 320]);
        }
        let level = rms(&out[320 * 5..]) / rms(&input[320 * 5..]);
        assert!((level - 1.0).abs() < 0.05, "level ratio {level}");
    }

    #[test]
    fn downsample_rejects_above_nyquist() {
        let mut down = Resampler::new(48000, 16000);
        // 12 kHz is above the 8 kHz Nyquist of 16 kHz output; must be attenuated.
        let input = sine(12000.0, 48000, 480 * 20);
        let mut out = vec![0.0; 160 * 20];
        for (i, block) in input.chunks(480).enumerate() {
            down.process(block, &mut out[i * 160..(i + 1) * 160]);
        }
        let level = rms(&out[160 * 5..]) / rms(&input[480 * 5..]);
        assert!(level < 0.05, "aliasing level {level}");
    }
}
