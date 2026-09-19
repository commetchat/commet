//! Reads the MP4 edit list of the first sound track, which symphonia's
//! isomp4 demuxer ignores. AAC encoders prepend priming samples (1024 or
//! 2112) and record them as the edit's media time; without this every
//! position in an .m4a would be off by that much.

use std::fs::File;
use std::io::{Read, Seek, SeekFrom};
use std::path::Path;

/// moov boxes bigger than this are not worth parsing for one number.
const MAX_MOOV: u64 = 64 << 20;

#[derive(Clone, Copy, Debug, PartialEq, Eq)]
pub(crate) struct Edit {
    /// Media time where playback starts, in `timescale` units.
    pub media_time: u64,
    pub timescale: u32,
    /// Playable length from the edit, when the file states one.
    pub duration_ms: Option<u64>,
}

fn be_u32(b: &[u8], at: usize) -> Option<u32> {
    Some(u32::from_be_bytes(b.get(at..at + 4)?.try_into().ok()?))
}

fn be_u64(b: &[u8], at: usize) -> Option<u64> {
    Some(u64::from_be_bytes(b.get(at..at + 8)?.try_into().ok()?))
}

/// Iterates the child boxes of `b` as (type, payload).
fn boxes(b: &[u8]) -> impl Iterator<Item = (&[u8], &[u8])> {
    let mut at = 0usize;
    std::iter::from_fn(move || {
        let size = be_u32(b, at)? as u64;
        let kind = b.get(at + 4..at + 8)?;
        let (header, size) = match size {
            0 => (8, (b.len() - at) as u64),
            1 => (16, be_u64(b, at + 8)?),
            s => (8, s),
        };
        if size < header as u64 || at as u64 + size > b.len() as u64 {
            return None;
        }
        let payload = &b[at + header..at + size as usize];
        at += size as usize;
        Some((kind, payload))
    })
}

fn child<'a>(b: &'a [u8], kind: &[u8]) -> Option<&'a [u8]> {
    boxes(b).find(|(k, _)| *k == kind).map(|(_, p)| p)
}

fn parse_moov(moov: &[u8]) -> Option<Edit> {
    // mvhd: version(1) flags(3), then times, then the movie timescale.
    let mvhd = child(moov, b"mvhd")?;
    let movie_scale = if mvhd.first()? == &1 {
        be_u32(mvhd, 20)?
    } else {
        be_u32(mvhd, 12)?
    };
    for (kind, trak) in boxes(moov) {
        if kind != b"trak" {
            continue;
        }
        let Some(mdia) = child(trak, b"mdia") else {
            continue;
        };
        let is_sound = child(mdia, b"hdlr").and_then(|h| h.get(8..12)) == Some(&b"soun"[..]);
        if !is_sound {
            continue;
        }
        let mdhd = child(mdia, b"mdhd")?;
        let timescale = if mdhd.first()? == &1 {
            be_u32(mdhd, 20)?
        } else {
            be_u32(mdhd, 12)?
        };
        let elst = child(trak, b"edts").and_then(|e| child(e, b"elst"))?;
        let v1 = elst.first()? == &1;
        let count = be_u32(elst, 4)? as usize;
        let entry = if v1 { 20 } else { 12 };
        for i in 0..count.min(16) {
            let at = 8 + i * entry;
            let (seg, media) = if v1 {
                (be_u64(elst, at)?, be_u64(elst, at + 8)? as i64)
            } else {
                (
                    be_u32(elst, at)? as u64,
                    be_u32(elst, at + 4)? as i32 as i64,
                )
            };
            // -1 is an empty edit (a leading delay); skip to the real one.
            if media < 0 {
                continue;
            }
            let duration_ms = (seg > 0 && movie_scale > 0).then(|| seg * 1000 / movie_scale as u64);
            return (timescale > 0).then_some(Edit {
                media_time: media as u64,
                timescale,
                duration_ms,
            });
        }
        return None;
    }
    None
}

/// The first sound track's edit, if `path` is an MP4 that has one.
pub(crate) fn edit(path: &Path) -> Option<Edit> {
    let mut f = File::open(path).ok()?;
    let len = f.metadata().ok()?.len();
    let mut pos = 0u64;
    let mut first = true;
    while pos + 8 <= len {
        let mut h = [0u8; 16];
        f.seek(SeekFrom::Start(pos)).ok()?;
        f.read_exact(&mut h[..8]).ok()?;
        let kind: [u8; 4] = h[4..8].try_into().ok()?;
        if first && &kind != b"ftyp" {
            return None;
        }
        first = false;
        let (header, size) = match be_u32(&h, 0)? {
            0 => (8, len - pos),
            1 => {
                f.read_exact(&mut h[8..16]).ok()?;
                (16, be_u64(&h, 8)?)
            }
            s => (8, s as u64),
        };
        if size < header {
            return None;
        }
        if &kind == b"moov" {
            if size > MAX_MOOV {
                return None;
            }
            let mut moov = vec![0u8; (size - header) as usize];
            f.read_exact(&mut moov).ok()?;
            return parse_moov(&moov);
        }
        pos += size;
    }
    None
}
