//! Streaming windowed-sinc resampler for any rate pair.
//!
//! Output frame `n` is the band-limited input evaluated at `n * in / out`,
//! tracked as an exact rational so long tracks never drift. The kernel is a
//! Kaiser-windowed sinc tabulated at `PHASES` sub-sample offsets and linearly
//! interpolated between them. The cutoff sits just under the lower Nyquist,
//! so upsampling 44.1 kHz keeps the audible band flat and downsampling
//! rejects everything that would fold back. There is no added latency:
//! output time zero is input time zero, which keeps positions exact.

use crate::ring::Frame;

const PHASES: usize = 512;
/// Kernel half-width in zero crossings of the lower rate.
const ZERO_CROSSINGS: usize = 48;
/// Cutoff as a fraction of the lower Nyquist frequency.
const CUTOFF: f64 = 0.92;
/// Around 90 dB of stopband.
const KAISER_BETA: f64 = 9.0;
/// Lowest supported out/in ratio (e.g. 768 kHz to 48 kHz).
const MIN_SCALE: f64 = 1.0 / 16.0;

pub(crate) struct Resampler {
    /// Each output frame advances the input position by `m / l` frames.
    l: u64,
    m: u64,
    /// Kernel reaches `half - 1` frames back and `half` frames forward.
    half: usize,
    taps: usize,
    table: Vec<f32>,
    coeffs: Vec<f32>,
    hist: Vec<Frame>,
    /// Input index of `hist[0]`.
    base: i64,
    ipos: i64,
    frac: u64,
    /// Real (non-padding) input frames fed so far.
    fed: i64,
    passthrough: bool,
}

fn gcd(a: u64, b: u64) -> u64 {
    if b == 0 {
        a
    } else {
        gcd(b, a % b)
    }
}

fn bessel_i0(x: f64) -> f64 {
    let mut sum = 1.0;
    let mut term = 1.0;
    let q = x * x / 4.0;
    for k in 1..64 {
        term *= q / (k * k) as f64;
        sum += term;
        if term < sum * 1e-12 {
            break;
        }
    }
    sum
}

impl Resampler {
    pub fn new(in_rate: u32, out_rate: u32) -> Self {
        let in_rate = in_rate.max(1) as u64;
        let out_rate = out_rate.max(1) as u64;
        let g = gcd(in_rate, out_rate);
        let (l, m) = (out_rate / g, in_rate / g);
        let passthrough = l == m;
        let scale = (out_rate as f64 / in_rate as f64).clamp(MIN_SCALE, 1.0);
        let half = if passthrough {
            1
        } else {
            (ZERO_CROSSINGS as f64 / scale).ceil() as usize
        };
        let taps = 2 * half;
        // Cutoff in cycles per input frame.
        let fc = 0.5 * CUTOFF * scale;
        let mut table = Vec::new();
        if !passthrough {
            table.reserve((PHASES + 1) * taps);
            let i0_beta = bessel_i0(KAISER_BETA);
            for j in 0..=PHASES {
                let p = j as f64 / PHASES as f64;
                let start = table.len();
                for k in 0..taps {
                    // Distance from the output instant to input tap k.
                    let x = k as f64 - (half as f64 - 1.0) - p;
                    let u = x / half as f64;
                    let w = if u.abs() >= 1.0 {
                        0.0
                    } else {
                        bessel_i0(KAISER_BETA * (1.0 - u * u).sqrt()) / i0_beta
                    };
                    let arg = 2.0 * fc * x;
                    let sinc = if arg.abs() < 1e-12 {
                        1.0
                    } else {
                        (std::f64::consts::PI * arg).sin() / (std::f64::consts::PI * arg)
                    };
                    table.push((2.0 * fc * sinc * w) as f32);
                }
                // Unity DC gain at every phase.
                let sum: f32 = table[start..].iter().sum();
                if sum.abs() > 1e-6 {
                    table[start..].iter_mut().for_each(|c| *c /= sum);
                }
            }
        }
        Resampler {
            l,
            m,
            half,
            taps,
            table,
            coeffs: vec![0.0; taps],
            hist: vec![[0.0; 2]; half - 1],
            base: -(half as i64 - 1),
            ipos: 0,
            frac: 0,
            fed: 0,
            passthrough,
        }
    }

    pub fn process(&mut self, input: &[Frame], out: &mut Vec<Frame>) {
        if self.passthrough {
            out.extend_from_slice(input);
            return;
        }
        self.hist.extend_from_slice(input);
        self.fed += input.len() as i64;
        self.run(out, None);
    }

    /// Emits the tail: every output instant before the end of the input.
    pub fn flush(&mut self, out: &mut Vec<Frame>) {
        if self.passthrough {
            return;
        }
        self.hist.resize(self.hist.len() + self.half + 1, [0.0; 2]);
        let end = self.fed;
        self.run(out, Some(end));
        self.hist.clear();
    }

    fn run(&mut self, out: &mut Vec<Frame>, limit: Option<i64>) {
        let taps = self.taps;
        loop {
            let first = self.ipos - (self.half as i64 - 1);
            let last = self.ipos + self.half as i64;
            if last >= self.base + self.hist.len() as i64 {
                break;
            }
            if limit.is_some_and(|end| self.ipos >= end) {
                break;
            }
            let pf = self.frac as f64 / self.l as f64 * PHASES as f64;
            let j = (pf as usize).min(PHASES - 1);
            let f = (pf - j as f64) as f32;
            let r0 = &self.table[j * taps..(j + 1) * taps];
            let r1 = &self.table[(j + 1) * taps..(j + 2) * taps];
            for ((c, a), b) in self.coeffs.iter_mut().zip(r0).zip(r1) {
                *c = a + f * (b - a);
            }
            let off = (first - self.base) as usize;
            let (mut acc_l, mut acc_r) = (0.0f32, 0.0f32);
            for (c, s) in self.coeffs.iter().zip(&self.hist[off..off + taps]) {
                acc_l += c * s[0];
                acc_r += c * s[1];
            }
            out.push([acc_l, acc_r]);
            self.frac += self.m;
            self.ipos += (self.frac / self.l) as i64;
            self.frac %= self.l;
        }
        let keep_from = self.ipos - (self.half as i64 - 1) - self.base;
        if keep_from > 0 {
            let n = (keep_from as usize).min(self.hist.len());
            self.hist.drain(..n);
            self.base += n as i64;
        }
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    fn sine(rate: u32, freq: f64, frames: usize, amp: f64) -> Vec<Frame> {
        (0..frames)
            .map(|i| {
                let v = (amp * (2.0 * std::f64::consts::PI * freq * i as f64 / rate as f64).sin())
                    as f32;
                [v, -v]
            })
            .collect()
    }

    fn resample_all(input: &[Frame], from: u32, to: u32, chunk: usize) -> Vec<Frame> {
        let mut r = Resampler::new(from, to);
        let mut out = Vec::new();
        for c in input.chunks(chunk) {
            r.process(c, &mut out);
        }
        r.flush(&mut out);
        out
    }

    /// Residual after removing the best-fit sinusoid at `freq`, in dB below it.
    fn snr_db(x: &[f32], rate: u32, freq: f64) -> f64 {
        let w = 2.0 * std::f64::consts::PI * freq / rate as f64;
        let (mut ss, mut sc, mut cc, mut xs, mut xc) = (0.0, 0.0, 0.0, 0.0, 0.0);
        for (i, &v) in x.iter().enumerate() {
            let (s, c) = (w * i as f64).sin_cos();
            ss += s * s;
            sc += s * c;
            cc += c * c;
            xs += v as f64 * s;
            xc += v as f64 * c;
        }
        let det = ss * cc - sc * sc;
        let a = (xs * cc - xc * sc) / det;
        let b = (xc * ss - xs * sc) / det;
        let (mut sig, mut err) = (0.0, 0.0);
        for (i, &v) in x.iter().enumerate() {
            let (s, c) = (w * i as f64).sin_cos();
            let fit = a * s + b * c;
            sig += fit * fit;
            err += (v as f64 - fit).powi(2);
        }
        10.0 * (sig / err.max(1e-30)).log10()
    }

    #[test]
    fn lengths_match_ratio() {
        for &(from, to) in &[
            (44100, 48000),
            (22050, 48000),
            (32000, 48000),
            (96000, 48000),
            (48000, 48000),
            (11025, 48000),
        ] {
            let n = from as usize; // one second
            let out = resample_all(&sine(from, 440.0, n, 0.5), from, to, 1000);
            let expected = (n as u64 * to as u64).div_ceil(from as u64) as usize;
            assert_eq!(out.len(), expected, "{from}->{to}");
        }
    }

    #[test]
    fn upsample_44k1_is_clean() {
        for &freq in &[1000.0, 10000.0, 18000.0] {
            let out = resample_all(&sine(44100, freq, 44100, 0.5), 44100, 48000, 777);
            // Skip the edges where the kernel sees the implicit silence.
            let mid: Vec<f32> = out[4800..out.len() - 4800].iter().map(|f| f[0]).collect();
            let snr = snr_db(&mid, 48000, freq);
            assert!(snr > 85.0, "{freq} Hz: SNR {snr:.1} dB");
        }
    }

    #[test]
    fn downsample_rejects_alias() {
        // 30 kHz at 96 kHz would fold to 18 kHz at 48 kHz.
        let out = resample_all(&sine(96000, 30000.0, 96000, 0.5), 96000, 48000, 1024);
        let mid = &out[4800..out.len() - 4800];
        let rms =
            (mid.iter().map(|f| (f[0] as f64).powi(2)).sum::<f64>() / mid.len() as f64).sqrt();
        let db = 20.0 * (rms / (0.5 / 2f64.sqrt())).log10();
        assert!(db < -80.0, "alias at {db:.1} dB");
        let out = resample_all(&sine(96000, 5000.0, 96000, 0.5), 96000, 48000, 1024);
        let mid: Vec<f32> = out[4800..out.len() - 4800].iter().map(|f| f[1]).collect();
        assert!(snr_db(&mid, 48000, 5000.0) > 85.0);
    }

    #[test]
    fn no_time_offset() {
        // An impulse at input frame 441 lands at output frame 480.
        let mut input = vec![[0.0f32; 2]; 4410];
        input[441] = [1.0, 1.0];
        let out = resample_all(&input, 44100, 48000, 100);
        let peak = out
            .iter()
            .enumerate()
            .max_by(|a, b| a.1[0].partial_cmp(&b.1[0]).unwrap())
            .unwrap()
            .0;
        assert_eq!(peak, 480);
    }
}
