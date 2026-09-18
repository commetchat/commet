//! What the other end hears when the user has loudspeakers and no headset.
//!
//! The scenario is the one people complain about: someone is in a voice room
//! with speakers and a microphone, they are not talking, and something else
//! on their machine is making noise (a video, music, a friend's stream
//! coming back out of the speakers). That should not reach the room; the
//! moment they speak, their voice must.
//!
//! The fixtures are real recordings (`testdata/README.md`) put through a
//! loudspeaker-and-room simulation in `common::speaker_bleed`, so what the
//! DSP sees is band limited, reverberant and delayed, like real bleed.
//!
//! Two situations:
//!
//! * with a reference - the desktop app captures the system mix (WASAPI
//!   loopback, PulseAudio monitor) and WebRTC's playout, and `bleed` removes
//!   whatever of the microphone those explain;
//! * without one - the browser, where nothing but WebRTC playout is visible.
//!   There the VAD gate cannot tell a loudspeaker's voice from the user's,
//!   and the input sensitivity threshold is the only tool.
//!
//! `-- --nocapture` prints the measured numbers for every scenario.

mod common;

use audio_dsp::{Dsp, Params, FRAME_SIZE};
use common::*;

/// The settings the app ships with: noise suppression on, automatic
/// (VAD driven) input sensitivity, far-end ducking and speaker bleed
/// rejection on. Mirrors `AudioDspSettings.fromPreferences()` with default
/// preferences and the constants in `audio_dsp_settings.dart`; if those
/// move, this fails and one of the two sides is wrong.
fn shipping_defaults() -> Params {
    let p = Params::default();
    assert_eq!(p.noise_suppression, 1);
    assert_eq!(p.gate_mode, 2, "automatic input sensitivity");
    assert_eq!(p.far_end_ducking, 1);
    assert_eq!(p.speaker_bleed, 1);
    assert_eq!(p.gate_threshold_db, -50.0);
    assert_eq!(p.gate_floor_db, -40.0);
    assert_eq!(p.duck_depth_db, -20.0);
    assert_eq!(p.duck_far_threshold_db, -45.0);
    p
}

/// Microphone self noise and the room: always there under everything else.
fn floor_noise(n: usize) -> Vec<f32> {
    room_tone(n, -62.0, 4242)
}

/// Time the bleed detector gets to learn the loudspeakers before the
/// with-reference numbers count. Measured separately in
/// `the_first_second_is_the_price_of_learning`.
const WARMUP_S: f32 = 2.0;

fn warmup_frames() -> usize {
    (WARMUP_S * 100.0) as usize
}

struct Measured {
    input_db: f32,
    output_db: f32,
    peak_block_db: f32,
    gate_open: f32,
    ducking: f32,
    bleed: f32,
    vad: f32,
}

impl Measured {
    /// How much quieter the other end hears this than the microphone did.
    fn attenuation_db(&self) -> f32 {
        self.input_db - self.output_db
    }
}

/// Run and summarise, skipping the first `skip` frames in every number.
fn measure_from(name: &str, params: Params, capture: &[f32], feeds: Feeds, skip: usize) -> (Measured, Run) {
    let mut dsp = Dsp::new(params);
    let r = run(&mut dsp, capture, feeds);
    let from = skip * FRAME_SIZE;
    let frames = &r.frames[skip..];
    let frac = |f: &dyn Fn(&Frame) -> bool| frames.iter().filter(|x| f(x)).count() as f32 / frames.len() as f32;
    let m = Measured {
        input_db: rms_dbfs(&capture[from..r.out.len()]),
        output_db: rms_dbfs(&r.out[from..]),
        peak_block_db: r.out[from..].chunks(FRAME_SIZE).map(rms_dbfs).fold(-120.0f32, f32::max),
        gate_open: frac(&|f| f.gate_open),
        ducking: frac(&|f| f.ducking),
        bleed: frac(&|f| f.bleed),
        vad: frames.iter().map(|f| f.vad).sum::<f32>() / frames.len() as f32,
    };
    println!(
        "{name:<46} in {:6.1}  out {:6.1}  atten {:5.1} dB  peak {:6.1}  gate {:3.0}%  duck {:3.0}%  bleed {:3.0}%  vad {:.2}",
        m.input_db,
        m.output_db,
        m.attenuation_db(),
        m.peak_block_db,
        m.gate_open * 100.0,
        m.ducking * 100.0,
        m.bleed * 100.0,
        m.vad
    );
    (m, r)
}

fn measure(name: &str, params: Params, capture: &[f32], feeds: Feeds) -> Measured {
    measure_from(name, params, capture, feeds, 0).0
}

/// 10 ms blocks of `x` louder than `db`: where someone is actually talking.
fn blocks_above(x: &[f32], db: f32) -> Vec<usize> {
    x.chunks(FRAME_SIZE)
        .enumerate()
        .filter(|(_, b)| b.len() == FRAME_SIZE && rms_dbfs(b) > db)
        .map(|(i, _)| i)
        .collect()
}

fn rms_over(x: &[f32], blocks: &[usize]) -> f32 {
    let picked: Vec<f32> = blocks
        .iter()
        .filter(|&&i| (i + 1) * FRAME_SIZE <= x.len())
        .flat_map(|&i| x[i * FRAME_SIZE..(i + 1) * FRAME_SIZE].iter().copied())
        .collect();
    rms_dbfs(&picked)
}

/// How much of the user's voice survives: level lost over the blocks where
/// the user is talking, from `start_block` on.
fn voice_loss_db(speech: &[f32], capture: &[f32], out: &[f32], start_block: usize) -> f32 {
    let talking: Vec<usize> = blocks_above(speech, -40.0).into_iter().filter(|&i| i >= start_block).collect();
    rms_over(capture, &talking) - rms_over(out, &talking)
}

// ------------------------------------------------------------------ guards

#[test]
fn the_user_talking_is_not_damaged() {
    let speech = scale_to(&local_speech(), -22.0);
    let capture = mix(&speech, &floor_noise(speech.len()));
    let m = measure("user talking", shipping_defaults(), &capture, Feeds::default());

    assert!(m.attenuation_db() < 4.0, "the user lost {:.1} dB", m.attenuation_db());
    assert!(m.gate_open > 0.4, "gate open only {:.0}% of the time", m.gate_open * 100.0);
    assert!(m.vad > 0.3, "the VAD did not see speech (mean {:.2})", m.vad);
}

/// A fan, a PC, a room. This is also the guard that catches the DSP silently
/// not running at all, which would look exactly like bleed leaking.
#[test]
fn a_noisy_room_is_suppressed_and_gated() {
    let capture = room_tone(48_000 * 6, -40.0, 7);
    let m = measure("noisy room at -40 dBFS", shipping_defaults(), &capture, Feeds::default());
    assert!(m.attenuation_db() > 30.0, "only {:.1} dB of attenuation", m.attenuation_db());
    assert!(m.gate_open < 0.05, "gate open {:.0}% of the time", m.gate_open * 100.0);
    assert!(m.vad < 0.3, "the VAD called room noise speech ({:.2})", m.vad);
}

/// With everything off the DSP is a wire. The control the other numbers are
/// read against.
#[test]
fn with_the_dsp_off_everything_goes_through() {
    let media = media_dialogue();
    let bleed = speaker_bleed(&media, -34.0);
    let capture = mix(&bleed, &floor_noise(bleed.len()));
    let params = Params {
        noise_suppression: 0,
        gate_mode: 0,
        far_end_ducking: 0,
        speaker_bleed: 0,
        ..Params::default()
    };
    let feeds = Feeds { reference: Some(&media), ..Feeds::default() };
    let m = measure("everything off (control)", params, &capture, feeds);
    assert!(m.attenuation_db().abs() < 0.5, "not a wire: {:.1} dB", m.attenuation_db());
}

#[test]
fn far_end_audio_is_measured_on_the_render_side() {
    let far = scale_to(&far_end_voice(), -20.0);
    let capture = floor_noise(far.len());
    let mut dsp = Dsp::new(shipping_defaults());
    let r = run(&mut dsp, &capture, Feeds { render: Some(&far), ..Feeds::default() });
    let loud = r.frames.iter().filter(|f| f.far_db > -45.0).count();
    assert!(
        loud > r.frames.len() / 2,
        "the far end was only seen as loud in {loud} of {} frames",
        r.frames.len()
    );
}

// ------------------------------------------- with a reference (the desktop)

/// The headline case: speakers at a normal volume, the user silent, the
/// system mix captured. Whatever is playing has to come out far enough down
/// that the room cannot make it out; -50 dBFS peak blocks is about the
/// level of a quiet room.
#[test]
fn dialogue_from_the_speakers_is_removed() {
    let media = media_dialogue();
    for level in [-40.0f32, -34.0, -28.0] {
        let bleed = speaker_bleed(&media, level);
        let capture = mix(&bleed, &floor_noise(bleed.len()));
        let feeds = Feeds { reference: Some(&media), ..Feeds::default() };
        let (m, _) = measure_from(
            &format!("video dialogue at {level:.0} dBFS, reference"),
            shipping_defaults(),
            &capture,
            feeds,
            warmup_frames(),
        );
        assert!(m.attenuation_db() > 25.0, "only {:.1} dB at {level:.0} dBFS", m.attenuation_db());
        assert!(
            m.peak_block_db < -50.0,
            "loudest 10 ms leaving the client is {:.1} dBFS at {level:.0} dBFS",
            m.peak_block_db
        );
    }
}

#[test]
fn music_from_the_speakers_is_removed() {
    // the system mix at a normal level; music() is unit scale
    let media = scale_to(&music(48_000 * 8), -20.0);
    let bleed = speaker_bleed(&media, -30.0);
    let capture = mix(&bleed, &floor_noise(bleed.len()));
    let feeds = Feeds { reference: Some(&media), ..Feeds::default() };
    // Music has less envelope to correlate against than speech, so the lag
    // takes about half a second longer to establish (2.1 s against 1.5 s).
    let (m, _) = measure_from("music at -30 dBFS, reference", shipping_defaults(), &capture, feeds, 300);
    assert!(m.attenuation_db() > 25.0, "only {:.1} dB of attenuation", m.attenuation_db());
    assert!(m.peak_block_db < -50.0, "loudest 10 ms is {:.1} dBFS", m.peak_block_db);
}

/// Before the detector has learned how loud the loudspeakers are at the
/// microphone, bleed goes through as it did before. This bounds how long.
#[test]
fn the_first_second_is_the_price_of_learning() {
    let media = media_dialogue();
    let bleed = speaker_bleed(&media, -34.0);
    let capture = mix(&bleed, &floor_noise(bleed.len()));
    let mut dsp = Dsp::new(shipping_defaults());
    let r = run(&mut dsp, &capture, Feeds { reference: Some(&media), ..Feeds::default() });
    let first = r.frames.iter().position(|f| f.bleed).expect("never detected");
    println!("bleed first detected after {} ms", first * 10);
    assert!(first <= 200, "took {} ms to start removing bleed", first * 10);
}

/// The reference is not sample aligned with the microphone: device buffers
/// put it ahead by tens of milliseconds, and WASAPI loopback delivers in
/// bursts after stalls. Neither may matter.
#[test]
fn a_late_and_bursty_reference_still_works() {
    let media = media_dialogue();
    let bleed = speaker_bleed(&delay_ms(&media, 60), -34.0);
    let capture = mix(&bleed, &floor_noise(bleed.len()));
    let feeds = Feeds { reference: Some(&media), reference_burst: 5, ..Feeds::default() };
    let (m, _) = measure_from(
        "dialogue, 80 ms late, 50 ms bursts",
        shipping_defaults(),
        &capture,
        feeds,
        warmup_frames(),
    );
    assert!(m.attenuation_db() > 25.0, "only {:.1} dB of attenuation", m.attenuation_db());
}

/// The video plays, the user talks over it for ten seconds, pauses, talks
/// again. The voice has to survive, and once they pause the video has to go
/// again. The first half second of the pause is not judged: the gate holds
/// for 150 ms and releases over 200 ms after any speech on purpose, so as not
/// to clip the ends of words.
#[test]
fn talking_over_the_video_keeps_the_voice_and_drops_it_in_the_pauses() {
    let lead = 48_000 * 4;
    let pause = 48_000 * 5 / 2;
    let voice = scale_to(&local_speech(), -22.0);
    let mut speech = vec![0.0f32; lead];
    speech.extend_from_slice(&voice);
    let pause_start = speech.len();
    speech.extend(std::iter::repeat(0.0).take(pause));
    speech.extend_from_slice(&voice);
    let media = fit(&media_dialogue(), speech.len());
    let bleed = speaker_bleed(&media, -34.0);
    let capture = mix(&mix(&speech, &bleed), &floor_noise(speech.len()));
    let feeds = Feeds { reference: Some(&media), ..Feeds::default() };
    let (_, r) = measure_from("user talking over the video, reference", shipping_defaults(), &capture, feeds, 0);

    let loss = voice_loss_db(&speech, &capture, &r.out, lead / FRAME_SIZE);
    let judged: Vec<usize> = ((pause_start + 48_000 / 2) / FRAME_SIZE..(pause_start + pause) / FRAME_SIZE).collect();
    let pause_atten = rms_over(&capture, &judged) - rms_over(&r.out, &judged);
    println!("  voice lost {loss:.1} dB, video in the pause down {pause_atten:.1} dB");
    assert!(loss < 3.0, "the user lost {loss:.1} dB");
    assert!(pause_atten > 25.0, "the video in the pause only came down {pause_atten:.1} dB");
}

/// Talking without a break over music for a long time must not teach the
/// detector that the user's voice is bleed.
#[test]
fn talking_non_stop_over_music_does_not_teach_it_to_cut_the_user() {
    let n = 48_000 * 25;
    let media = scale_to(&music(n), -20.0);
    let bleed = speaker_bleed(&media, -34.0);
    // the user starts at 6 s and does not stop
    let voice = scale_to(&local_speech(), -22.0);
    let mut speech = vec![0.0f32; n];
    let start = 48_000 * 6;
    for i in start..n {
        speech[i] = voice[(i - start) % voice.len()];
    }
    let capture = mix(&mix(&speech, &bleed), &floor_noise(n));
    let feeds = Feeds { reference: Some(&media), ..Feeds::default() };
    let (_, r) = measure_from("19 s of talking over music, reference", shipping_defaults(), &capture, feeds, 0);
    let loss = voice_loss_db(&speech, &capture, &r.out, 1700);
    println!("  voice lost {loss:.1} dB over the last 8 s");
    assert!(loss < 3.0, "the user lost {loss:.1} dB after talking for 11 s");
}

/// Someone with a headset: the system mix plays, none of it reaches the
/// microphone. Nothing may change for them.
#[test]
fn a_headset_is_left_alone() {
    let speech = scale_to(&local_speech(), -22.0);
    let media = fit(&media_dialogue(), speech.len());
    let capture = mix(&speech, &floor_noise(speech.len()));
    let feeds = Feeds { reference: Some(&media), ..Feeds::default() };
    let (m, r) = measure_from("headset user talking, reference playing", shipping_defaults(), &capture, feeds, 0);
    let loss = voice_loss_db(&speech, &capture, &r.out, 0);
    assert!(loss < 1.0, "the user lost {loss:.1} dB");
    assert!(m.bleed < 0.05, "bleed reported {:.0}% of the time", m.bleed * 100.0);
}

/// Turning the speakers up is a new coupling; it has to be picked up within
/// a few seconds.
#[test]
fn turning_the_speakers_up_is_followed() {
    let half = 48_000 * 8;
    let media = fit(&media_dialogue(), half * 2);
    let quiet = speaker_bleed(&media, -40.0);
    let loud = speaker_bleed(&media, -26.0);
    let mut bleed = quiet[..half].to_vec();
    bleed.extend_from_slice(&loud[half..]);
    let capture = mix(&bleed, &floor_noise(bleed.len()));
    let feeds = Feeds { reference: Some(&media), ..Feeds::default() };
    // judge the last 4 s: the change happened 4 s before that
    let (m, _) = measure_from("speakers turned up 14 dB, reference", shipping_defaults(), &capture, feeds, 1200);
    assert!(m.attenuation_db() > 20.0, "only {:.1} dB after the change", m.attenuation_db());
}

/// A friend is streaming, their audio comes out of the speakers and back
/// into the microphone while the user says nothing. WebRTC's AEC3 removes
/// most of this in the app before we see it; this is our own contribution,
/// against the playout reference.
#[test]
fn a_remote_stream_bleeding_back_is_removed() {
    let far = scale_to(&far_end_voice(), -20.0);
    let bleed = speaker_bleed(&far, -30.0);
    let capture = mix(&bleed, &floor_noise(bleed.len()));
    let feeds = Feeds { render: Some(&far), ..Feeds::default() };
    let (m, _) = measure_from("remote stream at -30 dBFS, playout", shipping_defaults(), &capture, feeds, warmup_frames());
    assert!(m.attenuation_db() > 25.0, "only {:.1} dB of attenuation", m.attenuation_db());
    assert!(m.peak_block_db < -50.0, "loudest 10 ms is {:.1} dBFS", m.peak_block_db);
}

// ------------------------------------------------- without one (the browser)

/// Records what happens without a reference, so it cannot drift unnoticed:
/// the VAD gate passes a video playing next to the microphone almost
/// untouched. If this starts failing because the attenuation went up,
/// something new is doing the job and the docs need updating.
#[test]
fn without_a_reference_loudspeaker_bleed_leaks() {
    for (name, clean) in [("video dialogue", media_dialogue()), ("music", music(48_000 * 8))] {
        let bleed = speaker_bleed(&clean, -34.0);
        let capture = mix(&bleed, &floor_noise(bleed.len()));
        let m = measure(&format!("{name} at -34 dBFS, no reference"), shipping_defaults(), &capture, Feeds::default());
        assert!(m.attenuation_db() < 10.0, "{name}: {:.1} dB, better than recorded", m.attenuation_db());
        assert!(m.gate_open > 0.5, "{name}: gate open {:.0}%, better than recorded", m.gate_open * 100.0);
    }
}

/// The tool there is without a reference: raise the input sensitivity
/// threshold, which now applies in automatic mode too. It has to clear the
/// *peaks* of the bleed, not its average: at -28 dBFS, 6 dB above this
/// fixture's average, the loudest 16 % of frames still open the gate and the
/// run only comes out 4 dB down. Between the bleed's peak blocks (-25 dBFS
/// here) and the user's (-13 dBFS) is what the meter and its threshold
/// marker are for.
#[test]
fn a_raised_threshold_gates_the_bleed_in_either_mode() {
    for (mode, name) in [(2u8, "automatic"), (1u8, "manual")] {
        let params = Params { gate_mode: mode, gate_threshold_db: -20.0, ..shipping_defaults() };

        let bleed = speaker_bleed(&media_dialogue(), -34.0);
        let capture = mix(&bleed, &floor_noise(bleed.len()));
        let m = measure(&format!("dialogue, {name}, threshold -20 dB"), params, &capture, Feeds::default());
        assert!(m.attenuation_db() > 20.0, "{name}: only {:.1} dB", m.attenuation_db());
        assert!(m.gate_open < 0.1, "{name}: gate open {:.0}% of the time", m.gate_open * 100.0);

        let speech = scale_to(&local_speech(), -22.0);
        let capture = mix(&speech, &floor_noise(speech.len()));
        let m = measure(&format!("user talking, {name}, threshold -20 dB"), params, &capture, Feeds::default());
        assert!(m.attenuation_db() < 6.0, "{name}: the user lost {:.1} dB", m.attenuation_db());
        assert!(m.gate_open > 0.3, "{name}: gate open only {:.0}%", m.gate_open * 100.0);
    }
}
