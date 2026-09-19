//! DJ music source: plays a local file (yt-dlp output: AAC in MP4, plain or
//! fragmented; MP3, including concatenated streams; also Ogg Vorbis, FLAC,
//! WAV, MKV/WebM with those codecs) as 48 kHz stereo for the WebRTC music
//! track. Pure Rust (symphonia) plus our own windowed-sinc resampler.
//!
//! Dart drives a [`Player`] through the C ABI in [`ffi`]; a C++ thread in the
//! WebRTC plugin pulls 10 ms blocks from it. Decoding runs on a background
//! thread that keeps a ~3 s ring filled, so `pull` only copies, fades,
//! applies gain and soft-clips.

pub mod ffi;
mod mp4;
mod player;
mod resample;
mod ring;
mod source;

pub use player::{Player, State, Status, OUTPUT_RATE};

/// Bad arguments (null handle or path, invalid UTF-8, nothing loaded).
pub const ERR_ARGS: i32 = -1;
/// The file cannot be opened.
pub const ERR_OPEN: i32 = -2;
/// Unrecognised container, no audio track, or no decoder for its codec.
pub const ERR_UNSUPPORTED: i32 = -3;
/// Seeking to the start position failed.
pub const ERR_SEEK: i32 = -4;
/// The decoder failed (or panicked) mid-track.
pub const ERR_DECODER: i32 = -5;
