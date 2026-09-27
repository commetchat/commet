//! A capture that hands the DSP one sample that is not a number.
//!
//! Every stage of the DSP keeps state from block to block: DeepFilterNet's
//! normalisation and recurrent layers, both RNNoise instances, the
//! high-pass, the band meters, the gate's gain. One NaN or infinity in the
//! input used to spread into all of it for good: from then on every sample
//! out was NaN, which WebRTC turns into digital silence, and the gate never
//! opened again. The call went on, the frame counter kept counting, and the
//! user could not be heard until they left and rejoined. A huge finite
//! sample did the same for tens of seconds.
//!
//! The DSP now takes what is not a finite sample as silence, keeps samples
//! within a sane range, and rebuilds whatever state went bad anyway.

mod common;

use audio_dsp::{Dsp, ModelLoad, Params, FRAME_SIZE};
use common::*;

const SECONDS: usize = RATE;

/// The user talking in a quiet room, `n` samples.
fn talking(n: usize) -> Vec<f32> {
    mix(&scale_to(&fit(&local_speech(), n), -24.0), &room_tone(n, -50.0, 7))
}

/// How the DSP treats speech over a run: output level over input level, in
/// dB, and how much of the time the gate is open.
fn treatment(input: &[f32], r: &Run) -> (f32, f32) {
    (rms_dbfs(&r.out) - rms_dbfs(&input[..r.out.len()]), r.gate_open_fraction())
}

fn all_finite(x: &[f32]) -> bool {
    x.iter().all(|s| s.is_finite())
}

/// Speech, one block with `bad` in it, then speech again: how the voice
/// comes out before, and in the last `settle`-less part after.
fn around_a_bad_sample(bad: f32) -> ((f32, f32), (f32, f32), Run) {
    let mut dsp = Dsp::with_model(Params::default(), ModelLoad::Now);
    let before_in = talking(6 * SECONDS);
    let before = run(&mut dsp, &before_in, Feeds::default());

    let mut block = talking(FRAME_SIZE);
    block[FRAME_SIZE / 2] = bad;
    dsp.process_block(&mut block);
    assert!(all_finite(&block), "{bad}: the block carrying it came out not finite");

    // A second after it, the voice has to be back as it was.
    let after_in = talking(11 * SECONDS);
    let after = run(&mut dsp, &after_in, Feeds::default());
    let tail = SECONDS;
    let tail_run = Run {
        out: after.out[tail..].to_vec(),
        frames: after.frames[tail / FRAME_SIZE..].to_vec(),
    };
    (
        treatment(&before_in[SECONDS..], &Run {
            out: before.out[SECONDS..].to_vec(),
            frames: before.frames[SECONDS / FRAME_SIZE..].to_vec(),
        }),
        treatment(&after_in[tail..], &tail_run),
        after,
    )
}

fn assert_voice_back(bad: f32) {
    let ((gain_before, open_before), (gain_after, open_after), after) = around_a_bad_sample(bad);
    println!(
        "{bad:>14e}: before {gain_before:5.1} dB, gate {:3.0}%; after {gain_after:5.1} dB, gate {:3.0}%",
        open_before * 100.0,
        open_after * 100.0
    );
    assert!(all_finite(&after.out), "{bad}: the DSP sent out samples that are not numbers");
    assert!(
        after.out.iter().all(|s| s.abs() <= 4.0 * 32768.0),
        "{bad}: the DSP sent out samples far beyond full scale"
    );
    assert!(
        gain_after >= gain_before - 1.0,
        "{bad}: the voice came back {:.1} dB quieter ({gain_before:.1} dB before, {gain_after:.1} dB after)",
        gain_before - gain_after
    );
    assert!(
        open_after >= open_before - 0.05,
        "{bad}: the gate opened {:.0}% of the time after, {:.0}% before",
        open_after * 100.0,
        open_before * 100.0
    );
}

#[test]
fn a_nan_sample_does_not_silence_the_voice() {
    assert_voice_back(f32::NAN);
}

#[test]
fn an_infinite_sample_does_not_silence_the_voice() {
    assert_voice_back(f32::INFINITY);
    assert_voice_back(f32::NEG_INFINITY);
}

#[test]
fn a_huge_sample_does_not_silence_the_voice() {
    assert_voice_back(f32::MAX);
    assert_voice_back(-f32::MAX);
    assert_voice_back(1e20);
}

#[test]
fn a_whole_block_of_nan_does_not_silence_the_voice() {
    let mut dsp = Dsp::with_model(Params::default(), ModelLoad::Now);
    let warm = talking(3 * SECONDS);
    run(&mut dsp, &warm, Feeds::default());
    for _ in 0..10 {
        let mut block = [f32::NAN; FRAME_SIZE];
        dsp.process_block(&mut block);
        assert!(all_finite(&block));
    }
    let input = talking(6 * SECONDS);
    let r = run(&mut dsp, &input, Feeds::default());
    let (gain, open) = treatment(&input[SECONDS..], &Run {
        out: r.out[SECONDS..].to_vec(),
        frames: r.frames[SECONDS / FRAME_SIZE..].to_vec(),
    });
    assert!(all_finite(&r.out));
    assert!(gain > -3.0, "the voice came out {gain:.1} dB down");
    assert!(open > 0.8, "the gate opened {:.0}% of the time", open * 100.0);
}

/// A NaN that got into the state some other way than the input (a bug in
/// a stage, something the input check does not foresee) is found in what
/// comes out, and the state is rebuilt.
#[test]
fn state_that_went_bad_is_rebuilt() {
    let mut dsp = Dsp::with_model(Params::default(), ModelLoad::Now);
    let warm = talking(3 * SECONDS);
    let before = run(&mut dsp, &warm, Feeds::default());
    let (gain_before, _) = treatment(&warm[SECONDS..], &Run {
        out: before.out[SECONDS..].to_vec(),
        frames: before.frames[SECONDS / FRAME_SIZE..].to_vec(),
    });

    dsp.debug_poison_state();

    let input = talking(8 * SECONDS);
    let r = run(&mut dsp, &input, Feeds::default());
    assert!(all_finite(&r.out), "state that went bad kept sending NaN");
    let tail = 2 * SECONDS;
    let (gain, open) = treatment(&input[tail..], &Run {
        out: r.out[tail..].to_vec(),
        frames: r.frames[tail / FRAME_SIZE..].to_vec(),
    });
    println!("rebuilt: {gain:.1} dB (before {gain_before:.1}), gate {:.0}%", open * 100.0);
    assert!(gain >= gain_before - 1.0, "the voice came back {gain:.1} dB, {gain_before:.1} before");
    assert!(open > 0.8);
    assert!(dsp.recoveries() >= 1, "the rebuild is counted");
}

/// Parameters are Dart's and the browser worker's to send: one that is not
/// a number must not stick in the gate's gain after it is corrected.
#[test]
fn a_parameter_that_is_not_a_number_does_not_stick() {
    let mut dsp = Dsp::with_model(Params::default(), ModelLoad::Now);
    let input = talking(3 * SECONDS);
    run(&mut dsp, &input, Feeds::default());

    let mut bad = Params::default();
    bad.gate_floor_db = f32::NAN;
    bad.duck_depth_db = f32::NAN;
    bad.gate_threshold_db = f32::NAN;
    bad.input_scale = f32::NAN;
    dsp.set_params(&bad);
    let r = run(&mut dsp, &talking(SECONDS), Feeds::default());
    assert!(all_finite(&r.out), "a NaN parameter made the output NaN");

    dsp.set_params(&Params::default());
    let input = talking(4 * SECONDS);
    let r = run(&mut dsp, &input, Feeds::default());
    assert!(all_finite(&r.out));
    let (gain, open) = treatment(&input[SECONDS..], &Run {
        out: r.out[SECONDS..].to_vec(),
        frames: r.frames[SECONDS / FRAME_SIZE..].to_vec(),
    });
    assert!(gain > -3.0, "the voice came out {gain:.1} dB down");
    assert!(open > 0.8);
    assert!(dsp.report().gain_db.is_finite());
}

/// The cost guard hands suppression to RNNoise mid-call on a machine that
/// is too slow for DeepFilterNet (or after one long stall): the voice has
/// to keep going through.
#[test]
fn switching_to_rnnoise_mid_speech_keeps_the_voice() {
    let mut dsp = Dsp::with_model(Params::default(), ModelLoad::Now);
    let first = talking(4 * SECONDS);
    let before = run(&mut dsp, &first, Feeds::default());
    let (gain_before, _) = treatment(&first[SECONDS..], &Run {
        out: before.out[SECONDS..].to_vec(),
        frames: before.frames[SECONDS / FRAME_SIZE..].to_vec(),
    });
    dsp.disable_deep_filter();
    let input = talking(6 * SECONDS);
    let r = run(&mut dsp, &input, Feeds::default());
    let (gain, open) = treatment(&input[SECONDS..], &Run {
        out: r.out[SECONDS..].to_vec(),
        frames: r.frames[SECONDS / FRAME_SIZE..].to_vec(),
    });
    println!("RNNoise took over: {gain:.1} dB (DeepFilterNet {gain_before:.1}), gate {:.0}%", open * 100.0);
    assert!(gain >= gain_before - 1.0);
    assert!(open > 0.85);
}

/// A stage that keeps producing NaN however often it is rebuilt: the model
/// is given up on, then suppression, and the voice keeps going through the
/// gate instead of the DSP rebuilding everything on every block.
#[test]
fn state_that_keeps_going_bad_gives_up_suppression_not_the_voice() {
    let mut dsp = Dsp::with_model(Params::default(), ModelLoad::Now);
    run(&mut dsp, &talking(2 * SECONDS), Feeds::default());
    for _ in 0..12 {
        dsp.debug_poison_state();
        let r = run(&mut dsp, &talking(SECONDS / 10), Feeds::default());
        assert!(all_finite(&r.out));
    }
    assert!(dsp.recoveries() >= 10, "{} rebuilds", dsp.recoveries());
    assert!(!dsp.has_deep_filter(), "the model is still being rebuilt");
    let input = talking(4 * SECONDS);
    let r = run(&mut dsp, &input, Feeds::default());
    let recoveries = dsp.recoveries();
    let (gain, open) = treatment(&input[SECONDS..], &Run {
        out: r.out[SECONDS..].to_vec(),
        frames: r.frames[SECONDS / FRAME_SIZE..].to_vec(),
    });
    println!("suppression given up: {gain:.1} dB, gate {:.0}%", open * 100.0);
    assert!(all_finite(&r.out));
    assert!(gain > -3.0, "the voice came out {gain:.1} dB down");
    assert!(open > 0.6, "the gate opened {:.0}% of the time", open * 100.0);
    assert_eq!(dsp.recoveries(), recoveries, "healthy blocks rebuild nothing");
}
