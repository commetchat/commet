//! C ABI, loaded from Dart with `dart:ffi` (see
//! `commet/lib/client/components/soundboard/audio_decoder/audio_decoder_native.dart`).
//!
//! `commet_audio_decode` fills `out` and returns 0, or returns a negative
//! code and leaves `out` zeroed. The caller must pass `out.samples` and
//! `out.len` back to `commet_audio_decode_free`.

use std::ffi::{c_char, CStr};

use crate::decode;

/// Bump when `DecodedAudio` or the function signatures change.
pub const ABI_VERSION: u32 = 1;

#[repr(C)]
pub struct DecodedAudio {
    /// Interleaved f32 samples, owned by Rust.
    pub samples: *mut f32,
    /// Number of samples (frames * channels).
    pub len: usize,
    pub sample_rate: u32,
    pub channels: u32,
    /// 1 when decoding stopped at `max_seconds`.
    pub truncated: u32,
}

pub const ERR_ARGS: i32 = -1;
pub const ERR_DECODE: i32 = -2;

#[no_mangle]
pub extern "C" fn commet_audio_decode_abi_version() -> u32 {
    ABI_VERSION
}

/// # Safety
/// `data` must point to `len` readable bytes, `extension` must be null or a
/// NUL-terminated string, and `out` must point to a writable `DecodedAudio`.
#[no_mangle]
pub unsafe extern "C" fn commet_audio_decode(
    data: *const u8,
    len: usize,
    extension: *const c_char,
    max_seconds: f64,
    out: *mut DecodedAudio,
) -> i32 {
    if data.is_null() || out.is_null() {
        return ERR_ARGS;
    }
    *out = DecodedAudio {
        samples: std::ptr::null_mut(),
        len: 0,
        sample_rate: 0,
        channels: 0,
        truncated: 0,
    };
    let bytes = std::slice::from_raw_parts(data, len);
    let ext = if extension.is_null() {
        None
    } else {
        CStr::from_ptr(extension).to_str().ok()
    };
    // symphonia may panic on hostile input; never unwind into Dart.
    let result = std::panic::catch_unwind(|| decode(bytes, ext, max_seconds));
    let pcm = match result {
        Ok(Ok(pcm)) => pcm,
        _ => return ERR_DECODE,
    };
    let mut samples = pcm.samples.into_boxed_slice();
    *out = DecodedAudio {
        samples: samples.as_mut_ptr(),
        len: samples.len(),
        sample_rate: pcm.sample_rate,
        channels: pcm.channels,
        truncated: pcm.truncated as u32,
    };
    std::mem::forget(samples);
    0
}

/// # Safety
/// `samples`/`len` must come from a successful `commet_audio_decode`, and be
/// freed once.
#[no_mangle]
pub unsafe extern "C" fn commet_audio_decode_free(samples: *mut f32, len: usize) {
    if samples.is_null() {
        return;
    }
    drop(Box::from_raw(std::ptr::slice_from_raw_parts_mut(samples, len)));
}
