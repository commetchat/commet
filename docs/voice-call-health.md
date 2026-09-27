# Voice call health

Report (2026-09-26, after PR #157): after some time in a voice room the
user can no longer be heard, and only leaving and rejoining the room
brings their voice back. PR #157 had fixed one way to get there (an unmute
recording from the wrong device); the report says it still happens.

Nobody hears their own microphone in a call, so every failure below looked
the same from the inside: the call on screen, the user talking, nothing
arriving. A rejoin cured all of them because it rebuilds everything: a new
capture, a new DSP, a new publication, new subscriptions, new keys. Nothing
short of that ever retried. This document lists what went wrong, what now
watches for it, how it repairs, and what guards it.

## What went wrong

| # | Where | What happened | Found by |
|---|-------|---------------|----------|
| 1 | Windows audio device module (libwebrtc's legacy `AudioDeviceWindowsCore`, the one webrtc-sdk's wrapper creates) | Any WASAPI error mid-stream (a Bluetooth headset switching profiles, a USB hiccup, sleep and resume, a driver or audio service restart, another program taking the device) or half a second without a capture event ends the capture thread for good. `_recording` stays true, so `Recording()` says it records and nothing starts it again. Linux PulseAudio does the same when its recording stream goes away. | Reading the m150 source; reproduced on Linux by killing the app's recording stream |
| 2 | The noise suppression watchdog (`MicrophoneNoiseSuppression`) | The only thing that ever restarted a capture mid-call, by accident: it took a dead capture for a dead DSP, restarted the microphone once, and gave up on the DSP for the rest of the call. A second death was never looked at, and with noise suppression off there was no watchdog at all. | Code reading, fake-clock repro |
| 3 | LiveKit `restartTrack` (vendored) | Stopped the old capture before opening the new one and set the new options first. A restart that could not open the device (gone for a moment, held by another program) left the sender on a stopped track, with options saying the restart had happened, so nothing tried again. | `microphone_restart_failure_test.dart`, red before the fix |
| 4 | `audio_dsp` (Rust) | One NaN or infinity in the input spread into every recursive state (DeepFilterNet, both RNNoise instances, the filters, the gate) for good: every sample out NaN, which WebRTC sends as digital silence, the gate never open again. In debug builds RNNoise's FFT aborts on NaN; in release it is undefined behaviour. A huge finite sample did the same for tens of seconds. | Audit, `tests/non_finite.rs`, red before the fix |
| 5 | Web: LiveKit watched only the first capture for its end | A capture that ended after any restart (unplugged, permission revoked) went unnoticed; the first one made LiveKit unpublish the microphone, which made the user look muted with nothing to bring it back. | Headless Chrome |
| 6 | Web: the DSP worker | A wasm trap on every block (about a hundred errors a second in the log) or a hung worker made the worklet play silence for good. | `web_health_loop.mjs`, red before the fix |
| 7 | Web: the DSP's AudioContext | Nothing resumed a context the browser suspended or interrupted; the processed track then carried nothing. | `web_health_loop.mjs`, red before the fix |
| 8 | Remote audio | Subscriptions are made by the session itself (auto-subscribe is off for opt-in screen shares), from LiveKit's events. A subscription that went missing or stopped delivering was never asked for again, so everyone stopped hearing one person until that person rejoined. Remote video had a stall detector; remote audio had none. | Code reading |
| 9 | Encrypted rooms (experimental): key distribution | A new key on every change to any membership (a mute, going away after 15 minutes idle, a screen share, the expiry refresh), sent once as a fire-and-forget to-device message, used five seconds later regardless. One send that failed or skipped a device (device keys not downloaded yet) meant silence from that sender until the next membership change. Incoming keys were not checked for room, call, encryption or sender device. | Audit against matrix-js-sdk's `RTCEncryptionManager` |
| 10 | The mute button | `isMicrophoneMuted` read LiveKit's `isMuted`, which is the first audio publication's: with the DJ booth's music or screen audio published before the microphone, the button showed the music's state and the toggle could never unmute. | Audit, `livekit_session_voice_health_test.dart` |
| 11 | LiveKit's lookup by source (vendored) | With no microphone published, `getTrackPublicationBySource(microphone)` fell back to a publication without a source, which is the DJ booth's music: unmuting (or publishing a microphone again) unmuted the music and published nothing. | Review of this change |
| 12 | LiveKit `Track.disable()` | Does nothing while the track is stopped, which a restart makes it for a moment: a mute that landed then was lost, and the new capture went out enabled while the button said muted. | Review of this change, `microphone_restart_failure_test.dart` |

## What watches now

Once a second a voice room's session (`MatrixLivekitVoipSession._watchVoice`)
runs, in this order:

1. **Our microphone** — `MicrophoneHealthMonitor`
   (`client/components/voip/microphone_health.dart`), wired to the room by
   `LivekitMicrophoneHealth` (`voip_room/livekit_microphone.dart`). While
   the user wants to be heard (not muted, not deafened; the session keeps
   that intent itself, so a repair never undoes a mute that is still on its
   way through LiveKit) it reads:
   - the sender's `media-source` `totalSamplesDuration`, which grows by one
     second a second while the capture hands over audio, speech or silence,
     and stops when the capture does (native: the capture thread; web: the
     audio context);
   - whether the capture track ended (on the web, the raw capture behind
     the DSP's processed track);
   - whether the web DSP's frame counter moves;
   - `outbound-rtp` `packetsSent` while the DSP hears the user speak (with
     DTX, a quiet microphone sends next to nothing, so only then);
   - whether a microphone that was published is gone.

   Nothing is judged for 3 s after the microphone starts sending or after a
   repair. The faults and the repairs, cheapest first:

   | Fault | Repair ladder |
   |-------|---------------|
   | capture stalled (< 0.25 s of audio a second over 2 s), capture ended, DSP stalled, nothing sent while speaking | desktop: **reopen** (the track off and on: WebRTC stops recording and starts it again, which brings back a dead capture thread; the COMMET `ReselectRecordingDevice` picks the microphone again by id), then **restart** (`restartTrack`, a new capture), then **republish** (a new publication on a new sender). Web: restart, then republish. |
   | microphone no longer published | republish |

   The last step repeats every 10, 20, 40 and then 60 s for as long as the
   fault lasts. Once every step was tried the user is told ("Your
   microphone stopped reaching the call…"), and told again when it is
   back. A call that never had a microphone (no device, permission denied)
   is not given one behind the user's back.

2. **Noise suppression** — `MicrophoneNoiseSuppression.update`, as before,
   except that its DSP watchdog asks the microphone watch first
   (`captureFlowing`): a capture that went quiet is repaired as such, not
   blamed on the DSP.

3. **Everyone we hear** — `RemoteAudioWatch`
   (`client/components/voip/remote_audio_watch.dart`). Every remote audio
   track we want (all microphones; screen audio being watched; music) that
   has not arrived after 6 s, or a microphone that delivers no packet for
   3 s while the server lists its owner as speaking, is subscribed to again
   (`RemoteTrackPublication.resubscribe`), every 5, 10, 20, 40, then 60 s
   while it does not help.

4. **Keys we cannot decrypt** (encrypted rooms) — a remote track in
   `kMissingKey` or `kDecryptionFailed` makes us ask its owner for its key
   (`io.roscord.call.encryption_keys_request`, at most every 10 s per
   participant, until it decrypts).

Nothing is judged or repaired while the room is not connected (LiveKit
unpublishes everything when it gives up, and nothing flows while it
reconnects) or once the call is being left. A microphone gone for less than
3 s is LiveKit republishing it after a reconnect, not a fault. Every step
is bounded, so one platform call that hangs cannot stop the checks: reads
5 s, statistics 2 s, the noise suppression update 5 s.

Capture changes (noise suppression restarts, repairs) go through one queue
per call (`CaptureChanges`), which waits 15 s at most for the change before
it; mutes never wait on it. While a microphone that went missing is being
published again, the mute button shows what the user chose (not muted),
not "muted".

## Fixes underneath

- **Make before break** (`third_party/livekit-client-sdk-flutter`,
  `restartTrack`): on desktop and mobile the new capture is opened before
  the old one stops, so a failed restart keeps the old capture going; the
  options only change once the new capture exists, so a failed restart is
  tried again. The browser keeps the old order (close, then open): a second
  capture of a device that is open gets the open one's processing, so the
  browser's noise suppressor could not be switched (the web noise loop's
  restart scenario caught it). There a failed restart leaves the track
  stopped, which the watch repairs, and the DSP processor is kept for the
  next attempt.
- **Ended captures** (vendored LiveKit): a capture made by a restart is
  watched for its end too, and a microphone whose capture ended stays
  published for the watch to repair (LiveKit's JS SDK restarts it too).
- **The DSP takes no NaN** (`rust/audio_dsp/src/lib.rs`): a sample that is
  not a finite number is taken as silence and samples are clipped at
  `INPUT_LIMIT` (4× full scale) before anything with state sees them; the
  render and reference meters too. Parameters that are not numbers fall back
  to the defaults. If a stage still produces NaN, the block goes out silent
  and every stage is rebuilt (`Dsp::recover`: RNNoise, the filters, the gate,
  the bleed detectors, the model built again the way it first was); the
  report's `REPORT_FLAG_RECOVERED` says so and the app logs it once. RNNoise
  is never handed NaN.
- **Web DSP glue** (`commet/web/`): the worker returns a block untouched when
  the DSP throws and reports it at most every 5 s; the worklet passes the
  microphone through once no block came back for 200 ms (the user is heard
  unprocessed rather than not at all, until the watch builds a new graph);
  the audio context is resumed when the browser suspends or interrupts it;
  `create()` refuses a capture that already ended.
- **Key distribution** (`voip_room/call_key_distributor.dart`, a pure state
  machine; the Matrix side in `matrix_livekit_encryption_key_provider.dart`,
  messages in `call_key_messages.dart`):
  - a new key only when someone leaves; someone joining (or joining again,
    a new `created_ts`) gets the key in use, and our own membership
    rewrites change nothing;
  - every member is sent every key it needs until a send to it works (1 s
    backoff doubling to 60 s), and everyone the key in use every 60 s and
    whenever they ask for it;
  - a new key is used 2 s after everyone got it, or 10 s after it was made
    at the latest (a member we cannot reach must not keep the others on a
    key someone who left still has); a key made for a leave that is
    superseded by another leave is never used;
  - the first key index is random, so a rejoin does not reuse the indices
    receivers still hold;
  - device keys that are not known yet are asked for, and the member is
    tried again;
  - incoming keys are taken only encrypted, for this room's call, from the
    device that encrypted them (its curve25519 key), in the order they were
    sent; a key from someone whose membership has not arrived yet is held
    for 60 s.
- **Mute state** reads the microphone's own publication.
- **Republishing** creates the capture and publishes it directly
  (`publishAudioTrack`), and stops it if the publish fails; the vendored
  `setSourceEnabled` stops a microphone whose publish failed too, and the
  local lookup by source has no fallback to a publication without one.
- **A mute during a restart holds**: the vendored `restartTrack` keeps the
  new capture off (or the processed track, on the web) when the track was
  muted meanwhile, and the repair checks again once it is done.
- **Keys count as sent** only for devices we hold an olm session with and
  that are not blocked; the SDK drops the others without a word.
- **The DSP stops rebuilding**: after 3 rebuilds it gives DeepFilterNet up,
  after 10 noise suppression (the gate still runs on levels), so a stage that
  keeps producing NaN cannot have everything rebuilt on every block.

## What the tests guard

| Invariant | Guarded by | In CI |
|-----------|------------|-------|
| A capture that stops handing over audio, a capture that ended, a DSP that stopped and a sender that sends nothing while the user speaks are repaired in order, spaced out, never while muted, never given up on; the user is told once | `unit_test/voice_health/microphone_health_test.dart` | ci `test` |
| On a real LiveKit microphone track: reopen turns it off and on, a mute during a reopen or a restart wins, restart gives the sender a new capture, republish publishes a new microphone (next to the DJ booth's music too) and does not unmute someone who muted meanwhile, a capture opened for a publish that failed is closed, a vanished microphone is published again after 3 s, one never published is not, nothing happens while disconnected | `livekit_microphone_health_test.dart` | ci `test` |
| One capture change at a time; a failed one does not stop the next; one that never finishes releases the queue after its limit | `capture_changes_test.dart` | ci `test` |
| A restart that cannot open the device keeps the old capture and its options, and is retried; a restarted capture is watched for its end | `microphone_restart_failure_test.dart` | ci `test` |
| A dead capture is not blamed on the DSP | `microphone_noise_suppression_test.dart` | ci `test` |
| The session wires it: a dead capture is reopened without a rejoin, a mute or deafen is respected, nothing is repaired while reconnecting or leaving, a remote microphone that never arrives is asked for again, the mute button follows the microphone (and shows not muted while it is being published again) | `livekit_session_voice_health_test.dart` | ci `test` |
| A remote track that never arrives, or a microphone silent while its owner speaks, is resubscribed; quiet, muted or unwanted ones are not | `remote_audio_watch_test.dart` | ci `test` |
| Keys: no new key on rewrites, one on a leave; a failed send is retried and its key not used; a key nobody could get is used after the cap and still sent; unknown device keys, lost messages (the announcement) and requests are healed; indices go round the ring from a random start; nothing after dispose | `call_key_distributor_test.dart` | ci `test` |
| Incoming keys: only this room's call, only encrypted, only from the device that claims them, in order; held until the membership arrives; an older roscord's keys are still taken | `call_key_messages_test.dart` | ci `test` |
| One NaN, infinity or huge sample (and a whole NaN block) leaves the voice as it was a second later; state that went bad is rebuilt; state that keeps going bad gives suppression up, not the voice; NaN parameters do not stick; RNNoise taking over keeps the voice | `rust/audio_dsp/tests/non_finite.rs` | ci `test` |
| Inside the real WebRTC (Linux): the app's recording stream killed mid-capture stays dead on its own (WebRTC does not notice), and the reopen repair brings the voice back within 3 dB | `native_noise_loop.sh` ("a microphone whose recording died is heard again"; pacmd on PulseAudio, pw-cli on PipeWire) | integration-test |
| In Chrome: a worker that traps on every block or hangs keeps the microphone going out (it was -120 dB) and stops the frame counter; a suspended context is resumed; an ended capture is refused | `web_health_loop.mjs` | ci `voice-dsp` |
| The vendored changes and the session's calls are still there | `check_contracts.py` | ci `voice-dsp` |

Measured on 2026-09-26: the native scenario gives "before: 1.00 s/s at
-6.1 dB; recording killed: 0.00 s/s; after 1 repair(s) in 6.1 s: 0.99 s/s
at -9.8 dB" on PipeWire and "0.98 s/s at -8.4 dB; killed 0.00 s/s; after 1
repair in 6.1 s: 1.02 s/s at -7.5 dB" on a CI-like real PulseAudio.

## If it happens again

The app log says what the watch saw and did:

- `Voice: microphone fault captureStalled, repairing it (reopen, attempt 1)`
  then `Voice: the microphone gets through again`: the capture died and came
  back. Frequent ones point at the audio device (Bluetooth profile switches,
  a driver). `captureEnded`, `processingStalled` (web DSP), `sendStalled`
  (captured but not sent) and `missing` name the other faults.
- `Voice: every microphone repair was tried and it still does not get
  through`: none of the repairs helped; the log above it has the errors of
  each attempt.
- `Voice DSP: a sample that was not a number reached it, and it rebuilt its
  state`: the DSP's guard fired.
- `Voice: remote audio TR_… silent, subscribing to it again`: we stopped
  receiving someone.
- `Voice keys: …`: encrypted rooms. `cannot decrypt X, asking it for its
  key`, `key N did not reach X; trying again`, `using key N before X got
  it`.

With none of these lines and the user still not heard, ask them to mute and
unmute (it restarts WebRTC's recording on desktop) and to turn off "Filter
out sound from your speakers" (see below).

## Known limits

- **The user's own voice in the system mix.** With something playing the
  microphone back within about 30 ms (Windows "Listen to this device", OBS
  monitoring, Voicemeeter, NVIDIA Broadcast), the loudspeaker bleed detector
  takes the user's voice for bleed and holds the gate shut (measured -40 dB,
  95 % of the time). It lasts as long as the monitoring does. Turning off
  "Filter out sound from your speakers" cures it. Telling the two apart
  needs the bleed detector to look at which side leads (the microphone leads
  its own monitoring; bleed follows the reference); not done.
- **The DeepFilterNet cost guard is permanent.** One long stall (sleep, a
  busy machine) can hand noise suppression to RNNoise for the rest of the
  DSP's life. The voice goes through (`tests/non_finite.rs`); knocks and
  typing come through more.
- **Linux PulseAudio restarting.** WebRTC's Pulse module only connects its
  context at startup: after the sound server restarts no repair can record
  again, and only restarting the app helps.
- **Windows is not exercised end to end.** The native scenario runs on
  Linux's PulseAudio module, which fails the same way the Windows one does
  (the capture ends, `Recording()` stays true) and is repaired the same way;
  the Windows module itself is only compiled in CI.
