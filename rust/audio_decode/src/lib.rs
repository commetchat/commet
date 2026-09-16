//! Decodes short compressed clips (soundboard sounds) to PCM so the app can
//! measure their loudness at import. Pure Rust (symphonia): MP3, Ogg Vorbis,
//! FLAC and WAV.
//!
//! The loudness maths lives in Dart (`soundboard_normalizer.dart`) so the WAV and
//! browser paths share it; this crate only turns bytes into samples.

pub mod ffi;

use std::io::Cursor;

use symphonia::core::codecs::audio::AudioDecoderOptions;
use symphonia::core::errors::Error as SymphoniaError;
use symphonia::core::formats::probe::Hint;
use symphonia::core::formats::{FormatOptions, TrackType};
use symphonia::core::io::MediaSourceStream;
use symphonia::core::meta::MetadataOptions;

/// Decoded audio, interleaved `f32` in [-1, 1].
#[derive(Debug, Default)]
pub struct Pcm {
    pub sample_rate: u32,
    pub channels: u32,
    pub samples: Vec<f32>,
    /// True when decoding stopped at the duration cap.
    pub truncated: bool,
}

#[derive(Debug)]
pub enum DecodeError {
    Unsupported(String),
    NoAudio,
}

impl std::fmt::Display for DecodeError {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        match self {
            DecodeError::Unsupported(e) => write!(f, "unsupported audio: {e}"),
            DecodeError::NoAudio => write!(f, "no decodable audio"),
        }
    }
}

impl std::error::Error for DecodeError {}

/// Decodes `bytes` up to `max_seconds` of audio. `extension` ("mp3", "ogg")
/// only helps probing; the container is still detected from the bytes.
pub fn decode(bytes: &[u8], extension: Option<&str>, max_seconds: f64) -> Result<Pcm, DecodeError> {
    let mss = MediaSourceStream::new(Box::new(Cursor::new(bytes.to_vec())), Default::default());
    let mut hint = Hint::new();
    if let Some(ext) = extension {
        hint.with_extension(ext);
    }
    let mut format = symphonia::default::get_probe()
        .probe(&hint, mss, FormatOptions::default(), MetadataOptions::default())
        .map_err(|e| DecodeError::Unsupported(e.to_string()))?;
    let track = format.default_track(TrackType::Audio).ok_or(DecodeError::NoAudio)?;
    let params = track
        .codec_params
        .as_ref()
        .and_then(|p| p.audio())
        .ok_or(DecodeError::NoAudio)?;
    let mut decoder = symphonia::default::get_codecs()
        .make_audio_decoder(params, &AudioDecoderOptions::default())
        .map_err(|e| DecodeError::Unsupported(e.to_string()))?;
    let track_id = track.id;

    let mut pcm = Pcm::default();
    let mut max_samples = usize::MAX;
    let mut chunk: Vec<f32> = Vec::new();
    loop {
        let packet = match format.next_packet() {
            Ok(Some(p)) => p,
            Ok(None) => break,
            // A truncated tail still leaves us everything before it.
            Err(SymphoniaError::IoError(_)) => break,
            Err(e) => return Err(DecodeError::Unsupported(e.to_string())),
        };
        if packet.track_id != track_id {
            continue;
        }
        let buf = match decoder.decode(&packet) {
            Ok(buf) => buf,
            // A corrupt frame is skipped, as players do.
            Err(SymphoniaError::DecodeError(_)) => continue,
            Err(e) => return Err(DecodeError::Unsupported(e.to_string())),
        };
        if pcm.sample_rate == 0 {
            let spec = buf.spec();
            pcm.sample_rate = spec.rate();
            pcm.channels = spec.channels().count() as u32;
            if pcm.sample_rate == 0 || pcm.channels == 0 {
                return Err(DecodeError::NoAudio);
            }
            let frames = (max_seconds.max(0.0) * pcm.sample_rate as f64).round() as usize;
            max_samples = frames.saturating_mul(pcm.channels as usize);
        } else if buf.spec().rate() != pcm.sample_rate
            || buf.spec().channels().count() as u32 != pcm.channels
        {
            // A chained stream changed layout; the part before is enough to
            // measure and mixing layouts would corrupt the interleaving.
            break;
        }
        chunk.resize(buf.samples_interleaved(), 0.0);
        buf.copy_to_slice_interleaved(&mut chunk);
        let room = max_samples - pcm.samples.len();
        if chunk.len() >= room {
            pcm.samples.extend_from_slice(&chunk[..room]);
            pcm.truncated = true;
            break;
        }
        pcm.samples.extend_from_slice(&chunk);
    }
    if pcm.samples.is_empty() {
        return Err(DecodeError::NoAudio);
    }
    Ok(pcm)
}
