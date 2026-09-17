# Issue #11: call grid shows you twice when sharing your screen with audio

Research note, 2026-09-16. All paths are relative to the repo root; line
numbers are from the working tree at commit `906de7c1`
(branch `t3code/solve-github-issue-eleven`). Nothing here changes code.

Issue: https://github.com/PondLabs/roscord/issues/11. Sharing a screen with
"do not share audio" unchecked adds a second avatar tile for the sharer
(both on the sharer's side and on every viewer's), and that tile's speaking
indicator lights up whenever the shared audio plays.

## 1. How the grid is built: one tile per `VoipStream`

`CallView` (`commet/lib/ui/organisms/call_view/call_view.dart`) subscribes to
`currentSession.onStateChanged` and calls `setState` on every event
(`call_view.dart:61-63`). While the call is connected it renders
`generateLayout()` inside a `Row` or `Column` depending on aspect ratio
(`call_view.dart:227-245`).

`generateLayout()` (`call_view.dart:267-334`):

- If `mainStream` is set, it gets a big `Flexible(flex: 100)` tile with a
  `VoipStreamView` keyed on `callView_mainStreamView_${streamId}`
  (`call_view.dart:269-301`).
- Everything else goes into a `BentoLayout` built from
  `widget.currentSession.streams.where((e) => e != mainStream).map(...)`,
  one `VoipStreamView` per stream, keyed `callView__${e.streamId}`
  (`call_view.dart:302-332`). `BentoLayout` is a plain list-of-children
  layout (`commet/lib/ui/layout/bento.dart:6-8`).
- The only type-aware logic here is the `fit`: `BoxFit.contain` for
  `VoipStreamType.screenshare`, `BoxFit.cover` otherwise
  (`call_view.dart:317-319`).

There is no grouping by member and no filtering. Whatever the session puts
in `streams` becomes a tile.

## 2. How a tile is drawn: `VoipStreamView`

`commet/lib/ui/organisms/call_view/voip_stream_view.dart`:

- `initState` resolves the member from `stream.streamUserId` and listens to
  `stream.onStreamChanged` and `session.onUpdateVolumeVisualizers`
  (`voip_stream_view.dart:43-53`).
- The speaking indicator is `stream.audiolevel > 0.5`, re-evaluated on each
  `onUpdateVolumeVisualizers` tick (`voip_stream_view.dart:61-64`).
- `buildDefault()` switches on `stream.type`
  (`voip_stream_view.dart:159-250`):
  - `VoipStreamType.audio` -> avatar tile with `SpeakingIndicator`, the
    mute/deafen badge, and the soundboard emoji overlay
    (`voip_stream_view.dart:162-241`).
  - `VoipStreamType.video` and `VoipStreamType.screenshare` ->
    `stream.buildVideoRenderer(fit, key)` or a spinner
    (`voip_stream_view.dart:243-248`).
- The fullscreen button appears only for `video`/`screenshare`
  (`voip_stream_view.dart:103-114`). Note the operator precedence: the
  condition is `(canFullscreen && type == video) || type == screenshare`,
  so `canFullscreen` does not suppress the button for screenshares.
- The right-click menu, for incoming streams only, shows the user row and a
  `StreamVolumeSlider` (`voip_stream_view.dart:120-157`). The slider calls
  `stream.setVolume(value)` with a 0..2.5 range and reads `stream.volume`
  (`voip_stream_view.dart:266-288`).

So an audio-type stream whose source is screen-share audio is drawn exactly
like a microphone stream: same avatar, same speaking indicator, same volume
slider. That is the second tile from the issue.

## 3. Where streams come from: `MatrixLivekitVoipSession`

`commet/lib/client/matrix/components/voip_room/matrix_livekit_voip_session.dart`.

`streams` is a plain growable `List<VoipStream>`
(`matrix_livekit_voip_session.dart:513-514`). It is filled from LiveKit
publications, one `MatrixLivekitVoipStream` per `TrackPublication`:

- `addInitialStreams()` walks `localParticipant.trackPublications` and every
  `remoteParticipants[*].trackPublications`, skipping only muted VIDEO
  publications (`:107-134`; the skip is at `:111` and `:122`). Audio
  publications of any source are added.
- `onTrackPublished` (remote) creates the stream, applies the saved user
  volume, copies the deafen flag and appends (`:192-201`).
- `onLocalTrackPublished` does the same for our own tracks (`:268-276`).
- `onTrackUnpublished` / `onLocalTrackUnpublished` remove by
  `publication.sid` (`:278-292`).
- `onTrackUnmutedEvent` re-adds a stream for a publication that had been
  removed on mute (`:171-190`); `onTrackMutedEvent` removes VIDEO
  publications on mute (`:151-169`).

The user id for remote streams is derived from the LiveKit identity by
keeping the first two `:`-separated parts (`:126-127`, `:193-194`,
`:269-270`), so the mic and screen-share-audio streams of one member share
the same `streamUserId`.

### `setScreenShare` publishes the screen audio as a normal audio track

`setScreenShare` (`:412-473`):

- Android goes through `setScreenShareEnabled(true)` with no audio (`:413-418`).
- Otherwise it builds `ScreenShareCaptureOptions(captureScreenAudio:
  source.captureAudio, ...)` (`:440-449`) and, when `captureAudio` is true,
  calls `lk.LocalVideoTrack.createScreenShareTracksWithAudio(captureOptions)`
  (`:451-453`).
- It then loops over the returned tracks: `LocalVideoTrack` ->
  `publishVideoTrack(...)` with screen-share encoding options (`:455-466`),
  `LocalAudioTrack` -> `publishAudioTrack(track)` (`:467-469`).

That second publish fires `LocalTrackPublishedEvent`, which
`onLocalTrackPublished` turns into a new `MatrixLivekitVoipStream`
(`:268-276`); on other clients the server-side publication fires
`TrackPublishedEvent` and `onTrackPublished` does the same (`:192-201`).

### `stopScreenshare` already knows about the audio source

`stopScreenshare` (`:494-511`) calls `setScreenShareEnabled(false)` and then
explicitly looks up `getTrackPublicationBySource(lk.TrackSource.screenShareAudio)`
and removes it (`:496-500`). This is the only place in the app that names
`TrackSource.screenShareAudio` today.

### Other code that iterates `streams`

- `onTrackStreamEvent`, `onTrackMutedEvent`, `onTrackUnmutedEvent` cast
  every element to `MatrixLivekitVoipStream` and match by sid
  (`:142-149`, `:159-164`, `:175-180`).
- `_setStreamsDeafened(identity, deafened)` sets `deafened` on every stream
  belonging to a LiveKit identity (`:245-254`). It is driven by the
  `chat.commet.voice_state.v1` data topic (`:216-243`) and by the local
  toggle (`:401-404`).
- `setDeafened` mutes the mic, then calls `_applyStreamVolume` on every
  `MatrixLivekitVoipStream` (`:386-409`).
- `_applyStreamVolume` only touches incoming `AudioTrack`s: volume is `0.0`
  when deafened, else `preferences.getVoipUserVolume(stream.userId)`
  (`:331-339`). Screen-share audio is an `AudioTrack`, so deafen correctly
  silences it today; any fix must keep that.
- `generalAudioLevel` is `streams.fold(0.0, max(..., stream.audiolevel))`
  (`:596-601`). It feeds the pulsing avatar in the sessions panel
  (`commet/lib/ui/molecules/call_sessions_panel.dart:82-83`), so shared
  audio also makes that indicator pulse.
- `isSharingScreen` is `localParticipant.isScreenShareEnabled()` (`:349-350`),
  which only checks the screen-share *video* source (see section 6).

## 4. `MatrixLivekitVoipStream`: why screen audio looks like a mic

`commet/lib/client/matrix/components/voip_room/matrix_livekit_voip_stream.dart`.

- Wraps a `TrackPublication` and a `userId` (`:12-13`, `:22`).
- Constructor: for any `AudioTrack` (no source check) it creates a 7-band
  `AudioVisualizer`, applies the saved per-user volume with
  `Helper.setVolume`, and listens for visualizer events (`:23-39`).
- `type` (`:132-142`): `AudioTrack` -> `audio`; else `publication.isScreenShare`
  -> `screenshare`; else `video`. Screen-share audio therefore reports
  `VoipStreamType.audio`.
- `audiolevel` (`:60-82`): 0 when muted; otherwise 1 if the visualizer saw a
  band above `_audioThreshold` (0.4) within the last 400 ms (`:46-53`,
  `:84-93`), or if `source == microphone && participant.isSpeaking`
  (`:76-79`). The visualizer path has no source check, so shared audio lights
  the indicator (the "looks like the person is talking" symptom).
  `_isLocalMic` (`:55-57`) is already source-aware: it only short-circuits
  through the DSP gate for `TrackSource.microphone`.
- `direction` (`:118-120`): outgoing for `LocalTrackPublication`.
- `streamId` is `publication.sid` (`:126`); `streamUserId` is the passed
  `userId` (`:129`).
- `isMuted` (`:145`) reads `publication.track?.muted`; `deafened` is a plain
  field set by the session (`:150-153`).
- `setVolume` writes `preferences.setVoipUserVolume(userId, volume)` and sets
  the track volume (`:163-168`); `volume` reads the same preference (`:171`).
  The preference key is `call_user_volume:<userId>`
  (`commet/lib/config/preferences.dart:237-243`), so a mic stream and a
  screen-share-audio stream from the same member share one volume setting.
  Sliding the volume on either tile changes the preference; the *other*
  stream's live `Helper.setVolume` is not updated until the next
  `_applyStreamVolume`.

## 5. The `VoipStream` interface and the legacy implementation

`commet/lib/client/components/voip/voip_stream.dart`:

- `enum VoipStreamType { audio, video, screenshare }` (`:3`).
- `enum VoipStreamDirection { incoming, outgoing }` (`:5`).
- `abstract class VoipStream` (`:7-37`) exposes `type`, `direction`,
  `buildVideoRenderer`, `onStreamChanged`, `streamUserId`, `label`,
  `streamId`, `stats`, `audiolevel`, `isMuted`, `isDeafened`, `aspectRatio`,
  `volume`, `setVolume`.

`VoipSession` (`commet/lib/client/components/voip/voip_session.dart:28-86`)
exposes `List<VoipStream> get streams` (`:57`) and `generalAudioLevel` (`:53`).

The legacy 1:1 path, `MatrixVoipStream`
(`commet/lib/client/matrix/components/voip/matrix_voip_stream.dart`), wraps a
matrix-dart-sdk `WrappedMediaStream`:

- `type` (`:49-59`): `SDPStreamMetadataPurpose.Screenshare` ->
  `screenshare`; else `videoMuted ? audio : video`.
- `audiolevel` comes from `getStats` audio levels (`:68-97`).
- `setVolume` applies to every audio track in the stream and saves the same
  per-user preference (`:163-176`).

`MatrixVoipSession.initStreams`/`shouldAddStream`
(`commet/lib/client/matrix/components/voip/matrix_voip_session.dart:285-320`)
only accept `Screenshare` and `Usermedia` purposes and skip video-muted
screenshares. In this path a screenshare is one `MediaStream` that can carry
both video and audio tracks, so it never produces a separate audio-only
stream. The legacy implementation is not affected by the bug; any interface
change must still compile for it (it is a plain `implements VoipStream`).

Test fakes also implement the interface with `noSuchMethod`
(`commet/unit_test/deafen_test.dart:90-121`,
`commet/unit_test/screen_share_audio_test.dart:238-262`), so adding a new
abstract member does not break them, but adding an enum value does affect
exhaustive `switch`es (`voip_stream_view.dart:161`).

## 6. LiveKit primary sources (vendored under `third_party/`)

`commet/pubspec.yaml:169-170` overrides `livekit_client` to
`../third_party/livekit-client-sdk-flutter`
(origin and ref in `third_party/README.md:6-9`).

- `enum TrackSource { unknown, camera, microphone, screenShareVideo,
  screenShareAudio }`
  (`third_party/livekit-client-sdk-flutter/lib/src/types/other.dart:90-96`).
  Protobuf mapping `SCREEN_SHARE_AUDIO <-> screenShareAudio` in
  `lib/src/extensions.dart:188-207`.
- `TrackPublication` has `final TrackType kind` and `final TrackSource
  source`, both taken from the server `TrackInfo`
  (`lib/src/publication/track_publication.dart:30-34`, `:73-75`). Remote
  publications therefore carry the source too, which is why viewers get the
  duplicate as well.
- `isScreenShare => kind == TrackType.VIDEO && source ==
  TrackSource.screenShareVideo` (`track_publication.dart:86-87`). It is
  false for screen-share audio by construction, which is why
  `MatrixLivekitVoipStream.type` never classifies it as `screenshare`.
- `LocalVideoTrack.createScreenShareTracksWithAudio`
  (`lib/src/track/local/video.dart:237-272`): forces
  `captureScreenAudio: true`, calls `getDisplayMedia`, returns
  `[LocalVideoTrack(TrackSource.screenShareVideo, ...)]` plus, when the
  stream has an audio track, `LocalAudioTrack(TrackSource.screenShareAudio,
  ...)` (`:261-270`).
- `Participant.getTrackPublicationBySource` finds a publication by exact
  source, then falls back to "compatible" publications of source `unknown`
  by kind (`lib/src/participant/participant.dart:288-299`). Overridden
  trivially in `local.dart:747-753` and `remote.dart:168-174`.
- `isScreenShareEnabled()` checks only `screenShareVideo`; there is a
  separate `isScreenShareAudioEnabled()` (`participant.dart:312-318`).
- `LocalParticipant.setScreenShareEnabled` -> `setSourceEnabled`
  (`local.dart:768-773`). On disable it removes the video publication and
  then the `screenShareAudio` one (`local.dart:799-804`), the same pattern
  `stopScreenshare` repeats. On enable with `captureScreenAudio` it also
  publishes both tracks and returns only the video publication
  (`local.dart:829-845`). The app does not use this enable path; it
  publishes the two tracks itself (section 3).

## 7. Other consumers of `session.streams`

`grep -rn "\.streams\b" commet/lib` finds only:

- `call_view.dart:306` (the grid, above).
- `commet/lib/client/matrix/components/rtc_screen_share_annotation/matrix_rtc_screen_share_annotation_component.dart:131-133`:
  looks a stream up by `streamId` to check `direction == outgoing` when a
  remote cursor event arrives. It matches by id, so it does not care about
  audio streams.

Indirect consumers:

- `VoipFullscreenStreamView`
  (`commet/lib/ui/organisms/call_view/voip_fullscreen_stream_view.dart:33-58`)
  wraps a single `VoipStreamView(canFullscreen: false)` and forwards hover
  positions with `stream.streamId`. It is only reachable from the fullscreen
  button, which exists for video/screenshare tiles, so it is never opened on
  a screen-audio stream.
- `call_sessions_panel.dart:82-83` uses `generalAudioLevel`, which folds
  over `streams` (section 3).
- The soundboard (`commet/lib/ui/organisms/soundboard/soundboard_call_controller.dart`)
  uses `session.client`/`session.roomId` only; it does not publish a LiveKit
  audio track (no `publishAudioTrack`/`LocalAudioTrack` outside the session
  file), so it does not add a third tile.

## 8. Tests

- Dart unit tests live in `commet/unit_test/` (not `test/`). CI runs
  `dart run scripts/codegen.dart && flutter test unit_test` from `commet/`
  (`.github/workflows/ci.yml:64-69`), gated on any `*_test.dart` existing
  there (`ci.yml:41-43`). Rust crates with tests run via `cargo test`
  (`ci.yml:71-77`).
- `commet/integration_test/` holds Synapse-backed integration tests
  (`commet/integration_test/README.md`, `runner.dart:1-25`) and benchmarks
  (`.github/workflows/benchmark.yml:56`). They need a running homeserver and
  are not the right place for this.
- `dev_dependencies` are `flutter_test`, `integration_test`, `drift_dev`,
  `build_runner`, `file`, plus icon/msix tooling
  (`commet/pubspec.yaml`, `dev_dependencies:` block). There is no mockito or
  mocktail; existing fakes are hand-written `implements X` classes with
  `noSuchMethod` (`deafen_test.dart:11-121`,
  `screen_share_audio_test.dart:23-41`, `:238-262`).
- `deafen_test.dart` already defines `FakeVoipSession` (with a `streams`
  list and `addStream`) and `FakeVoipStream` (with `direction`, `type`,
  `streamUserId`, volume fields). They are file-local; a new test for the
  grid would either duplicate them or move them to a shared helper under
  `commet/unit_test/`.
- `screen_share_audio_test.dart:95-191` shows the widget-test pattern for
  this area: `createTestApp` wraps the widget in a `MaterialApp` with the
  tiamat `ThemeSettings` extension (`:12-21`). `CallView` itself is harder to
  pump: it needs `session.client.getRoom(roomId)` (`call_view.dart:65`),
  starts a 200 ms timer, and constructs a `SoundboardCallController`
  (`call_view.dart:66-72`); `VoipStreamView` also needs a room and reads the
  global `preferences.developerMode` (`voip_stream_view.dart:45-50`, `:89`).
  A pure-Dart test of the tile-selection logic is much cheaper than a widget
  test of `CallView` if that logic is extracted (see options).

## 9. Docs conventions

`docs/` contained a single design/status document,
`docs/voice-audio-processing.md`, written as dated prose with a "Status"
header and cited paths. There was no `docs/research/` folder or template
before this note; it is created here following the instruction for this
task. `third_party/README.md` points at `docs/voice-audio-processing.md`
for the list of vendored changes. GitHub issues are the work tracker
(`.issue-drafts/` in the main checkout, not in this worktree).

## Summary of the causal chain

1. `setScreenShare` publishes the `LocalAudioTrack` with
   `TrackSource.screenShareAudio` as a plain audio track
   (`matrix_livekit_voip_session.dart:451-469`;
   `video.dart:261-270`).
2. `onLocalTrackPublished` / `onTrackPublished` append a
   `MatrixLivekitVoipStream` for every publication, with the same
   `streamUserId` as the member's mic (`:192-201`, `:268-276`).
3. `MatrixLivekitVoipStream.type` returns `audio` for any `AudioTrack`
   (`matrix_livekit_voip_stream.dart:132-135`); `isScreenShare` is
   video-only (`track_publication.dart:86-87`).
4. `generateLayout` makes a tile per stream (`call_view.dart:306-330`) and
   `VoipStreamView` draws every `audio` stream as an avatar with a speaking
   indicator driven by the source-agnostic visualizer
   (`voip_stream_view.dart:162-241`; `matrix_livekit_voip_stream.dart:23-39`,
   `:84-93`).

## Options for the fix

All options must keep the screen-audio stream in `streams` (or otherwise
keep `_applyStreamVolume` / `_setStreamsDeafened` reaching it), because
deafen relies on iterating `streams`
(`matrix_livekit_voip_session.dart:386-409`).

### A. Filter in the UI: skip screen-share-audio streams in `generateLayout`

Add a predicate in `call_view.dart:306-307` (and guard `mainStream`) that
drops streams which are screen-share audio.

- Needs a way to ask a `VoipStream` "are you screen-share audio?" without
  importing LiveKit into the UI, so in practice it is combined with B or C.
- Smallest blast radius: no change to deafen, volume, `generalAudioLevel`,
  annotation lookup or the fullscreen view.
- Leaves the speaking-indicator bug for the sessions panel: `generalAudioLevel`
  still folds shared audio in (`:596-601`), so the panel avatar pulses with
  the shared audio. Fixable separately by excluding those streams in the fold
  or by returning 0 from `audiolevel` for that source.
- Volume for shared audio is then only reachable via the mic tile (shared
  preference key), which is what happens today anyway.

### B. Add `VoipStreamType.screenshareAudio` to the enum

Change `voip_stream.dart:3` and make `MatrixLivekitVoipStream.type` return it
when `publication.source == TrackSource.screenShareAudio`
(`matrix_livekit_voip_stream.dart:132-135`).

- Affected code: the exhaustive `switch` in `voip_stream_view.dart:161-249`
  must handle the new case (either draw nothing / a small badge, or the
  caller filters it before it gets there); `call_view.dart:317` and
  `voip_stream_view.dart:103-105` compare against specific values and keep
  working; `deafen_test.dart` constructs `FakeVoipStream(type: ...)` and
  keeps compiling.
- The legacy `MatrixVoipStream.type` (`matrix_voip_stream.dart:49-59`) needs
  no change since it never produces such a stream, but every future
  `switch` on the enum must account for it.
- Cleaner model: the grid can decide "tile or not" from `type` alone, and a
  unit test can assert the classification without LiveKit objects.
- Slightly misleading in that `type` currently describes what to *render*;
  a value that means "render nothing" is a new category.

### C. Add a boolean to `VoipStream` (e.g. `bool get isScreenShareAudio`)

Keep `type == audio` but add a flag; `MatrixLivekitVoipStream` returns
`publication.source == TrackSource.screenShareAudio`, `MatrixVoipStream`
returns false, test fakes rely on `noSuchMethod` or add the getter.

- No exhaustive-switch churn; `voip_stream_view.dart` unchanged unless we
  want the mic tile to show a "sharing audio" badge.
- `generateLayout` filters on the flag (option A). `generalAudioLevel` can
  filter on it too, or `audiolevel` can return 0 for it.
- Slight interface growth for one LiveKit-specific concept, but the concept
  already leaks (`stopScreenshare` names the source, `:496-500`).

### D. Fold the audio into the screenshare tile

Rather than hiding the audio stream, attach it to the screen-share video
tile: the video tile's context menu shows the volume slider for the paired
audio stream (found by same `streamUserId` and `isScreenShareAudio`), and
its speaking indicator (if any) comes from that stream.

- Gives the Discord-style separate "stream volume" the issue mentions, but
  needs a separate preference key (today `setVolume` writes
  `call_user_volume:<userId>`, shared with the mic,
  `matrix_livekit_voip_stream.dart:163-171`; `preferences.dart:237-243`) and
  a matching change in `_applyStreamVolume` (`:331-339`), which reads the
  same key by `userId`.
- Larger change touching preferences, the session, the stream and the view;
  best done after A/B/C removes the duplicate tile.

### E. Do not add the stream at all in the session

Skip `TrackSource.screenShareAudio` publications in `addInitialStreams`,
`onTrackPublished`, `onLocalTrackPublished`, `onTrackUnmutedEvent`.

- Breaks deafen for shared audio: `setDeafened` only reaches tracks through
  `streams` (`:395-399`), and remote-side subscription volume would stay at
  the user preference. Would need a parallel list of hidden audio
  publications. Not recommended.

### F. Group the grid by member (longer term, per the issue)

Rebuild `generateLayout` around members: one avatar tile per
`streamUserId`, plus one tile per video/screenshare stream. Audio streams of
any source stop being tiles; the avatar tile's speaking state is derived
from the member's microphone stream only.

- Fixes this bug and the general "one tile per track" shape, but is a
  redesign of `call_view.dart:267-334`, `mainStream` selection and the
  fullscreen keys; the volume slider and mute/deafen badges move from
  "stream" to "member" semantics. Larger than #11 needs.

### Suggested test (any of A-C)

A pure-Dart test in `commet/unit_test/` using the existing `FakeVoipStream`
shape (`deafen_test.dart:90-121`): a member with a mic stream, a
screenshare stream and a screen-share-audio stream yields one avatar tile
and one screenshare tile. That requires the tile-selection predicate to be
callable without building `CallView` (extract it to a static function or a
small helper), because `CallView`/`VoipStreamView` need a client, a room,
`preferences` and a soundboard controller (`call_view.dart:65-72`,
`voip_stream_view.dart:45-50`, `:89`). A second test can assert
`generalAudioLevel` ignores screen-share audio if that is part of the fix.
