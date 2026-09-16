use audio_decode::decode;

fn peak(samples: &[f32]) -> f32 {
    samples.iter().fold(0.0, |m, s| m.max(s.abs()))
}

#[test]
fn decodes_mp3_to_interleaved_pcm() {
    let bytes = include_bytes!("fixtures/sine_-20dbfs_stereo.mp3");
    let pcm = decode(bytes, Some("mp3"), 30.0).unwrap();
    assert_eq!(pcm.sample_rate, 44100);
    assert_eq!(pcm.channels, 2);
    let seconds = pcm.samples.len() as f64 / 2.0 / 44100.0;
    // One second of audio; encoder padding may add a frame or two.
    assert!((0.99..1.1).contains(&seconds), "{seconds} s");
    // -20 dBFS sine.
    assert!((peak(&pcm.samples) - 0.1).abs() < 0.01, "{}", peak(&pcm.samples));
}

#[test]
fn decodes_ogg_vorbis_without_a_hint() {
    let bytes = include_bytes!("fixtures/sine_-20dbfs_mono.ogg");
    let pcm = decode(bytes, None, 30.0).unwrap();
    assert_eq!(pcm.sample_rate, 48000);
    assert_eq!(pcm.channels, 1);
    assert!((peak(&pcm.samples) - 0.1).abs() < 0.01);
}

#[test]
fn stops_at_the_duration_cap() {
    let bytes = include_bytes!("fixtures/sine_-20dbfs_stereo.mp3");
    let pcm = decode(bytes, Some("mp3"), 0.25).unwrap();
    let seconds = pcm.samples.len() as f64 / 2.0 / 44100.0;
    assert!((0.25..0.3).contains(&seconds), "{seconds} s");
    assert!(pcm.truncated);
}

#[test]
fn rejects_garbage() {
    assert!(decode(b"definitely not audio", Some("mp3"), 30.0).is_err());
}

#[test]
fn c_abi_round_trips() {
    use audio_decode::ffi::*;
    let bytes = include_bytes!("fixtures/sine_-20dbfs_stereo.mp3");
    let mut out = std::mem::MaybeUninit::<DecodedAudio>::uninit();
    let code = unsafe {
        commet_audio_decode(bytes.as_ptr(), bytes.len(), c"mp3".as_ptr(), 30.0, out.as_mut_ptr())
    };
    assert_eq!(code, 0);
    let out = unsafe { out.assume_init() };
    assert_eq!((out.sample_rate, out.channels, out.truncated), (44100, 2, 0));
    assert!(out.len > 80_000);
    unsafe { commet_audio_decode_free(out.samples, out.len) };

    let mut bad = std::mem::MaybeUninit::<DecodedAudio>::uninit();
    let code = unsafe {
        commet_audio_decode(b"nope".as_ptr(), 4, std::ptr::null(), 30.0, bad.as_mut_ptr())
    };
    assert_eq!(code, ERR_DECODE);
    assert!(unsafe { bad.assume_init() }.samples.is_null());
}
