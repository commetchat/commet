//! Rebuilds the speech fixtures in `testdata/` from the recordings that
//! `testdata/fetch_sources.sh` downloads. The fixtures are committed, so this
//! only has to run when they change.
//!
//!   sh testdata/fetch_sources.sh
//!   cargo run -p audio_dsp --example make_fixtures
//!
//! Everything stays at the source rate (16 kHz mono PCM16): the recordings
//! hold nothing above 8 kHz, so storing them at 48 kHz would only triple the
//! size of the repository. The tests upsample with the crate's own resampler,
//! which is what the app does with a 16 kHz WebRTC pipeline anyway.

use std::path::PathBuf;

const RATE: usize = 16_000;
/// Silence between utterances. Dialogue coming out of a video is more
/// continuous than someone talking in a call, hence two values.
const GAP_MS_SPEAKER: usize = 350;
const GAP_MS_DIALOGUE: usize = 140;
/// Everything is normalised to this RMS so the tests can scale from a known
/// starting point.
const TARGET_DBFS: f32 = -20.0;
/// Below this, relative to the utterance peak, the head and tail of a
/// recording is treated as silence and cut.
const TRIM_BELOW_DB: f32 = -45.0;

fn main() {
    let testdata = PathBuf::from(env!("CARGO_MANIFEST_DIR")).join("testdata");
    let sources = testdata.join("sources");
    if !sources.is_dir() {
        eprintln!("no {}: run testdata/fetch_sources.sh first", sources.display());
        std::process::exit(1);
    }

    for (voice, ids, gap_ms, out) in [
        ("bdl", ["0001", "0002", "0003"], GAP_MS_SPEAKER, "local_speech_16k.wav"),
        ("slt", ["0001", "0002", "0003"], GAP_MS_DIALOGUE, "media_dialogue_16k.wav"),
        ("clb", ["0001", "0002", "0003"], GAP_MS_DIALOGUE, "far_end_voice_16k.wav"),
    ] {
        let mut joined: Vec<f32> = Vec::new();
        for id in ids {
            let path = sources.join(format!("{voice}_a{id}.wav"));
            let (rate, samples) = read_wav_pcm16(&std::fs::read(&path).unwrap_or_else(|e| {
                panic!("{}: {e}", path.display());
            }));
            assert_eq!(rate, RATE, "{}", path.display());
            joined.extend_from_slice(trim(&samples));
            joined.extend(std::iter::repeat(0.0).take(RATE * gap_ms / 1000));
        }
        normalise(&mut joined, TARGET_DBFS);
        let path = testdata.join(out);
        std::fs::write(&path, write_wav_pcm16(RATE, &joined)).unwrap();
        println!(
            "{}: {:.1} s, {:.1} dBFS RMS",
            path.display(),
            joined.len() as f32 / RATE as f32,
            rms_dbfs(&joined)
        );
    }
}

/// Cut leading and trailing silence, judged against the loudest 10 ms block.
fn trim(samples: &[f32]) -> &[f32] {
    let block = RATE / 100;
    let level = |b: &[f32]| rms_dbfs(b);
    let peak = samples
        .chunks(block)
        .map(level)
        .fold(-120.0f32, f32::max);
    let floor = peak + TRIM_BELOW_DB;
    let first = samples.chunks(block).position(|b| level(b) > floor).unwrap_or(0);
    let last = samples
        .chunks(block)
        .rposition(|b| level(b) > floor)
        .unwrap_or(samples.len() / block);
    let start = first * block;
    let end = ((last + 1) * block).min(samples.len());
    &samples[start..end]
}

fn rms_dbfs(x: &[f32]) -> f32 {
    if x.is_empty() {
        return -120.0;
    }
    let mean_sq = x.iter().map(|s| (*s as f64) * (*s as f64)).sum::<f64>() / x.len() as f64;
    let rms = mean_sq.sqrt() as f32 / 32768.0;
    if rms <= 1e-9 {
        -120.0
    } else {
        20.0 * rms.log10()
    }
}

fn normalise(x: &mut [f32], target_dbfs: f32) {
    let gain = 10f32.powf((target_dbfs - rms_dbfs(x)) / 20.0);
    let peak = x.iter().fold(0.0f32, |m, s| m.max(s.abs())) * gain;
    // Keep 1 dB of headroom below full scale; loud peaks would otherwise clip
    // when the tests add a bleed signal on top.
    let gain = if peak > 29_000.0 { gain * 29_000.0 / peak } else { gain };
    for s in x.iter_mut() {
        *s *= gain;
    }
}

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
            data = body
                .chunks_exact(2)
                .map(|c| i16::from_le_bytes([c[0], c[1]]) as f32)
                .collect();
        }
        pos += 8 + len + (len & 1);
    }
    (rate, data)
}

fn write_wav_pcm16(rate: usize, samples: &[f32]) -> Vec<u8> {
    let data_len = samples.len() * 2;
    let mut out = Vec::with_capacity(44 + data_len);
    out.extend_from_slice(b"RIFF");
    out.extend_from_slice(&((36 + data_len) as u32).to_le_bytes());
    out.extend_from_slice(b"WAVEfmt ");
    out.extend_from_slice(&16u32.to_le_bytes());
    out.extend_from_slice(&1u16.to_le_bytes()); // PCM
    out.extend_from_slice(&1u16.to_le_bytes()); // mono
    out.extend_from_slice(&(rate as u32).to_le_bytes());
    out.extend_from_slice(&((rate * 2) as u32).to_le_bytes()); // byte rate
    out.extend_from_slice(&2u16.to_le_bytes()); // block align
    out.extend_from_slice(&16u16.to_le_bytes()); // bits
    out.extend_from_slice(b"data");
    out.extend_from_slice(&(data_len as u32).to_le_bytes());
    for &s in samples {
        out.extend_from_slice(&(s.round().clamp(-32768.0, 32767.0) as i16).to_le_bytes());
    }
    out
}

