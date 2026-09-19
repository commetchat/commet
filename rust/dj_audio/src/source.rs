//! Opening, probing, seeking and decoding one file with symphonia.
//!
//! Timestamps are converted to source frames and anything before the
//! requested start is dropped here, so the first frame handed to the
//! resampler is the start position (to the sample, codec permitting).

use std::fs::File;
use std::path::Path;

use symphonia::core::codecs::audio::well_known::CODEC_ID_MP3;
use symphonia::core::codecs::audio::{AudioDecoder, AudioDecoderOptions};
use symphonia::core::errors::Error;
use symphonia::core::formats::probe::Hint;
use symphonia::core::formats::{FormatOptions, FormatReader, SeekMode, SeekTo, Track, TrackType};
use symphonia::core::io::MediaSourceStream;
use symphonia::core::meta::MetadataOptions;
use symphonia::core::packet::Packet;
use symphonia::core::units::{Time, TimeBase};

use crate::mp4;
use crate::ring::Frame;
use crate::{ERR_DECODER, ERR_OPEN, ERR_SEEK, ERR_UNSUPPORTED};

/// Decoded audio before this much ahead of a seek target primes the codec
/// (AAC overlap, MP3 bit reservoir) and is then discarded.
const PREROLL_MS: u64 = 100;
/// Packet bytes the duration scan reads before extrapolating by file size.
const SCAN_LIMIT_BYTES: u64 = 64 << 20;
/// A scan longer than the Xing/Info header by more than this means the
/// header undercounts (concatenated streams); less is just padding frames.
const MP3_HEADER_SLACK_MS: u64 = 500;

pub(crate) struct Source {
    format: Box<dyn FormatReader>,
    decoder: Box<dyn AudioDecoder>,
    track_id: u32,
    time_base: Option<TimeBase>,
    gapless: bool,
    /// First packet, already read by a manual seek.
    pending: Option<Packet>,
    /// Drop audio before this time; `None` once reached.
    target_ms: Option<u64>,
    /// MP4 edit-list start (media time, timescale), subtracted from every
    /// timestamp.
    priming: Option<(u64, u32)>,
    interleaved: Vec<f32>,
}

pub(crate) struct Opened {
    /// `None` when the start position is at or past the end.
    pub source: Option<Source>,
    pub duration_ms: u64,
}

struct Selected {
    track_id: u32,
    time_base: Option<TimeBase>,
    rate: Option<u32>,
    is_mp3: bool,
    reported_ms: Option<u64>,
    decoder: Box<dyn AudioDecoder>,
}

fn probe(path: &Path) -> Result<Box<dyn FormatReader>, i32> {
    let file = File::open(path).map_err(|_| ERR_OPEN)?;
    let mss = MediaSourceStream::new(Box::new(file), Default::default());
    let mut hint = Hint::new();
    if let Some(ext) = path.extension().and_then(|e| e.to_str()) {
        hint.with_extension(ext);
    }
    symphonia::default::get_probe()
        .probe(
            &hint,
            mss,
            FormatOptions::default(),
            MetadataOptions::default(),
        )
        .map_err(|_| ERR_UNSUPPORTED)
}

fn time_ms(tb: TimeBase, dur: symphonia::core::units::Duration) -> Option<u64> {
    tb.calc_duration(dur).map(|t| t.as_millis().max(0) as u64)
}

fn make_decoder(track: &Track) -> Option<Selected> {
    let params = track.codec_params.as_ref()?.audio()?;
    let is_mp3 = params.codec == CODEC_ID_MP3;
    // MP3 trimming trusts the first stream's Xing frame count, which cuts
    // off concatenated streams; its delay frames have negative timestamps
    // and are dropped by the start target instead.
    let opts = AudioDecoderOptions::default().gapless(!is_mp3);
    let decoder = symphonia::default::get_codecs()
        .make_audio_decoder(params, &opts)
        .ok()?;
    let rate = params.sample_rate.filter(|r| *r > 0);
    let reported_ms = match (track.num_frames, rate) {
        (Some(n), Some(r)) if n > 0 => Some(n.saturating_mul(1000) / r as u64),
        _ => match (track.duration, track.time_base) {
            (Some(d), Some(tb)) if d.get() > 0 => time_ms(tb, d),
            _ => None,
        },
    };
    Some(Selected {
        track_id: track.id,
        time_base: track.time_base,
        rate,
        is_mp3,
        reported_ms,
        decoder,
    })
}

fn select(format: &dyn FormatReader) -> Result<Selected, i32> {
    if let Some(sel) = format
        .default_track(TrackType::Audio)
        .and_then(make_decoder)
    {
        return Ok(sel);
    }
    format
        .tracks()
        .iter()
        .find_map(make_decoder)
        .ok_or(ERR_UNSUPPORTED)
}

/// Converts a timestamp to milliseconds (may be negative).
fn ts_ms(ts: i64, tb: Option<TimeBase>, rate: Option<u32>) -> i128 {
    match (tb, rate) {
        (Some(tb), _) => ts as i128 * tb.numer.get() as i128 * 1000 / tb.denom.get() as i128,
        (None, Some(r)) => ts as i128 * 1000 / r as i128,
        _ => ts as i128,
    }
}

/// Converts a timestamp to frames at `rate`.
fn ts_frames(ts: i64, tb: Option<TimeBase>, rate: u32) -> i128 {
    match tb {
        Some(tb) => ts as i128 * tb.numer.get() as i128 * rate as i128 / tb.denom.get() as i128,
        None => ts as i128,
    }
}

/// End of the packet's valid frames. (For MP3 symphonia reports the whole
/// frame as `dur` and may put junk in `trim_end`, so that is left out.)
fn packet_end(p: &Packet) -> i64 {
    let valid = p.trim_start.get().saturating_add(p.dur.get());
    p.pts
        .get()
        .saturating_add(valid.min(i64::MAX as u64) as i64)
}

/// Demuxes (without decoding) to find where the track really ends. Cheap
/// for MP3, where it also catches concatenated streams the header misses.
fn scan_duration_ms(format: &mut dyn FormatReader, sel: &Selected, file_len: u64) -> Option<u64> {
    let mut bytes = 0u64;
    let mut end: Option<i64> = None;
    let mut capped = false;
    loop {
        match format.next_packet() {
            Ok(Some(p)) if p.track_id == sel.track_id => {
                bytes += p.data.len() as u64;
                let e = packet_end(&p);
                end = Some(end.map_or(e, |x| x.max(e)));
                if bytes > SCAN_LIMIT_BYTES {
                    capped = true;
                    break;
                }
            }
            Ok(Some(_)) => {}
            _ => break,
        }
    }
    let ms = ts_ms(end?, sel.time_base, sel.rate).max(0) as u64;
    if capped && bytes > 0 {
        Some((ms as u128 * file_len as u128 / bytes as u128) as u64)
    } else {
        Some(ms)
    }
}

/// Reads packets until the one that covers `ms`.
fn skip_to(format: &mut dyn FormatReader, sel: &Selected, ms: u64) -> Result<Option<Packet>, i32> {
    loop {
        match format.next_packet() {
            Ok(Some(p)) if p.track_id == sel.track_id => {
                if ts_ms(packet_end(&p), sel.time_base, sel.rate) > ms as i128 {
                    return Ok(Some(p));
                }
            }
            Ok(Some(_)) => {}
            Ok(None) | Err(Error::IoError(_)) => return Ok(None),
            Err(_) => return Err(ERR_SEEK),
        }
    }
}

/// Opens `path` positioned at `start_ms`. `known_duration_ms` skips the
/// duration work when re-opening the same file for a seek.
pub(crate) fn open(
    path: &Path,
    start_ms: u64,
    known_duration_ms: Option<u64>,
) -> Result<Opened, i32> {
    let mut format = probe(path)?;
    let mut sel = select(format.as_ref())?;
    let edit = mp4::edit(path);
    // Where our zero sits on the track's timeline.
    let priming_ms = edit.map_or(0, |e| e.media_time * 1000 / e.timescale as u64);

    let duration_ms = match known_duration_ms {
        Some(d) => d,
        None if edit.is_some_and(|e| e.duration_ms.is_some()) => {
            edit.and_then(|e| e.duration_ms).unwrap_or(0)
        }
        None if sel.is_mp3 || sel.reported_ms.is_none() => {
            let file_len = std::fs::metadata(path).map(|m| m.len()).unwrap_or(0);
            let scanned = scan_duration_ms(format.as_mut(), &sel, file_len);
            // The scan consumed the reader; start over.
            format = probe(path)?;
            sel = select(format.as_ref())?;
            match (sel.reported_ms, scanned) {
                // The header is exact unless it only describes the first of
                // several concatenated streams.
                (Some(a), Some(b)) => {
                    if b > a + MP3_HEADER_SLACK_MS {
                        b
                    } else {
                        a
                    }
                }
                (a, b) => a.or(b).unwrap_or(0),
            }
            .saturating_sub(priming_ms)
        }
        None => sel.reported_ms.unwrap_or(0).saturating_sub(priming_ms),
    };

    if duration_ms > 0 && start_ms >= duration_ms {
        return Ok(Opened {
            source: None,
            duration_ms,
        });
    }

    let mut pending = None;
    let seek_ms = start_ms.saturating_sub(PREROLL_MS);
    if seek_ms > 0 {
        let to = SeekTo::Time {
            time: Time::from_millis_u64(seek_ms + priming_ms),
            track_id: Some(sel.track_id),
        };
        match format.seek(SeekMode::Accurate, to) {
            Ok(_) => sel.decoder.reset(),
            Err(_) => {
                // Unseekable or out of the header's range (concatenated MP3):
                // walk the packets from the top instead.
                format = probe(path).map_err(|_| ERR_SEEK)?;
                sel = select(format.as_ref()).map_err(|_| ERR_SEEK)?;
                match skip_to(format.as_mut(), &sel, seek_ms + priming_ms)? {
                    Some(p) => pending = Some(p),
                    None => {
                        return Ok(Opened {
                            source: None,
                            duration_ms,
                        })
                    }
                }
            }
        }
    }

    Ok(Opened {
        source: Some(Source {
            format,
            decoder: sel.decoder,
            track_id: sel.track_id,
            time_base: sel.time_base,
            gapless: !sel.is_mp3,
            pending,
            target_ms: Some(start_ms),
            priming: edit.map(|e| (e.media_time, e.timescale)),
            interleaved: Vec::new(),
        }),
        duration_ms,
    })
}

impl Source {
    fn reselect(&mut self) -> bool {
        match select(self.format.as_ref()) {
            Ok(sel) => {
                self.decoder = sel.decoder;
                self.track_id = sel.track_id;
                self.time_base = sel.time_base;
                self.gapless = !sel.is_mp3;
                true
            }
            Err(_) => false,
        }
    }

    fn next_packet(&mut self) -> Result<Option<Packet>, i32> {
        if let Some(p) = self.pending.take() {
            return Ok(Some(p));
        }
        loop {
            match self.format.next_packet() {
                Ok(Some(p)) if p.track_id == self.track_id => return Ok(Some(p)),
                Ok(Some(_)) => {}
                Ok(None) => return Ok(None),
                // A truncated tail ends the track rather than failing it.
                Err(Error::IoError(_)) => return Ok(None),
                // Chained stream with new tracks.
                Err(Error::ResetRequired) => {
                    if !self.reselect() {
                        return Ok(None);
                    }
                }
                Err(Error::DecodeError(_)) => {}
                Err(_) => return Err(ERR_DECODER),
            }
        }
    }

    /// Decodes the next packet into stereo frames (cleared first). Returns
    /// the source rate, or `None` at the end of the track. The frames may be
    /// empty (corrupt packet, or still before the start target).
    pub fn decode_next(&mut self, stereo: &mut Vec<Frame>) -> Result<Option<u32>, i32> {
        stereo.clear();
        let Some(packet) = self.next_packet()? else {
            return Ok(None);
        };
        let buf = match self.decoder.decode(&packet) {
            Ok(buf) => buf,
            // A corrupt frame is skipped, as players do.
            Err(Error::DecodeError(_)) | Err(Error::IoError(_)) => return Ok(Some(0)),
            Err(Error::ResetRequired) => {
                if !self.reselect() {
                    return Ok(None);
                }
                return Ok(Some(0));
            }
            Err(_) => return Err(ERR_DECODER),
        };
        let rate = buf.spec().rate();
        let channels = buf.spec().channels().count();
        let frames = buf.frames();
        if rate == 0 || channels == 0 || frames == 0 {
            return Ok(Some(0));
        }
        let mut skip = 0usize;
        if let Some(target) = self.target_ms {
            let first_ts = if self.gapless {
                packet
                    .pts
                    .get()
                    .saturating_add(packet.trim_start.get().min(i64::MAX as u64) as i64)
            } else {
                packet.pts.get()
            };
            let priming = self.priming.map_or(0, |(t, scale)| {
                t as i128 * rate as i128 / scale.max(1) as i128
            });
            let start = ts_frames(first_ts, self.time_base, rate) - priming;
            let target_frame = target as i128 * rate as i128 / 1000;
            let s = (target_frame - start).max(0);
            if s >= frames as i128 {
                return Ok(Some(rate));
            }
            skip = s as usize;
            self.target_ms = None;
        }
        self.interleaved.resize(frames * channels, 0.0);
        buf.copy_to_slice_interleaved(&mut self.interleaved);
        stereo.reserve(frames - skip);
        for f in self.interleaved.chunks_exact(channels).skip(skip) {
            stereo.push(match channels {
                1 => [f[0], f[0]],
                2 => [f[0], f[1]],
                // Surround: fronts as-is, everything else folded in at -6 dB.
                // Music from the usual sources is stereo; the limiter
                // catches the extra headroom this needs.
                _ => {
                    let rest: f32 = f[2..].iter().sum::<f32>() * 0.5;
                    [f[0] + rest, f[1] + rest]
                }
            });
        }
        Ok(Some(rate))
    }
}
