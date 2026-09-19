//! Review: what the player makes of a download cut short (yt-dlp runs with
//! `--no-part`, so a killed or failed download leaves a truncated file under
//! the final name, which a later yt-dlp run reports as "already downloaded").

use std::path::{Path, PathBuf};
use std::time::{Duration, Instant};

use dj_audio::{Player, State};

fn fixture(name: &str) -> PathBuf {
    Path::new(env!("CARGO_MANIFEST_DIR"))
        .join("tests/fixtures")
        .join(name)
}

fn truncated(name: &str, keep: f64) -> PathBuf {
    let bytes = std::fs::read(fixture(name)).unwrap();
    let n = (bytes.len() as f64 * keep) as usize;
    let path = std::env::temp_dir().join(format!(
        "dj_review_trunc_{}_{}",
        std::process::id(),
        name
    ));
    std::fs::write(&path, &bytes[..n]).unwrap();
    path
}

/// Plays to the end; returns (open rc, duration_ms, ms of audio, final state, error).
fn play_out(path: &Path) -> (i32, u64, usize, State, i32) {
    let p = Player::new();
    let rc = p.open(path, 0, 1);
    if rc != 0 {
        let s = p.status();
        return (rc, 0, 0, s.state, s.error);
    }
    let dur = p.status().duration_ms;
    let mut buf = [0i16; 960];
    let mut audio = 0;
    let deadline = Instant::now() + Duration::from_secs(10);
    loop {
        std::thread::sleep(Duration::from_micros(200));
        audio += p.pull(&mut buf, 2, 48_000);
        let s = p.status();
        if matches!(s.state, State::Ended | State::Error) || Instant::now() > deadline {
            return (rc, dur, audio * 1000 / 48_000, s.state, s.error);
        }
    }
}

#[test]
fn review_truncated_downloads() {
    for (name, keep) in [
        ("tone_gap_frag.m4a", 0.5),
        ("tone_gap_frag_elst.m4a", 0.5),
        ("tone_gap.m4a", 0.5),
        ("tone_gap.mp3", 0.5),
    ] {
        let full = play_out(&fixture(name));
        let path = truncated(name, keep);
        let cut = play_out(&path);
        println!(
            "REVIEW {name:<24} full: rc {} dur {} ms played {} ms {:?} err {} | {:.0}% of file: rc {} dur {} ms played {} ms {:?} err {}",
            full.0, full.1, full.2, full.3, full.4,
            keep * 100.0,
            cut.0, cut.1, cut.2, cut.3, cut.4
        );
        std::fs::remove_file(path).ok();
    }
}
