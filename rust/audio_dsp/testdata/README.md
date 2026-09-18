# audio_dsp test fixtures

| File | What it stands for | Used by |
|------|--------------------|---------|
| `speech_48k.wav` | synthesised speech, 48 kHz | `src/lib.rs` unit tests |
| `local_speech_16k.wav` | the user talking into their microphone | `tests/speaker_bleed.rs` |
| `media_dialogue_16k.wav` | dialogue from a video the user is watching | `tests/speaker_bleed.rs` |
| `far_end_voice_16k.wav` | another participant's voice on playout | `tests/speaker_bleed.rs` |

The three 16 kHz files are cuts of the **CMU_ARCTIC** databases: `bdl` (US
male), `slt` and `clb` (US female). Three different voices so that leakage in
a test is attributable to one source. They are stored at the rate they were
recorded at — the recordings hold nothing above 8 kHz, and storing them at
48 kHz would only triple the size of the repository. The tests upsample with
the crate's own resampler, which is what the app does with a 16 kHz WebRTC
pipeline anyway.

Modifications: leading and trailing silence cut, three utterances
concatenated with a fixed gap, normalised to -20 dBFS RMS. Nothing else; the
loudspeaker and room simulation lives in `tests/common/mod.rs` so the tests
can pick the bleed level.

Music in the tests is synthesised in `tests/common/mod.rs`, not a fixture.

## Rebuilding

```sh
sh testdata/fetch_sources.sh                        # into testdata/sources/, gitignored
cargo run -p audio_dsp --example make_fixtures
```

## Licence

> Carnegie Mellon University, Copyright (c) 2003, All Rights Reserved.
>
> This voice is free for use for any purpose (commercial or otherwise)
> subject to the pretty light restrictions detailed below. Permission to use,
> copy, modify, and licence this software and its documentation for any
> purpose, is hereby granted without fee, subject to the following
> conditions: 1. The code must retain the above copyright notice, this list
> of conditions and the following disclaimer. 2. Any modifications must be
> clearly marked as such. 3. Original authors' names are not deleted.
>
> THE AUTHORS OF THIS WORK DISCLAIM ALL WARRANTIES WITH REGARD TO THIS
> SOFTWARE, INCLUDING ALL IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS,
> IN NO EVENT SHALL THE AUTHORS BE LIABLE FOR ANY SPECIAL, INDIRECT OR
> CONSEQUENTIAL DAMAGES OR ANY DAMAGES WHATSOEVER RESULTING FROM LOSS OF USE,
> DATA OR PROFITS, WHETHER IN AN ACTION OF CONTRACT, NEGLIGENCE OR OTHER
> TORTIOUS ACTION, ARISING OUT OF OR IN CONNECTION WITH THE USE OR
> PERFORMANCE OF THIS SOFTWARE.

See <http://festvox.org/cmu_arctic/> for the full databases.
