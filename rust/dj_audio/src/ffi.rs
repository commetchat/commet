//! C ABI. Dart controls the player with `dart:ffi`; the WebRTC plugin's C++
//! pacing thread calls `commet_music_pull` every 10 ms with the same handle.
//!
//! `open`, `stop`, `seek`, `set_paused`, `set_gain` and `status` may run on
//! one thread concurrently with `pull` on another. `open` and `seek` block
//! while the file is probed and positioned. `pull` never allocates, blocks or
//! frees; it always writes `frames * channels` samples (silence where there
//! is no music) and returns the number of frames that carried track audio.
//! Only 48 kHz is produced; any other rate yields silence. `free` must only
//! be called once pulls have stopped; it joins the decoder thread.
//!
//! Negative return codes: -1 arguments, -2 cannot open file, -3 unsupported
//! format or no audio track, -4 seek failed, -5 decoder failure (status
//! only).

use std::ffi::{c_char, c_void, CStr};
use std::panic::{catch_unwind, AssertUnwindSafe};
use std::path::Path;

use crate::{Player, ERR_ARGS};

/// Bump when `MusicStatus` or the function signatures change.
pub const ABI_VERSION: u32 = 1;

#[repr(C)]
#[derive(Clone, Copy, Debug, Default)]
pub struct MusicStatus {
    /// 0 Idle, 1 Playing, 2 Paused, 3 Ended, 4 Error, 5 Buffering.
    pub state: u32,
    /// Pulls that ran dry while playing, since the last successful open.
    pub underruns: u32,
    /// As passed to open; 0 when idle.
    pub track_id: u64,
    /// Start position plus the frames output from the track so far.
    pub position_ms: u64,
    /// 0 if unknown.
    pub duration_ms: u64,
    /// Last error (negative) or 0.
    pub error: i32,
    pub _pad: u32,
}

unsafe fn player<'a>(p: *mut c_void) -> Option<&'a Player> {
    (p as *const Player).as_ref()
}

#[no_mangle]
pub extern "C" fn commet_music_abi_version() -> u32 {
    ABI_VERSION
}

#[no_mangle]
pub extern "C" fn commet_music_new() -> *mut c_void {
    catch_unwind(|| Box::into_raw(Box::new(Player::new())) as *mut c_void)
        .unwrap_or(std::ptr::null_mut())
}

/// # Safety
/// `p` must be null or come from `commet_music_new`, freed once, with no
/// concurrent call on it.
#[no_mangle]
pub unsafe extern "C" fn commet_music_free(p: *mut c_void) {
    if p.is_null() {
        return;
    }
    let _ = catch_unwind(AssertUnwindSafe(|| drop(Box::from_raw(p as *mut Player))));
}

/// # Safety
/// `p` must be a live handle; `path_utf8` null or a NUL-terminated string.
#[no_mangle]
pub unsafe extern "C" fn commet_music_open(
    p: *mut c_void,
    path_utf8: *const c_char,
    start_ms: u64,
    track_id: u64,
) -> i32 {
    let Some(player) = player(p) else {
        return ERR_ARGS;
    };
    if path_utf8.is_null() {
        return ERR_ARGS;
    }
    let Ok(path) = CStr::from_ptr(path_utf8).to_str() else {
        return ERR_ARGS;
    };
    catch_unwind(AssertUnwindSafe(|| {
        player.open(Path::new(path), start_ms, track_id)
    }))
    .unwrap_or(ERR_ARGS)
}

/// # Safety
/// `p` must be null or a live handle.
#[no_mangle]
pub unsafe extern "C" fn commet_music_stop(p: *mut c_void) {
    if let Some(player) = player(p) {
        let _ = catch_unwind(AssertUnwindSafe(|| player.stop()));
    }
}

/// # Safety
/// `p` must be null or a live handle.
#[no_mangle]
pub unsafe extern "C" fn commet_music_set_paused(p: *mut c_void, paused: u8) {
    if let Some(player) = player(p) {
        player.set_paused(paused != 0);
    }
}

/// # Safety
/// `p` must be null or a live handle.
#[no_mangle]
pub unsafe extern "C" fn commet_music_seek(p: *mut c_void, ms: u64) -> i32 {
    let Some(player) = player(p) else {
        return ERR_ARGS;
    };
    catch_unwind(AssertUnwindSafe(|| player.seek(ms))).unwrap_or(ERR_ARGS)
}

/// # Safety
/// `p` must be null or a live handle.
#[no_mangle]
pub unsafe extern "C" fn commet_music_set_gain(p: *mut c_void, gain: f32) {
    if let Some(player) = player(p) {
        player.set_gain(gain);
    }
}

/// # Safety
/// `p` must be null or a live handle; `out` null or writable.
#[no_mangle]
pub unsafe extern "C" fn commet_music_status(p: *mut c_void, out: *mut MusicStatus) {
    if out.is_null() {
        return;
    }
    let status = match player(p) {
        Some(player) => catch_unwind(AssertUnwindSafe(|| player.status())).ok(),
        None => None,
    };
    *out = match status {
        Some(s) => MusicStatus {
            state: s.state as u32,
            underruns: s.underruns,
            track_id: s.track_id,
            position_ms: s.position_ms,
            duration_ms: s.duration_ms,
            error: s.error,
            _pad: 0,
        },
        None => MusicStatus::default(),
    };
}

/// # Safety
/// `ctx` must be null or a live handle; `out` null or writable for
/// `frames * channels` samples.
#[no_mangle]
pub unsafe extern "C" fn commet_music_pull(
    ctx: *mut c_void,
    out: *mut i16,
    frames: usize,
    channels: usize,
    sample_rate: i32,
) -> usize {
    if out.is_null() {
        return 0;
    }
    let Some(len) = frames.checked_mul(channels) else {
        return 0;
    };
    let out = std::slice::from_raw_parts_mut(out, len);
    let Some(player) = player(ctx) else {
        out.fill(0);
        return 0;
    };
    catch_unwind(AssertUnwindSafe(|| player.pull(out, channels, sample_rate))).unwrap_or_else(
        |_| {
            out.fill(0);
            0
        },
    )
}
