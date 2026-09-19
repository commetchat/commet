//! Review: how long the blocking control calls (`open`, `seek`) take on long
//! files. Dart calls them synchronously on the UI isolate.
//!
//! Needs long files made with ffmpeg; set DJ_REVIEW_DIR to their folder.
//! Skipped (passes) when it is not set.

use std::path::PathBuf;
use std::time::Instant;

use dj_audio::Player;

fn files() -> Vec<PathBuf> {
    let Ok(dir) = std::env::var("DJ_REVIEW_DIR") else {
        return vec![];
    };
    let mut v: Vec<PathBuf> = std::fs::read_dir(dir)
        .unwrap()
        .filter_map(|e| e.ok().map(|e| e.path()))
        .filter(|p| {
            matches!(
                p.extension().and_then(|e| e.to_str()),
                Some("mp3") | Some("m4a")
            )
        })
        .collect();
    v.sort();
    v
}

fn ms(t: Instant) -> f64 {
    t.elapsed().as_secs_f64() * 1000.0
}

#[test]
fn review_blocking_open_and_seek_times() {
    for path in files() {
        let size = std::fs::metadata(&path).unwrap().len() / (1 << 20);
        let p = Player::new();

        let t = Instant::now();
        let r = p.open(&path, 0, 1);
        let open0 = ms(t);
        let dur = p.status().duration_ms;

        let t = Instant::now();
        let r2 = p.open(&path, 50 * 60 * 1000, 2);
        let open50 = ms(t);

        let t = Instant::now();
        let s1 = p.seek(10 * 60 * 1000);
        let seek10 = ms(t);

        let t = Instant::now();
        let s2 = p.seek(55 * 60 * 1000);
        let seek55 = ms(t);

        let t = Instant::now();
        let s3 = p.seek(1000);
        let seek1 = ms(t);

        println!(
            "REVIEW {:<28} {:>4} MB dur {:>8} ms | open@0 {:>7.1} ms (rc {}) | open@50min {:>7.1} ms (rc {}) | seek 10min {:>7.1} ms (rc {}) | seek 55min {:>7.1} ms (rc {}) | seek 1s {:>7.1} ms (rc {})",
            path.file_name().unwrap().to_string_lossy(),
            size,
            dur,
            open0,
            r,
            open50,
            r2,
            seek10,
            s1,
            seek55,
            s2,
            seek1,
            s3
        );
    }
}
