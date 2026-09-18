//! C ABI.
//!
//! Two kinds of entry points:
//!
//! * handle management and control (`commet_dsp_create`, `..._set_params`,
//!   `..._get_report`, `..._destroy`), called from Dart or JS on any thread;
//! * audio callbacks whose signatures match libwebrtc's
//!   `RTCAudioProcessing::CustomProcessing` (`commet_dsp_capture_*`,
//!   `commet_dsp_render_*`). The native plugin stores their addresses plus the
//!   handle as `ctx` and calls them from the audio thread.
//!
//! Lifetime rule: clear the processors on the native side before calling
//! `commet_dsp_destroy`. The handle is not reference counted.

use std::ffi::c_void;

use crate::{Dsp, Params, Report};

/// Bump when the struct layouts, their meaning or the callback signatures
/// change. 2: `Params::speaker_bleed` (was padding), `commet_dsp_feed_reference`.
pub const ABI_VERSION: u32 = 2;

#[no_mangle]
pub extern "C" fn commet_dsp_abi_version() -> u32 {
    ABI_VERSION
}

#[no_mangle]
pub extern "C" fn commet_dsp_default_params(out: *mut Params) {
    if out.is_null() {
        return;
    }
    unsafe { *out = Params::default() };
}

#[no_mangle]
pub extern "C" fn commet_dsp_create(params: *const Params) -> *mut Dsp {
    let p = if params.is_null() { Params::default() } else { unsafe { *params } };
    Box::into_raw(Dsp::new(p))
}

#[no_mangle]
pub extern "C" fn commet_dsp_destroy(h: *mut Dsp) {
    if h.is_null() {
        return;
    }
    unsafe { drop(Box::from_raw(h)) };
}

#[no_mangle]
pub extern "C" fn commet_dsp_set_params(h: *mut Dsp, params: *const Params) {
    if h.is_null() || params.is_null() {
        return;
    }
    let dsp = unsafe { &mut *h };
    dsp.set_params(unsafe { &*params });
}

#[no_mangle]
pub extern "C" fn commet_dsp_get_report(h: *mut Dsp, out: *mut Report) {
    if h.is_null() || out.is_null() {
        return;
    }
    let dsp = unsafe { &*h };
    unsafe { *out = dsp.report() };
}

/// Process one 10 ms block in place. `n * 100` is taken as the sample rate.
#[no_mangle]
pub extern "C" fn commet_dsp_process_block(h: *mut Dsp, buf: *mut f32, n: usize) {
    if h.is_null() || buf.is_null() || n == 0 {
        return;
    }
    let dsp = unsafe { &mut *h };
    let slice = unsafe { std::slice::from_raw_parts_mut(buf, n) };
    dsp.process_block(slice);
}

/// Streaming variant (48 kHz only, any block size up to `MAX_STREAM_BLOCK`).
#[no_mangle]
pub extern "C" fn commet_dsp_process_stream(h: *mut Dsp, buf: *mut f32, n: usize) {
    if h.is_null() || buf.is_null() || n == 0 {
        return;
    }
    let dsp = unsafe { &mut *h };
    let slice = unsafe { std::slice::from_raw_parts_mut(buf, n.min(crate::MAX_STREAM_BLOCK)) };
    dsp.process_stream(slice);
}

#[no_mangle]
pub extern "C" fn commet_dsp_feed_render(h: *mut Dsp, buf: *const f32, n: usize) {
    if h.is_null() || buf.is_null() || n == 0 {
        return;
    }
    let dsp = unsafe { &*h };
    let slice = unsafe { std::slice::from_raw_parts(buf, n) };
    dsp.feed_render(slice);
}

/// System audio from a loopback capturer: int16 PCM, `frames` frames of
/// `channels` interleaved channels at `sample_rate`. A null `samples` is a
/// block the capturer reported as silent. Shaped as the callback the native
/// loopback tap calls (`ctx` is the handle), from the capturer's own thread.
#[no_mangle]
pub extern "C" fn commet_dsp_feed_reference(
    ctx: *mut c_void,
    samples: *const i16,
    frames: usize,
    channels: usize,
    sample_rate: i32,
) {
    if ctx.is_null() || frames == 0 || sample_rate <= 0 {
        return;
    }
    let dsp = unsafe { &*(ctx as *const Dsp) };
    let channels = channels.max(1);
    let pcm = if samples.is_null() {
        None
    } else {
        Some(unsafe { std::slice::from_raw_parts(samples, frames * channels) })
    };
    dsp.feed_reference_i16(pcm, channels, sample_rate as usize);
}

#[no_mangle]
pub extern "C" fn commet_dsp_reset(h: *mut Dsp, sample_rate: i32) {
    if h.is_null() || sample_rate <= 0 {
        return;
    }
    let dsp = unsafe { &mut *h };
    dsp.reset(sample_rate as usize);
}

// ---- libwebrtc CustomProcessing shaped callbacks -------------------------
//
// void Initialize(int sample_rate_hz, int num_channels)
// void Process(int num_bands, int num_frames, int buffer_size, float* buffer)
// void Reset(int new_rate)
//
// `buffer` holds channel 0 only, full band, `num_frames` samples (one 10 ms
// block); `num_bands` and `buffer_size` are informational.

#[no_mangle]
pub extern "C" fn commet_dsp_capture_init(ctx: *mut c_void, sample_rate_hz: i32, _num_channels: i32) {
    commet_dsp_reset(ctx as *mut Dsp, sample_rate_hz);
}

#[no_mangle]
pub extern "C" fn commet_dsp_capture_process(
    ctx: *mut c_void,
    _num_bands: i32,
    num_frames: i32,
    _buffer_size: i32,
    buffer: *mut f32,
) {
    if num_frames <= 0 {
        return;
    }
    commet_dsp_process_block(ctx as *mut Dsp, buffer, num_frames as usize);
}

#[no_mangle]
pub extern "C" fn commet_dsp_capture_reset(ctx: *mut c_void, new_rate: i32) {
    commet_dsp_reset(ctx as *mut Dsp, new_rate);
}

#[no_mangle]
pub extern "C" fn commet_dsp_render_init(_ctx: *mut c_void, _sample_rate_hz: i32, _num_channels: i32) {}

#[no_mangle]
pub extern "C" fn commet_dsp_render_process(
    ctx: *mut c_void,
    _num_bands: i32,
    num_frames: i32,
    _buffer_size: i32,
    buffer: *mut f32,
) {
    if num_frames <= 0 {
        return;
    }
    commet_dsp_feed_render(ctx as *mut Dsp, buffer, num_frames as usize);
}

#[no_mangle]
pub extern "C" fn commet_dsp_render_reset(_ctx: *mut c_void, _new_rate: i32) {}

// ---- wasm helpers ----------------------------------------------------------
//
// The AudioWorklet talks to the wasm module without a bindgen layer, so it
// needs a way to get buffers inside linear memory.

#[no_mangle]
pub extern "C" fn commet_dsp_alloc_f32(n: usize) -> *mut f32 {
    let mut v: Vec<f32> = vec![0.0; n.max(1)];
    let p = v.as_mut_ptr();
    std::mem::forget(v);
    p
}

#[no_mangle]
pub extern "C" fn commet_dsp_free_f32(p: *mut f32, n: usize) {
    if p.is_null() {
        return;
    }
    unsafe { drop(Vec::from_raw_parts(p, n.max(1), n.max(1))) };
}

#[no_mangle]
pub extern "C" fn commet_dsp_params_size() -> usize {
    std::mem::size_of::<Params>()
}

#[no_mangle]
pub extern "C" fn commet_dsp_report_size() -> usize {
    std::mem::size_of::<Report>()
}

/// Allocate a `Params` filled with defaults (for wasm callers).
#[no_mangle]
pub extern "C" fn commet_dsp_params_alloc() -> *mut Params {
    Box::into_raw(Box::new(Params::default()))
}

#[no_mangle]
pub extern "C" fn commet_dsp_params_free(p: *mut Params) {
    if !p.is_null() {
        unsafe { drop(Box::from_raw(p)) };
    }
}

#[no_mangle]
pub extern "C" fn commet_dsp_report_alloc() -> *mut Report {
    Box::into_raw(Box::new(Report::default()))
}

#[no_mangle]
pub extern "C" fn commet_dsp_report_free(p: *mut Report) {
    if !p.is_null() {
        unsafe { drop(Box::from_raw(p)) };
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn struct_layouts_are_stable() {
        // Dart and JS mirror these by hand.
        assert_eq!(commet_dsp_params_size(), 24);
        assert_eq!(commet_dsp_report_size(), 28);
    }

    #[test]
    fn callbacks_round_trip_through_ctx() {
        let h = commet_dsp_create(std::ptr::null());
        let mut buf = vec![0.0f32; 480];
        commet_dsp_capture_init(h as *mut c_void, 48000, 1);
        commet_dsp_capture_process(h as *mut c_void, 3, 480, 480, buf.as_mut_ptr());
        commet_dsp_render_process(h as *mut c_void, 3, 480, 480, buf.as_mut_ptr());
        let mut r = Report::default();
        commet_dsp_get_report(h, &mut r);
        assert_eq!(r.frames, 1);
        assert_eq!(r.sample_rate, 48000);
        commet_dsp_destroy(h);
    }

    #[test]
    fn reference_reaches_the_capture_side() {
        let h = commet_dsp_create(std::ptr::null());
        let pcm = vec![8000i16; 480 * 2];
        let mut buf = vec![0.0f32; 480];
        commet_dsp_feed_reference(h as *mut c_void, pcm.as_ptr(), 480, 2, 48000);
        commet_dsp_capture_process(h as *mut c_void, 3, 480, 480, buf.as_mut_ptr());
        let mut r = Report::default();
        commet_dsp_get_report(h, &mut r);
        assert_eq!(r.flags & crate::REPORT_FLAG_REFERENCE, crate::REPORT_FLAG_REFERENCE);
        // silent blocks still count as the reference being there
        commet_dsp_feed_reference(h as *mut c_void, std::ptr::null(), 480, 2, 48000);
        commet_dsp_capture_process(h as *mut c_void, 3, 480, 480, buf.as_mut_ptr());
        commet_dsp_get_report(h, &mut r);
        assert_eq!(r.flags & crate::REPORT_FLAG_REFERENCE, crate::REPORT_FLAG_REFERENCE);
        commet_dsp_destroy(h);
    }
}
