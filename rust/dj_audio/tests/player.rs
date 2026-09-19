//! Behaviour of the player through its Rust API and the C ABI.
//!
//! Compressed fixtures (tests/fixtures, made with ffmpeg) are 4 s at
//! 44.1 kHz: 1 kHz left, 1.5 kHz right, amplitude 0.5, silent from 2.0 s to
//! 2.5 s. WAV fixtures are written at test time.
//!
//! The m4a files are AAC with 1024 priming samples: `tone_gap.m4a` is a
//! plain MP4 with an edit list, `tone_gap_frag_elst.m4a` fragmented with an
//! edit list, and `tone_gap_frag.m4a` fragmented (`empty_moov`) without one,
//! so its timeline, for ffmpeg too, starts 1024 samples (23.2 ms) early.

use std::ffi::CString;
use std::path::{Path, PathBuf};
use std::sync::atomic::{AtomicUsize, Ordering};
use std::time::{Duration, Instant};

use dj_audio::ffi::*;
use dj_audio::{Player, State};

const RATE: usize = 48_000;
const BLOCK: usize = 480;

/// Fixture and how late (ms) its content sits on its own timeline.
const COMPRESSED: [(&str, f64); 4] = [
    ("tone_gap.m4a", 0.0),
    ("tone_gap_frag_elst.m4a", 0.0),
    ("tone_gap_frag.m4a", 1024.0 * 1000.0 / 44_100.0),
    ("tone_gap.mp3", 0.0),
];

fn fixture(name: &str) -> PathBuf {
    Path::new(env!("CARGO_MANIFEST_DIR"))
        .join("tests/fixtures")
        .join(name)
}

fn temp_path(name: &str) -> PathBuf {
    static N: AtomicUsize = AtomicUsize::new(0);
    let n = N.fetch_add(1, Ordering::Relaxed);
    std::env::temp_dir().join(format!("dj_audio_{}_{n}_{name}", std::process::id()))
}

/// 16-bit PCM WAV.
fn write_wav(
    path: &Path,
    rate: u32,
    channels: u16,
    frames: usize,
    f: impl Fn(usize, usize) -> f32,
) {
    let data_len = (frames * channels as usize * 2) as u32;
    let mut b = Vec::with_capacity(44 + data_len as usize);
    b.extend_from_slice(b"RIFF");
    b.extend_from_slice(&(36 + data_len).to_le_bytes());
    b.extend_from_slice(b"WAVEfmt ");
    b.extend_from_slice(&16u32.to_le_bytes());
    b.extend_from_slice(&1u16.to_le_bytes());
    b.extend_from_slice(&channels.to_le_bytes());
    b.extend_from_slice(&rate.to_le_bytes());
    b.extend_from_slice(&(rate * channels as u32 * 2).to_le_bytes());
    b.extend_from_slice(&(channels * 2).to_le_bytes());
    b.extend_from_slice(&16u16.to_le_bytes());
    b.extend_from_slice(b"data");
    b.extend_from_slice(&data_len.to_le_bytes());
    for i in 0..frames {
        for c in 0..channels as usize {
            let v = (f(i, c).clamp(-1.0, 1.0) * 32767.0).round() as i16;
            b.extend_from_slice(&v.to_le_bytes());
        }
    }
    std::fs::write(path, b).unwrap();
}

fn tone(rate: u32, freq: f64, i: usize) -> f32 {
    (0.5 * (2.0 * std::f64::consts::PI * freq * i as f64 / rate as f64).sin()) as f32
}

/// Same signal as the compressed fixtures.
fn gap_signal(rate: u32) -> impl Fn(usize, usize) -> f32 {
    move |i, c| {
        let t = i as f64 / rate as f64;
        if (2.0..2.5).contains(&t) {
            0.0
        } else {
            tone(rate, if c == 0 { 1000.0 } else { 1500.0 }, i)
        }
    }
}

fn gap_wav(rate: u32) -> PathBuf {
    let path = temp_path("gap.wav");
    write_wav(&path, rate, 2, rate as usize * 4, gap_signal(rate));
    path
}

/// Waits until `frames` are buffered or the decoder has finished.
fn wait_buffered(p: &Player, frames: usize) {
    let deadline = Instant::now() + Duration::from_secs(10);
    loop {
        let (avail, done) = p.buffer_state();
        if avail >= frames.min(RATE * 5 / 2) || done {
            return;
        }
        assert!(
            Instant::now() < deadline,
            "decoder stalled at {avail} frames"
        );
        std::thread::sleep(Duration::from_millis(1));
    }
}

/// Pulls `frames` stereo frames in 10 ms blocks without underrunning.
/// Returns samples scaled to [-1, 1] and the frames that carried audio.
fn pull(p: &Player, frames: usize) -> (Vec<[f32; 2]>, usize) {
    let mut out = Vec::with_capacity(frames);
    let mut audio = 0;
    let mut buf = [0i16; BLOCK * 2];
    while out.len() < frames {
        let n = BLOCK.min(frames - out.len());
        wait_buffered(p, n);
        audio += p.pull(&mut buf[..n * 2], 2, RATE as i32);
        out.extend(
            buf[..n * 2]
                .chunks(2)
                .map(|s| [s[0] as f32 / 32767.0, s[1] as f32 / 32767.0]),
        );
    }
    (out, audio)
}

fn channel(x: &[[f32; 2]], c: usize) -> Vec<f32> {
    x.iter().map(|f| f[c]).collect()
}

fn zero_crossings(x: &[f32]) -> usize {
    x.windows(2)
        .filter(|w| (w[0] < 0.0) != (w[1] < 0.0))
        .count()
}

/// Residual after removing the best-fit sinusoid at `freq`, in dB below it.
fn snr_db(x: &[f32], freq: f64) -> f64 {
    let w = 2.0 * std::f64::consts::PI * freq / RATE as f64;
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
    let (a, b) = ((xs * cc - xc * sc) / det, (xc * ss - xs * sc) / det);
    let (mut sig, mut err) = (0.0, 0.0);
    for (i, &v) in x.iter().enumerate() {
        let (s, c) = (w * i as f64).sin_cos();
        let fit = a * s + b * c;
        sig += fit * fit;
        err += (v as f64 - fit).powi(2);
    }
    10.0 * (sig / err.max(1e-30)).log10()
}

fn rms(x: &[f32]) -> f32 {
    (x.iter().map(|v| v * v).sum::<f32>() / x.len().max(1) as f32).sqrt()
}

/// First frame from which 1 ms stays quiet.
fn silence_onset(x: &[f32]) -> Option<usize> {
    (0..x.len().saturating_sub(48)).find(|&i| x[i..i + 48].iter().all(|v| v.abs() < 0.02))
}

/// First loud frame at or after `from`.
fn sound_onset(x: &[f32], from: usize) -> Option<usize> {
    (from..x.len()).find(|&i| x[i].abs() > 0.1)
}

fn assert_tone(x: &[[f32; 2]], label: &str) {
    // One second: 1 kHz crosses zero 2000 times, 1.5 kHz 3000 times.
    let l = channel(x, 0);
    let r = channel(x, 1);
    let zl = zero_crossings(&l[..RATE]) as i64;
    let zr = zero_crossings(&r[..RATE]) as i64;
    assert!((zl - 2000).abs() <= 4, "{label}: left crossings {zl}");
    assert!((zr - 3000).abs() <= 4, "{label}: right crossings {zr}");
    let a = rms(&l[..RATE]);
    assert!((a - 0.5 / 2f32.sqrt()).abs() < 0.03, "{label}: rms {a}");
}

fn open(p: &Player, path: &Path, start_ms: u64, id: u64) {
    assert_eq!(p.open(path, start_ms, id), 0, "open {}", path.display());
}

#[test]
fn wav_44k1_resampled_cleanly() {
    let path = gap_wav(44_100);
    let p = Player::new();
    open(&p, &path, 0, 7);
    let (x, audio) = pull(&p, RATE * 2);
    assert_eq!(audio, RATE * 2);
    // Skip the 5 ms fade-in.
    assert_tone(&x[4800..], "wav");
    let snr = snr_db(&channel(&x[4800..4800 + RATE], 0), 1000.0);
    assert!(snr > 75.0, "SNR {snr:.1} dB");
    let s = p.status();
    assert_eq!(
        (s.state, s.track_id, s.position_ms, s.duration_ms, s.error),
        (State::Playing, 7, 2000, 4000, 0)
    );
    std::fs::remove_file(path).ok();
}

#[test]
fn compressed_fixtures_decode() {
    for (name, offset) in COMPRESSED {
        let p = Player::new();
        open(&p, &fixture(name), 0, 1);
        let s = p.status();
        assert!(
            (s.duration_ms as i64 - 4000).abs() <= 60,
            "{name}: duration {}",
            s.duration_ms
        );
        let (x, audio) = pull(&p, RATE * 22 / 10);
        assert_eq!(audio, RATE * 22 / 10, "{name}");
        assert_tone(&x[RATE / 10..], name);
        let snr = snr_db(&channel(&x[RATE / 10..RATE / 10 + RATE], 0), 1000.0);
        // ffmpeg's AAC encoder itself only manages ~30 dB on these tones.
        assert!(snr > 25.0, "{name}: SNR {snr:.1} dB");
        // Encoder delay is gone: the gap starts at 2.000 s.
        let l = channel(&x, 0);
        let quiet =
            silence_onset(&l[RATE / 10..]).expect("gap") as f64 * 1000.0 / RATE as f64 + 100.0;
        assert!(
            (quiet - 2000.0 - offset).abs() <= 10.0,
            "{name}: gap at {quiet:.1} ms"
        );
    }
}

#[test]
fn other_rates_and_codecs() {
    // 22.05 kHz mono FLAC and 32 kHz Ogg Vorbis.
    let p = Player::new();
    open(&p, &fixture("tone_22k_mono.flac"), 0, 1);
    assert_eq!(p.status().duration_ms, 1000);
    let (x, _) = pull(&p, RATE * 9 / 10);
    let l = channel(&x[2400..2400 + RATE / 2], 0);
    assert!(x.iter().all(|f| f[0] == f[1]), "mono is duplicated");
    assert!((zero_crossings(&l) as i64 - 1000).abs() <= 3);
    assert!(snr_db(&l, 1000.0) > 75.0);

    open(&p, &fixture("tone_32k.ogg"), 0, 2);
    let (x, _) = pull(&p, RATE * 9 / 10);
    let r = channel(&x[2400..2400 + RATE / 2], 1);
    assert!((zero_crossings(&r) as i64 - 1500).abs() <= 3);

    // 96 kHz WAV is downsampled.
    let path = temp_path("96k.wav");
    write_wav(&path, 96_000, 2, 96_000, |i, _| tone(96_000, 1000.0, i));
    open(&p, &path, 0, 3);
    let (x, audio) = pull(&p, RATE);
    assert_eq!(audio, RATE);
    let l = channel(&x[2400..RATE - 2400], 0);
    assert!(snr_db(&l, 1000.0) > 75.0);
    std::fs::remove_file(path).ok();
}

#[test]
fn position_tracks_pulled_frames() {
    let path = gap_wav(44_100);
    let p = Player::new();
    open(&p, &path, 1234, 1);
    assert_eq!(p.status().position_ms, 1234);
    let mut total = 0usize;
    let mut buf = vec![0i16; 2000 * 2];
    for &n in &[480usize, 441, 1000, 7, 2000, 480, 480] {
        wait_buffered(&p, n);
        total += p.pull(&mut buf[..n * 2], 2, RATE as i32);
        assert_eq!(p.status().position_ms, 1234 + (total * 1000 / RATE) as u64);
    }
    assert_eq!(total, 480 + 441 + 1000 + 7 + 2000 + 480 + 480);
    std::fs::remove_file(path).ok();
}

#[test]
fn pause_freezes_and_resume_fades_in() {
    let path = gap_wav(48_000);
    let p = Player::new();
    open(&p, &path, 0, 1);
    pull(&p, RATE / 2);
    p.set_paused(true);
    assert_eq!(p.status().state, State::Paused);
    let (fade, audio) = pull(&p, BLOCK * 3);
    // 20 ms fade: 960 frames, decaying.
    assert!((955..=965).contains(&audio), "fade frames {audio}");
    assert!(rms(&channel(&fade[..240], 0)) > rms(&channel(&fade[720..960], 0)));
    assert!(fade[970..].iter().all(|f| f[0] == 0.0 && f[1] == 0.0));
    let pos = p.status().position_ms;
    for _ in 0..10 {
        let (x, audio) = pull(&p, BLOCK);
        assert_eq!(audio, 0);
        assert!(x.iter().all(|f| f[0] == 0.0));
    }
    assert_eq!(p.status().position_ms, pos);

    p.set_paused(false);
    let (x, audio) = pull(&p, BLOCK * 4);
    assert_eq!(audio, BLOCK * 4);
    let l = channel(&x, 0);
    let peak = |r: std::ops::Range<usize>| l[r].iter().fold(0f32, |m, v| m.max(v.abs()));
    assert!(peak(0..48) < 0.05, "fade-in starts quiet");
    assert!(peak(1440..1920) > 0.45, "full level after 20 ms");
    // No step anywhere: a 1 kHz sine at 0.5 moves at most ~0.066 per frame.
    assert!(l.windows(2).all(|w| (w[1] - w[0]).abs() < 0.08));
    std::fs::remove_file(path).ok();
}

/// Seeks to 1900 ms (100 ms before the gap) and checks where the gap lands,
/// `offset` ms late on the file's own timeline.
fn check_seek(p: &Player, offset: f64, tolerance_ms: f64, label: &str) {
    // Enough left in the old ring for its fade-out.
    wait_buffered(p, RATE / 10);
    assert_eq!(p.seek(1900), 0, "{label}");
    assert_eq!(p.status().position_ms, 1900);
    // The first block carries the old track's 5 ms fade-out.
    let (first, _) = pull(p, BLOCK);
    assert!(
        channel(&first, 0)
            .windows(2)
            .all(|w| (w[1] - w[0]).abs() < 0.1),
        "{label}: click at switch"
    );
    let pos = p.status().position_ms as f64;
    let (x, _) = pull(p, RATE * 7 / 10);
    let l = channel(&x, 0);
    let quiet = silence_onset(&l).expect("gap") as f64;
    let loud = sound_onset(&l, quiet as usize).expect("tone after gap") as f64;
    let quiet_ms = pos + quiet * 1000.0 / RATE as f64;
    let loud_ms = pos + loud * 1000.0 / RATE as f64;
    assert!(
        (quiet_ms - 2000.0 - offset).abs() <= tolerance_ms,
        "{label}: gap starts at {quiet_ms:.1} ms"
    );
    assert!(
        (loud_ms - 2500.0 - offset).abs() <= tolerance_ms,
        "{label}: gap ends at {loud_ms:.1} ms"
    );
}

#[test]
fn seek_lands_on_target() {
    let path = gap_wav(44_100);
    let files = std::iter::once((path.clone(), 0.0, 2.0)).chain(
        COMPRESSED
            .iter()
            .map(|(name, offset)| (fixture(name), *offset, 10.0)),
    );
    for (file, offset, tol) in files {
        let label = file.display().to_string();
        let p = Player::new();
        open(&p, &file, 0, 5);
        pull(&p, RATE / 5);
        check_seek(&p, offset, tol, &label);
        // Backwards too.
        assert_eq!(p.seek(300), 0);
        pull(&p, BLOCK);
        check_seek(&p, offset, tol, &label);
        assert_eq!(p.status().track_id, 5);
    }
    std::fs::remove_file(path).ok();
}

#[test]
fn open_at_start_position() {
    let path = gap_wav(44_100);
    let files = std::iter::once((path.clone(), 0.0)).chain(
        COMPRESSED
            .iter()
            .map(|(name, offset)| (fixture(name), *offset)),
    );
    for (file, offset) in files {
        let label = file.display().to_string();
        let p = Player::new();
        open(&p, &file, 2250, 9);
        let s = p.status();
        assert_eq!((s.position_ms, s.track_id), (2250, 9));
        let (x, _) = pull(&p, RATE / 2);
        let l = channel(&x, 0);
        let loud = sound_onset(&l, 0).expect("tone") as f64 * 1000.0 / RATE as f64;
        assert!(
            (loud - 250.0 - offset).abs() <= 10.0,
            "{label}: tone back after {loud:.1} ms"
        );
        assert_eq!(p.status().position_ms, 2750);
    }
    std::fs::remove_file(path).ok();
}

#[test]
fn opens_paused_when_paused() {
    let path = gap_wav(44_100);
    let p = Player::new();
    p.set_paused(true);
    open(&p, &path, 500, 1);
    wait_buffered(&p, RATE);
    let (x, audio) = pull(&p, BLOCK * 5);
    assert_eq!(audio, 0);
    assert!(x.iter().all(|f| f[0] == 0.0));
    let s = p.status();
    assert_eq!((s.state, s.position_ms), (State::Paused, 500));
    p.set_paused(false);
    let (_, audio) = pull(&p, BLOCK);
    assert_eq!(audio, BLOCK);
    std::fs::remove_file(path).ok();
}

#[test]
fn ends_at_eof() {
    let path = temp_path("short.wav");
    write_wav(&path, 44_100, 2, 22_050, |i, _| tone(44_100, 1000.0, i));
    let p = Player::new();
    open(&p, &path, 0, 1);
    let mut total = 0;
    let mut buf = [0i16; BLOCK * 2];
    for _ in 0..200 {
        wait_buffered(&p, BLOCK);
        total += p.pull(&mut buf, 2, RATE as i32);
        if p.status().state == State::Ended {
            break;
        }
    }
    // 22050 frames at 44.1 kHz are exactly 24000 at 48 kHz.
    assert_eq!(total, 24_000);
    let s = p.status();
    assert_eq!(
        (s.state, s.position_ms, s.duration_ms),
        (State::Ended, 500, 500)
    );
    assert_eq!(p.pull(&mut buf, 2, RATE as i32), 0);
    assert_eq!(p.status().underruns, 0);

    // Starting at or past the end is Ended straight away.
    open(&p, &fixture("tone_gap.mp3"), 5000, 2);
    let s = p.status();
    assert_eq!((s.state, s.track_id, s.error), (State::Ended, 2, 0));
    assert_eq!(p.pull(&mut buf, 2, RATE as i32), 0);
    // Seeking back into range revives it.
    assert_eq!(p.seek(1000), 0);
    wait_buffered(&p, BLOCK);
    assert_eq!(p.pull(&mut buf, 2, RATE as i32), BLOCK);
    std::fs::remove_file(path).ok();
}

#[test]
fn concatenated_mp3_plays_through() {
    let one = std::fs::read(fixture("tone_gap.mp3")).unwrap();
    let path = temp_path("twice.mp3");
    std::fs::write(&path, [one.clone(), one].concat()).unwrap();
    let p = Player::new();
    open(&p, &path, 0, 1);
    let d = p.status().duration_ms as i64;
    assert!((d - 8000).abs() <= 100, "duration {d}");

    // Past the first stream's Xing frame count: second copy, inside its gap.
    assert_eq!(p.seek(6100), 0);
    let (x, _) = pull(&p, RATE / 10);
    assert!(
        rms(&channel(&x[480..], 0)) < 0.02,
        "expected the gap at 6.1 s"
    );
    assert_eq!(p.seek(6700), 0);
    let (x, _) = pull(&p, RATE / 2);
    let l = channel(&x[RATE / 10..RATE / 10 + RATE / 4], 0);
    assert!(
        (zero_crossings(&l) as i64 - 500).abs() <= 2,
        "second stream tone"
    );
    assert!((rms(&l) - 0.5 / 2f32.sqrt()).abs() < 0.03);

    // Everything decodes.
    assert_eq!(p.seek(7500), 0);
    let mut total = 0;
    let mut buf = [0i16; BLOCK * 2];
    for _ in 0..500 {
        wait_buffered(&p, BLOCK);
        total += p.pull(&mut buf, 2, RATE as i32);
        if p.status().state == State::Ended {
            break;
        }
    }
    assert_eq!(p.status().state, State::Ended);
    let end_ms = 7500 + total * 1000 / RATE;
    assert!((end_ms as i64 - 8000).abs() <= 100, "ended at {end_ms} ms");
    std::fs::remove_file(path).ok();
}

#[test]
fn open_errors() {
    let p = Player::new();
    assert_eq!(
        p.open(Path::new("/nonexistent/dir/song.m4a"), 0, 3),
        dj_audio::ERR_OPEN
    );
    let s = p.status();
    assert_eq!((s.state, s.error, s.track_id), (State::Error, -2, 3));

    let zeros = temp_path("zeros.mp3");
    std::fs::write(&zeros, vec![0u8; 64 * 1024]).unwrap();
    assert_eq!(p.open(&zeros, 0, 1), dj_audio::ERR_UNSUPPORTED);
    let text = temp_path("text.txt");
    std::fs::write(&text, "definitely not audio\n".repeat(2000)).unwrap();
    assert_eq!(p.open(&text, 0, 1), dj_audio::ERR_UNSUPPORTED);
    let empty = temp_path("empty.m4a");
    std::fs::write(&empty, b"").unwrap();
    assert_eq!(p.open(&empty, 0, 1), dj_audio::ERR_UNSUPPORTED);

    let mut buf = [1i16; BLOCK * 2];
    assert_eq!(p.pull(&mut buf, 2, RATE as i32), 0);
    assert!(buf.iter().all(|&v| v == 0));
    assert_eq!(p.seek(100), dj_audio::ERR_ARGS);
    p.stop();
    let s = p.status();
    assert_eq!((s.state, s.error, s.track_id), (State::Idle, 0, 0));
    for f in [zeros, text, empty] {
        std::fs::remove_file(f).ok();
    }
}

#[test]
fn failed_seek_keeps_playing() {
    let path = gap_wav(44_100);
    let p = Player::new();
    open(&p, &path, 0, 1);
    pull(&p, RATE / 10);
    std::fs::remove_file(&path).unwrap();
    assert_eq!(p.seek(1000), dj_audio::ERR_OPEN);
    let (_, audio) = pull(&p, RATE / 10);
    assert_eq!(audio, RATE / 10);
    assert_eq!(p.status().position_ms, 200);
}

#[test]
fn underruns_are_counted() {
    let path = temp_path("long.wav");
    write_wav(&path, 44_100, 2, 44_100 * 20, |i, _| tone(44_100, 440.0, i));
    let p = Player::new();
    open(&p, &path, 0, 1);
    // One pull bigger than the whole ring has to run dry.
    let mut big = vec![0i16; RATE * 4 * 2];
    wait_buffered(&p, RATE);
    let got = p.pull(&mut big, 2, RATE as i32);
    assert!(got < RATE * 4);
    let s = p.status();
    assert!(s.underruns >= 1);
    assert!(matches!(s.state, State::Buffering | State::Playing));
    // Hammering it straight after open is fine too.
    open(&p, &path, 0, 2);
    let mut buf = [0i16; BLOCK * 2];
    for _ in 0..2000 {
        p.pull(&mut buf, 2, RATE as i32);
        let _ = p.status();
        std::thread::sleep(Duration::from_micros(50));
    }
    assert!(p.status().position_ms > 0);
    std::fs::remove_file(path).ok();
}

#[test]
fn gain_ramps_and_never_wraps() {
    let path = gap_wav(44_100);
    let p = Player::new();
    open(&p, &path, 0, 1);
    pull(&p, RATE / 10);
    p.set_gain(0.5);
    let (x, _) = pull(&p, RATE / 5);
    let l = channel(&x, 0);
    assert!(
        l.windows(2).all(|w| (w[1] - w[0]).abs() < 0.08),
        "gain change clicked"
    );
    let a = rms(&l[RATE / 10..]);
    assert!((a - 0.25 / 2f32.sqrt()).abs() < 0.01, "rms {a}");

    p.set_gain(8.0);
    let (x, _) = pull(&p, RATE / 5);
    let l = channel(&x[RATE / 10..], 0);
    let peak = l.iter().fold(0f32, |m, v| m.max(v.abs()));
    assert!(peak > 0.97 && peak <= 1.0, "peak {peak}");
    // Clipped, not wrapped: the sign follows the 1 kHz sine.
    assert!((zero_crossings(&l) as i64 - (l.len() as i64 / 24)).abs() <= 3);
    std::fs::remove_file(path).ok();
}

#[test]
fn stop_fades_out_then_idles() {
    let path = gap_wav(44_100);
    let p = Player::new();
    open(&p, &path, 0, 1);
    pull(&p, RATE / 10);
    // The fade needs the stopped decoder to have left something behind.
    wait_buffered(&p, RATE / 10);
    p.stop();
    assert_eq!(p.status().state, State::Idle);
    let (x, audio) = pull(&p, BLOCK * 2);
    assert!((200..=260).contains(&audio), "fade-out frames {audio}");
    assert!(channel(&x, 0)
        .windows(2)
        .all(|w| (w[1] - w[0]).abs() < 0.08));
    assert!(x[300..].iter().all(|f| f[0] == 0.0));
    let s = p.status();
    assert_eq!((s.state, s.track_id, s.position_ms), (State::Idle, 0, 0));
    std::fs::remove_file(path).ok();
}

#[test]
fn mono_and_foreign_rates() {
    let path = gap_wav(44_100);
    let p = Player::new();
    open(&p, &path, 0, 1);
    wait_buffered(&p, RATE);
    let mut buf = [7i16; BLOCK];
    assert_eq!(p.pull(&mut buf, 1, 44_100), 0);
    assert!(buf.iter().all(|&v| v == 0));
    assert_eq!(p.status().position_ms, 0);
    let mut mono = vec![0i16; RATE / 2];
    assert_eq!(p.pull(&mut mono, 1, RATE as i32), RATE / 2);
    // Average of 1 kHz and 1.5 kHz: both show up, peak below either alone.
    let x: Vec<f32> = mono[4800..].iter().map(|&v| v as f32 / 32767.0).collect();
    let peak = x.iter().fold(0f32, |m, v| m.max(v.abs()));
    assert!(peak > 0.4 && peak <= 0.51, "peak {peak}");
    // More than two channels: music in the first two, silence in the rest.
    let mut quad = vec![1i16; BLOCK * 4];
    assert_eq!(p.pull(&mut quad, 4, RATE as i32), BLOCK);
    assert!(quad.chunks(4).all(|f| f[2] == 0 && f[3] == 0));
    assert!(quad.chunks(4).any(|f| f[0] != 0));
    std::fs::remove_file(path).ok();
}

#[test]
fn switching_tracks_is_click_free() {
    let a = gap_wav(44_100);
    let b = temp_path("b.wav");
    write_wav(&b, 48_000, 2, 48_000 * 2, |i, _| {
        tone(48_000, 3000.0, i + 17)
    });
    let p = Player::new();
    open(&p, &a, 0, 1);
    pull(&p, RATE / 10);
    wait_buffered(&p, RATE / 10);
    open(&p, &b, 0, 2);
    let (x, _) = pull(&p, BLOCK * 4);
    // 3 kHz at 0.5 moves at most ~0.2 per frame; a hard cut would jump ~1.
    assert!(channel(&x, 0)
        .windows(2)
        .all(|w| (w[1] - w[0]).abs() < 0.21));
    assert_eq!(p.status().track_id, 2);
    let l = channel(&x[BLOCK * 2..], 0);
    assert!((zero_crossings(&l) as i64 - 6 * l.len() as i64 / 48).abs() <= 2);
    std::fs::remove_file(a).ok();
    std::fs::remove_file(b).ok();
}

// C ABI.

#[test]
fn ffi_round_trip() {
    assert_eq!(commet_music_abi_version(), 1);
    let path = gap_wav(44_100);
    let c_path = CString::new(path.to_str().unwrap()).unwrap();
    unsafe {
        let h = commet_music_new();
        assert!(!h.is_null());
        assert_eq!(commet_music_open(h, std::ptr::null(), 0, 1), -1);
        assert_eq!(
            commet_music_open(std::ptr::null_mut(), c_path.as_ptr(), 0, 1),
            -1
        );
        let missing = CString::new("/no/such/file.mp3").unwrap();
        assert_eq!(commet_music_open(h, missing.as_ptr(), 0, 1), -2);
        assert_eq!(commet_music_open(h, c_path.as_ptr(), 100, 42), 0);
        commet_music_set_gain(h, 0.8);
        commet_music_set_paused(h, 0);
        let player = &*(h as *const Player);
        wait_buffered(player, RATE);
        let mut buf = [0i16; BLOCK * 2];
        assert_eq!(
            commet_music_pull(h, buf.as_mut_ptr(), BLOCK, 2, 48_000),
            BLOCK
        );
        let mut st = MusicStatus::default();
        commet_music_status(h, &mut st);
        assert_eq!(
            (
                st.state,
                st.track_id,
                st.position_ms,
                st.duration_ms,
                st.error
            ),
            (1, 42, 110, 4000, 0)
        );
        assert_eq!(commet_music_seek(h, 3000), 0);
        commet_music_set_paused(h, 1);
        commet_music_status(h, &mut st);
        assert_eq!((st.state, st.position_ms), (2, 3000));
        commet_music_stop(h);
        commet_music_status(h, &mut st);
        assert_eq!((st.state, st.track_id), (0, 0));
        commet_music_status(h, std::ptr::null_mut());
        commet_music_free(h);
        commet_music_free(std::ptr::null_mut());
    }
    assert_eq!(std::mem::size_of::<MusicStatus>(), 40);
    std::fs::remove_file(path).ok();
}

#[test]
fn ffi_null_handles_are_safe() {
    unsafe {
        let mut buf = [5i16; 64];
        assert_eq!(
            commet_music_pull(std::ptr::null_mut(), buf.as_mut_ptr(), 32, 2, 48_000),
            0
        );
        assert!(buf.iter().all(|&v| v == 0));
        assert_eq!(
            commet_music_pull(std::ptr::null_mut(), std::ptr::null_mut(), 32, 2, 48_000),
            0
        );
        let h = commet_music_new();
        assert_eq!(commet_music_pull(h, std::ptr::null_mut(), 32, 2, 48_000), 0);
        assert_eq!(
            commet_music_pull(h, buf.as_mut_ptr(), usize::MAX, 2, 48_000),
            0
        );
        let mut st = MusicStatus {
            state: 9,
            ..Default::default()
        };
        commet_music_status(std::ptr::null_mut(), &mut st);
        assert_eq!(st.state, 0);
        commet_music_stop(std::ptr::null_mut());
        commet_music_set_paused(std::ptr::null_mut(), 1);
        commet_music_set_gain(std::ptr::null_mut(), 1.0);
        assert_eq!(commet_music_seek(std::ptr::null_mut(), 0), -1);
        assert_eq!(commet_music_seek(h, 0), -1);
        commet_music_free(h);
    }
}

#[test]
fn free_with_decoder_running_does_not_hang() {
    let path = temp_path("long.wav");
    write_wav(&path, 44_100, 2, 44_100 * 60, |i, _| tone(44_100, 440.0, i));
    let c_path = CString::new(path.to_str().unwrap()).unwrap();
    unsafe {
        // Freed while still decoding.
        let h = commet_music_new();
        assert_eq!(commet_music_open(h, c_path.as_ptr(), 0, 1), 0);
        let t = Instant::now();
        commet_music_free(h);
        assert!(t.elapsed() < Duration::from_secs(1));

        // Freed while parked on a full ring.
        let h = commet_music_new();
        assert_eq!(commet_music_open(h, c_path.as_ptr(), 0, 1), 0);
        wait_buffered(&*(h as *const Player), RATE * 5 / 2);
        std::thread::sleep(Duration::from_millis(50));
        let t = Instant::now();
        commet_music_free(h);
        assert!(t.elapsed() < Duration::from_secs(1));

        // Pull on another thread while Dart-side calls churn.
        let h = commet_music_new();
        assert_eq!(commet_music_open(h, c_path.as_ptr(), 0, 1), 0);
        let addr = h as usize;
        let stop = std::sync::Arc::new(std::sync::atomic::AtomicBool::new(false));
        let stop2 = stop.clone();
        let puller = std::thread::spawn(move || {
            let mut buf = [0i16; BLOCK * 2];
            while !stop2.load(Ordering::Relaxed) {
                commet_music_pull(addr as *mut _, buf.as_mut_ptr(), BLOCK, 2, 48_000);
                std::thread::sleep(Duration::from_micros(300));
            }
        });
        for i in 0..30u64 {
            match i % 5 {
                // -1 when the previous round stopped the player.
                0 => assert!(matches!(commet_music_seek(h, i * 500), 0 | -1)),
                1 => commet_music_set_paused(h, (i % 2) as u8),
                2 => assert_eq!(commet_music_open(h, c_path.as_ptr(), i * 100, i), 0),
                3 => commet_music_stop(h),
                _ => commet_music_set_gain(h, 0.5),
            }
            let mut st = MusicStatus::default();
            commet_music_status(h, &mut st);
            std::thread::sleep(Duration::from_millis(3));
        }
        stop.store(true, Ordering::Relaxed);
        puller.join().unwrap();
        commet_music_free(h);
    }
    std::fs::remove_file(path).ok();
}
