# Issue 8: LIVE state and preview in the voice panel

Research note for https://github.com/PondLabs/roscord/issues/8 (voice panel
should show a red LIVE pill, a 16:9 preview of the outgoing screen share /
camera, and stop buttons while the user is live). Read-only survey of this
repo at commit `906de7c1`, the vendored packages in `third_party/`, and the
matrix-dart-sdk checkout pub resolves for `commet/pubspec.yaml`
(`commetchat/matrix-dart-sdk` ref `upstream-v6.1.1`, pub-cache commit
`58e0bd24`). Line numbers are from those files as of 2026-09-16.

`docs/research/` did not exist before this note; it was created for it.

## 1. `VoipSession` interface

File: `commet/lib/client/components/voip/voip_session.dart`.

- `enum VoipState { incoming, connecting, connected, unknown, outgoing, ended }` (8-15).
- `abstract class VoipSession` (28-87). Members relevant here:
  - `bool get supportsScreenshare;` (47)
  - `bool get isSharingScreen;` (49)
  - `bool get isCameraEnabled;` (51)
  - `List<VoipStream> get streams;` (57)
  - `Stream<VoipState> get onConnectionStateChanged;` (66)
  - `Stream<void> get onStateChanged;` (68)
  - `Stream<void> get onUpdateVolumeVisualizers;` (70)
  - `Future<ScreenCaptureSource?> pickScreenCapture(BuildContext context);` (78)
  - `Future<void> setScreenShare(ScreenCaptureSource source);` (80)
  - `Future<void> stopScreenshare();` (82)
  - `Future<void> setCamera(MediaDeviceInfo? device);` (84)
  - `Future<void> stopCamera();` (86)

There is no `setScreenShareEnabled` / `setCameraEnabled` on the interface;
the stop methods are `stopScreenshare()` and `stopCamera()`. (The legacy
`MatrixVoipSession` has a non-interface `setCameraEnabled(bool)` helper at
`matrix_voip_session.dart:207-209`, unused by the UI.)

Sessions are tracked by `CallManager.currentSessions`, a
`NotifyingList<VoipSession>` (`commet/lib/client/call_manager.dart:38-39`),
added in `onClientSessionStarted` (64-66) and removed in `onSessionEnded`
(106-108).

## 2. `VoipStream` and the two implementations

File: `commet/lib/client/components/voip/voip_stream.dart`.

- `enum VoipStreamType { audio, video, screenshare }` (3)
- `enum VoipStreamDirection { incoming, outgoing }` (5)
- `VoipStreamType get type;` (8), `VoipStreamDirection get direction;` (10)
- `Widget? buildVideoRenderer(BoxFit fit, Key key);` (12)
- `Stream<void> get onStreamChanged;` (14)
- `double? get aspectRatio;` (32)

`VoipStreamView` (`commet/lib/ui/organisms/call_view/voip_stream_view.dart`)
calls `widget.stream.buildVideoRenderer(widget.fit, rendererKey) ?? const
CircularProgressIndicator()` inside a `Center` for `video` and `screenshare`
types (243-248), where `rendererKey` is a `GlobalKey` owned by the view state
(40). It subscribes to `stream.onStreamChanged` and
`session.onUpdateVolumeVisualizers` (46-49) and rebuilds on the former
(252-255). The fullscreen button is only shown for video/screenshare
(103-114). Note the operator-precedence bug on 103-105: `canFullscreen &&
type == video || type == screenshare`.

### `MatrixLivekitVoipSession` / `MatrixLivekitVoipStream`

Files: `commet/lib/client/matrix/components/voip_room/matrix_livekit_voip_session.dart`
(session) and `.../matrix_livekit_voip_stream.dart` (stream).

- `streams` is a plain growable `List<VoipStream>` field (session 514).
- `isCameraEnabled => livekitRoom.localParticipant?.isCameraEnabled() ?? false`
  (342-343); `isSharingScreen => ...isScreenShareEnabled() ?? false`
  (349-350). In LiveKit these are "publication for source exists and is not
  muted" (`third_party/livekit-client-sdk-flutter/lib/src/participant/participant.dart:302-304`,
  `312-314`).
- `onStateChanged => _stateChanged.stream`, a broadcast controller (69, 353).
- Room listener registered in the constructor (39-49). Handlers that touch
  `streams` and fire `_stateChanged`:
  - `onLocalTrackPublished` adds a `MatrixLivekitVoipStream` for the local
    publication and fires (268-276).
  - `onLocalTrackUnpublished` removes by `publication.sid` and fires (278-284).
  - `onTrackMutedEvent` removes any *video* stream whose publication got muted
    (local or remote) and fires (151-169). `onTrackUnmutedEvent` re-adds it
    (171-190).
- `setScreenShare` publishes the screen track (and optional audio) itself
  through `publishVideoTrack` / `publishAudioTrack` (412-473) and fires
  `_stateChanged` (472). `stopScreenshare` calls
  `localParticipant.setScreenShareEnabled(false)`, removes the screen-audio
  publication, and fires (494-511). `setCamera` /
  `stopCamera` call `setCameraEnabled(true/false)` and fire (476-491).
- Stream: `direction` is `outgoing` when `publication is
  LocalTrackPublication` (118-120). `type` is `audio` for `AudioTrack`,
  `screenshare` when `publication.isScreenShare`, else `video` (132-142).
  `buildVideoRenderer` returns `VideoTrackRenderer(publication.track as
  VideoTrack)` when the track is a `VideoTrack`, else `null`; it ignores both
  the `fit` and the `key` arguments (109-115). `aspectRatio` comes from
  `publication.dimensions` and is `null` until known (100-106).

How local publish / unpublish reaches `onStateChanged`, including when the
OS or the browser picker ends capture:

- Every `LocalTrack` sets `mediaStreamTrack.onEnded` to emit
  `TrackEndedEvent` (`third_party/livekit-client-sdk-flutter/lib/src/track/local/local.dart:177-180`).
- On publish, `LocalParticipant` listens for `TrackEndedEvent` and calls
  `removePublishedTrack(pub.sid)` (`.../participant/local.dart:245-248` for
  video, `529-532` for audio).
- `removePublishedTrack` removes the publication, stops the track, renegotiates
  and emits `LocalTrackUnpublishedEvent` on both participant and room events
  (`542-596`, emit at `589`).
- `MatrixLivekitVoipSession.onLocalTrackUnpublished` then drops the stream and
  fires `_stateChanged` (278-284), and `isSharingScreen` becomes false because
  the publication is gone.
- Camera off goes a different way: `setSourceEnabled(camera, false)` *mutes*
  the publication rather than unpublishing (`participant/local.dart:790-806`;
  screen share is the special case that unpublishes at 799-800). The muted
  publication triggers `TrackMutedEvent`, which `onTrackMutedEvent` turns into
  a stream removal plus `_stateChanged` (session 151-169). `isCameraEnabled`
  reads the muted flag, so it flips too.

### `MatrixVoipSession` / `MatrixVoipStream` (legacy 1:1)

Files: `commet/lib/client/matrix/components/voip/matrix_voip_session.dart`
and `.../matrix_voip_stream.dart`.

- `isSharingScreen => session.localScreenSharingStream != null` (90);
  `isCameraEnabled => session.localUserMediaStream?.isVideoMuted() == false`
  (93-94).
- `streams` is a `late List<VoipStream>` built by `initStreams()` (102,
  285-304) from the SDK's local + remote `WrappedMediaStream`s, filtered by
  `shouldAddStream` (306-320: only `Usermedia` and `Screenshare` purposes, and
  screenshare only if not `videoMuted`).
- `onStateChanged` fires from three places: the SDK's `onCallStateChanged`
  (42-45), `onStreamAdded` (322-336) and `onStreamRemoved` (338-341), the last
  two wired to `session.onStreamAdd` / `onStreamRemoved` (53-54).
- `setScreenShare` calls `getDisplayMedia` itself and
  `session.addLocalStream(stream, Screenshare)` (228-258); `stopScreenshare`
  calls `session.removeLocalStream` for every Screenshare stream (261-266).
  In the SDK `removeLocalStream` emits `onStreamRemoved` (`call_session.dart:744-760`,
  emit at 759), so `MatrixVoipSession.onStateChanged` fires.
- OS-ended screen share: the SDK sets `track.onEnded` on its own
  `setScreensharingEnabled(true)` path to call `setScreensharingEnabled(false)`
  (`call_session.dart:585-596`), whose disable branch removes senders, stops
  tracks and calls `_removeStream` (`602-611`), which emits `onStreamRemoved`
  (734). **However**, `MatrixVoipSession.setScreenShare` bypasses
  `setScreensharingEnabled` and calls `addLocalStream` directly (255-256), so
  that `onEnded` hook is *not* installed for streams started from roscord.
  Nothing in `matrix_voip_session.dart` sets `onEnded` on the captured
  tracks either. On the legacy path an OS-ended capture therefore does not
  update `streams`, `isSharingScreen` or `onStateChanged` today.
- Camera on/off on the legacy path: `setCamera` / `stopCamera` call
  `session.setLocalVideoMuted` (269-283) and do not fire `_onStateChanged`.
  In the SDK `setLocalVideoMuted` calls `localUserMediaStream.setVideoMuted`
  and `updateMuteStatus` (`call_session.dart:769-779`); `setVideoMuted` only
  emits `WrappedMediaStream.onMuteStateChanged`
  (`utils/wrapped_media_stream.dart:96-99`), and `updateMuteStatus` sends SDP
  metadata without touching `onCallStateChanged` (`1254-1276`). Nothing in
  `commet/lib` listens to `onMuteStateChanged` (grep: no hits). So
  `MatrixVoipSession.onStateChanged` does **not** fire when the camera is
  toggled. `MatrixVoipStream` does listen to `stream.onStreamChanged`
  (stream 25), which only fires on `setNewStream` (`wrapped_media_stream.dart:86-89`),
  i.e. when `insertVideoTrackToAudioOnlyStream` replaces the stream.
- Stream: `direction` from `stream.isLocal()` (148-150). `type` is
  `screenshare` for the Screenshare purpose, else `audio` when `videoMuted`,
  else `video` (49-59); so a camera toggle changes the *type* of the existing
  usermedia stream rather than adding/removing a stream.
  `buildVideoRenderer` owns one `RTCVideoRenderer` per `MatrixVoipStream`
  (15, 38-46); for `BoxFit.contain` it wraps `RTCVideoView(renderer!)` in an
  `AspectRatio`, otherwise it returns `RTCVideoView(key: key, renderer!,
  objectFit: cover)` (126-145). It returns a `CircularProgressIndicator`
  until the renderer exists (127-129). `aspectRatio` falls back to `1` when
  the renderer has no size yet (100-111).

## 3. The panel widgets today

### `CallSessionsPanel` / `CallSessionPanel`

File: `commet/lib/ui/molecules/call_sessions_panel.dart`.

- `CallSessionsPanel({this.height = 50})` (14-15) subscribes to
  `clientManager!.callManager.currentSessions.onListUpdated` and calls
  `setState` (26-28). It builds a `Container` with `surfaceTint.withAlpha(10)`
  background and radius 8, containing a `Column` of one `ClipRRect` +
  `CallSessionPanel(session: entry, height: widget.height)` per session
  (35-52). The `Column` has no fixed height, so it grows with its children.
- `CallSessionPanel({required this.session, this.height = 40})` (55-58) is a
  `StatefulWidget` with `TickerProviderStateMixin` (63-64). In `initState` it
  resolves the room, creates an `AnimationController` for the audio level
  (72-75), and subscribes to `session.onStateChanged` (`setState`) and
  `session.onUpdateVolumeVisualizers` (`updateStats` then
  `audioLevel.animateTo(generalAudioLevel)`) (77-85). Subscriptions are
  cancelled in `dispose` (90-97).
- Widget tree (100-204): `Material(transparent)` > `InkWell(onTap:
  EventBus.doOpenRoom(session.roomId, clientId: session.client.identifier))`
  (103-107) > `SizedBox(height: widget.height)` (108-109) > `Row(spaceBetween)`
  with a left `Row` [speaker icon in a `height x height` box driven by
  `audioLevel` (116-142), `tiamat.Text(session.roomName)` (143)] and a right
  `Row` of three `height x height` `tiamat.IconButton`s: mute/unmute via
  `callManager.mute()/unmute()` (149-164), deafen/undeafen via
  `callManager.deafen()/undeafen()` (166-184, error colour when deafened),
  and hang up via `session.hangUpCall()` (186-196, `iconColor: error`).
- `pickAnimation` wraps the icon in `RingShakerAnimation` while
  `state == VoipState.incoming` (207-213).
- Navigation: the whole row is the `InkWell`; `EventBus.doOpenRoom` is the
  only navigation call (105-106).

### `CurrentSessionPanel`

File: `commet/lib/ui/molecules/current_session_panel.dart`.

- Subscribes to `WidgetComponent.currentSessions.onListUpdated` and
  `callManager.currentSessions.onListUpdated` (35-42).
- `build` returns `Padding(2,0,0,0)` > `Column(mainAxisSize: min)` (71-73)
  with, in order: the widget sessions row, which *is* clamped to 40 (`SizedBox(height:
  40, child: WidgetSessionsPanel(height: 40))`, 76-83); the call sessions row
  (84-90), which is **not** wrapped in a `SizedBox` -- it is only
  `Padding(4,4,4,0) > CallSessionsPanel(height: 40)`, so "fixed height 40"
  is the button-row height passed down, not a hard clamp on the panel; and the
  profile row with avatar, name, id and `UserPanelSettings` (91-195).
  `profileHeight` is 60 on mobile, 50 on desktop (26).

So adding a second row under the button row inside `CallSessionPanel` will
make the sidebar column taller without any change to `CurrentSessionPanel`.
The desktop host column is `mainAxisSize: min` with the room picker in an
`Expanded`, so extra panel height takes space from the room list.

### `CallView` overlay (the existing screenshare / camera controls)

File: `commet/lib/ui/organisms/call_view/call_view.dart`.

- `CallView` takes callbacks `pickScreenshareSource`, `stopScreenshare`,
  `pickCamera`, `disableCamera` (18-44), all wired by `CallWidget`
  (`call.dart:19-30`) to `session.pickScreenCapture` + `session.setScreenShare`
  (33-38), `session.stopScreenshare()` (40-42), `session.setCamera(null)`
  (64-68) and `session.stopCamera()` (74-76).
- `callButtons` wraps the content in a `MouseRegion` that toggles
  `isMouseHovering` (128-138) and an `AnimatedOpacity` that is always 1 on
  mobile and hover-only on desktop (143-145). Buttons: screen share
  (151-155), stop screen share only while `currentSession.isSharingScreen`
  (156-161), camera toggle keyed on `currentSession.isCameraEnabled`
  (192-201), etc.
- `CallView` rebuilds on `session.onStateChanged` (61-63) and lays out
  `session.streams` in a `BentoLayout` of `VoipStreamView`s, with an optional
  `mainStream` rendered larger (267-334). `CallWidget` is only mounted while
  the voice room is the current room (`commet/lib/ui/pages/main/room_primary_view.dart:55-64`
  and `commet/lib/ui/organisms/voip_room_view/voip_room_view.dart:80`), so
  when the user is on a text channel the panel preview would be the only
  renderer of the local track.

## 4. Where `CurrentSessionPanel` is hosted

- Desktop: `commet/lib/ui/pages/main/main_page_view_desktop.dart`. The
  left column is `SizedBox(width: 320)` > `Column(mainAxisSize: min,
  crossAxisAlignment: stretch)` (45-49) with an `Expanded(Row[SideNavigationBar
  tile, Flexible(room picker)])` and then `tiamat.Tile.low(... child:
  ScaledSafeArea(top: false, child: CurrentSessionPanel(currentUser:
  state.currentUser)))` (102-112). The panel spans the full 320 px (minus the
  tile and the panel's own 2 + 4/4 px paddings), so a full-width 16:9 preview
  is roughly 310 x 175 px. The spaces column is not separate from the panel
  row: the panel sits under both the space bar and the room list.
- Mobile: `commet/lib/ui/pages/main/main_page_view_mobile.dart`. The
  navigation drawer `navigation()` (182+) ends with the same
  `tiamat.Tile.low(... ScaledSafeArea(bottom: true, top: false, child:
  CurrentSessionPanel(...)))` (245-256). The drawer is the `left` panel of
  `OverlappingPanels` (128-143, `commet/lib/ui/molecules/overlapping_panels.dart`),
  which pads the left panel by `restWidth + 3` on the right with
  `restWidth = 40` by default (32, 45, 209), i.e. the panel is screen width
  minus 43 logical px (after `preferences.appScale`, 71-72). The left panel is
  wrapped in `Offstage(offstage: translate <= 0)` (213-218), so while the main
  view is showing the sidebar (and any preview in it) is built but not
  painted.
- `MediaQuery.of(context).mobile` / `.desktop` come from the
  `LayoutQueryData` extension (`commet/lib/config/layout_config.dart:56-87`).

## 5. Test conventions

- There is no `commet/test/`. Dart tests live in `commet/unit_test/`
  (`deafen_test.dart`, `screen_share_audio_test.dart`,
  `url_preview_widget_test.dart`, `video_player_controls_test.dart`, a
  `soundboard/` folder, etc.). CI runs `dart run scripts/codegen.dart` then
  `flutter test unit_test` from `commet/` (`.github/workflows/ci.yml:41, 64-69`).
- `commet/integration_test/` holds Synapse-backed flows (login, spaces, key
  verification, multi-account) plus a `benchmark/` folder; nothing touches
  voice.
- No `commet/lib/client/simulated/` directory exists in this checkout.
- Fake `VoipSession` already exists in tests: `FakeVoipSession implements
  VoipSession` (`commet/unit_test/deafen_test.dart:11-88`) with mutable
  `isMicrophoneMuted` / `isDeafened`, a `_streams` list exposed as `streams`,
  broadcast controllers for `onStateChanged`, `onConnectionStateChanged` and
  `onUpdateVolumeVisualizers`, and `noSuchMethod` for everything else (87).
  `FakeVoipStream implements VoipStream` (90-121) takes `direction`, `type`,
  `streamUserId`, tracks volume, and also falls back to `noSuchMethod` (120).
  Both are file-private to that test; a panel widget test would need its own
  copy or a shared helper.
- Widget-test pattern: `screen_share_audio_test.dart` defines
  `createTestApp(Widget child)` returning a `MaterialApp` whose theme has
  `extensions: const [ThemeSettings()]` from
  `tiamat/config/style/theme_extensions.dart` (12-21) and uses
  `testWidgets` + `tester.pumpWidget(createTestApp(...))` (96-100). Note that
  `CallSessionPanel` dereferences the global `clientManager!` for
  mute/deafen and `EventBus` for navigation, so a widget test of the panel
  as-is needs those globals or the panel needs injectable callbacks.

## 6. Localization and theming

- Strings are `Intl.message` getters on the widget state, named after the
  getter, e.g. `String get labelEmojiPickerEmojiTab => Intl.message("Emoji",
  desc: "...", name: "labelEmojiPickerEmojiTab");`
  (`commet/lib/ui/molecules/emoticon_picker.dart:57-59`). Parameterised
  messages pass `args:` (`commet/lib/client/call_manager.dart:23-33`). ARB
  files are in `commet/assets/l10n` and generation goes to
  `lib/generated/l10n` (`commet/l10n.yaml:1-6`; `flutter_intl` in
  `commet/pubspec.yaml:184-187`). `CallSessionPanel` currently has no
  localized strings; `CallView` has a hard-coded `"Call ended"` (337).
- Theme: `tiamat` builds its dark scheme with `ColorScheme.fromSeed(...
  dynamicSchemeVariant: DynamicSchemeVariant.monochrome, primary: ...)` and
  does not override `error` (`tiamat/lib/config/style/theme_dark.dart:26-39`),
  so `ColorScheme.of(context).error` / `onError` are Material's default error
  palette. Existing code uses that pair for "red" state: deafened icon
  colour (`call_sessions_panel.dart:131-133, 179-181`), hang-up
  (`195`), the deafened badge in `voip_stream_view.dart:219-235`
  (`error` background, `onError` icon, radius 8) and the `errorContainer`
  circle buttons in `call_view.dart:168-170, 210`. The speaking green is
  `SpeakingIndicator.color = Color(0xFF23A55A)`
  (`commet/lib/ui/atoms/speaking_indicator.dart:16`).
- Tiamat has no pill/badge/chip atom (`tiamat/lib/atoms/`: avatar, button,
  circle_button, icon_button, text, tile, tooltip, ...). The deafened badge
  above is the closest in-tree example of a rounded coloured tag.

## 7. Rendering the same local track twice

LiveKit path (`MatrixLivekitVoipStream.buildVideoRenderer` ->
`VideoTrackRenderer`,
`third_party/livekit-client-sdk-flutter/lib/src/widgets/video_track_renderer.dart`):

- Each `VideoTrackRenderer` state creates its own `rtc.RTCVideoRenderer`
  and `initialize()`s it unless a `cachedRenderer` is passed (96-106,
  142-144); `_attach` sets `srcObject = track.mediaStream` and listens for
  `TrackStreamUpdatedEvent` (165-185). On dispose it removes its view key and,
  when `autoDisposeRenderer` (default true), disposes its renderer
  (155-163). Nothing prevents several instances per track; each just
  registers a view key on the track (`track/local/local.dart:50-58`).
- Constructor options: `fit` (`VideoViewFit.contain|cover`), `mirrorMode`,
  `renderMode`, `cachedRenderer`, `autoDisposeRenderer`, `autoCenter`
  (72-81). Mirroring is forced off for screen share (326-328).
- On native, `rtc.RTCVideoRenderer.initialize()` asks the plugin for a new
  texture (`third_party/flutter-webrtc/lib/src/native/rtc_video_renderer_impl.dart:22-30`)
  and `RTCVideoView` paints `Texture(textureId: ...)` inside a `FittedBox`
  (`.../native/rtc_video_view_impl.dart:40-62`). In C++ each renderer is a
  sink added with `track_->AddRenderer(this)`
  (`third_party/flutter-webrtc/common/cpp/src/flutter_video_renderer.cc:84-93`),
  so two renderers on one track mean two sinks and two texture uploads per
  frame; the capture and the encoder are unaffected.
- On web, each renderer builds its own `web.MediaStream` from the same video
  track and attaches it to its own `<video>` element rendered through
  `HtmlElementView` (`third_party/flutter-webrtc/lib/src/web/rtc_video_renderer_impl.dart:114-135`,
  `.../web/rtc_video_view_impl.dart:156-157`). Attaching one
  `MediaStreamTrack` to multiple video elements is standard browser
  behaviour.
- Neither package documents a perf caveat for multiple renderers; the cost
  is one extra full-resolution texture (native) or `<video>` decode (web) per
  extra renderer. The thumbnail cannot subscribe at a lower resolution: the
  track is local, so simulcast layers do not apply.

Legacy path (`MatrixVoipStream.buildVideoRenderer`): one `RTCVideoRenderer`
(one texture) per `MatrixVoipStream` (15, 38-46), and `RTCVideoView` is a
stateless widget over that renderer, so rendering the stream twice shares the
same texture id in two `Texture` widgets. That is cheaper than the LiveKit
case but the two views cannot have different keys/fits reliably: `contain`
returns an unkeyed `AspectRatio` and `cover` returns a keyed view (131-143).

Already rendered twice in the codebase: `Lightbox.show` uses
`showGeneralDialog` (`commet/lib/ui/atoms/lightbox.dart:37-50`), which keeps
the underlying route mounted, and `CallView` opens
`VoipFullscreenStreamView(stream: e)` from a tile that stays in the bento
grid (`call_view.dart:286-292, 321-328`;
`voip_fullscreen_stream_view.dart:40-44`), so any stream -- including the
local screen share -- is rendered in the grid and in the lightbox at the same
time. Also, because `_CallViewState` builds `VoipStreamView` from
`session.streams` (306-330), the user's own screen share and camera are
already rendered locally while sharing.

## 8. Existing LIVE / thumbnail UI

- No LIVE pill exists yet. Issue 9 (voice channel list) is still open and
  targets `RoomTextButton.buildCallMember`
  (`commet/lib/ui/atoms/room_text_button.dart:357-...`), which today renders a
  `tiamat.TextButton` with avatar and name and an optional `footer` row of
  activity icons (372-395). Nothing to reuse there yet; a shared pill widget
  could serve both issues.
- Closest in-tree badge: the muted/deafened badge in
  `voip_stream_view.dart:215-238` (`AnimatedScale` + rounded `Container` with
  `error`/`primary` background and an icon).
- 16:9 thumbnails exist for unrelated content (`space_appearance_settings_page.dart:102`,
  `generic_video_provider.dart:53`) but no reusable thumbnail widget.
- `WidgetSessionsPanel` (`commet/lib/ui/molecules/widget_sessions_panel.dart`)
  is the sibling 40 px row for Matrix widgets; it has no preview.

## Implications for implementation

- State and events are already sufficient on the LiveKit path: filter
  `session.streams` for `direction == outgoing && type in {screenshare,
  video}`, and rebuild on `session.onStateChanged` (the panel already
  subscribes). OS-ended capture reaches the panel through
  `TrackEndedEvent -> removePublishedTrack -> LocalTrackUnpublishedEvent ->
  onLocalTrackUnpublished -> _stateChanged`.
- The legacy path needs two fixes to satisfy the acceptance criteria:
  `MatrixVoipSession.setCamera`/`stopCamera` do not fire `onStateChanged`
  (either fire it there or forward `WrappedMediaStream.onMuteStateChanged`),
  and `setScreenShare` bypasses the SDK's `onEnded` hook, so an OS-ended
  capture is never removed; installing `track.onEnded = () =>
  stopScreenshare()` on the tracks obtained in `setScreenShare` (228-258)
  mirrors what the SDK does at `call_session.dart:591-593`. Also on legacy the
  camera does not add a stream; the existing usermedia stream changes `type`
  from `audio` to `video`, so the preview filter must accept that.
- Layout: put the LIVE section as a second row inside `CallSessionPanel`
  under the existing `SizedBox(height: widget.height)` row; `CallSessionsPanel`
  and `CurrentSessionPanel` impose no clamp. The section must be
  width-bounded (320 px desktop, screen-43 px mobile) and should size the
  preview from the width (`AspectRatio(16/9)`), not from `height`.
- `MatrixLivekitVoipStream.buildVideoRenderer` ignores `fit` and `key`; the
  thumbnail can call it as-is, or pass `VideoTrackRenderer(fit:
  VideoViewFit.cover, autoCenter: false)` directly if the panel needs cover
  cropping. Give each preview a `ValueKey(streamId)` so Flutter does not
  re-attach renderers when the list reorders.
- Each extra `VideoTrackRenderer` is another texture/sink at full capture
  resolution; the sidebar preview is small, so the GPU cost is one texture
  upload per frame. If stutter shows up, options are a lower-FPS preview
  (e.g. throttle with `TickerMode`/`Offstage` when the CallView is also
  visible) or reusing the CallView's renderer via `cachedRenderer` +
  `autoDisposeRenderer: false`, which the vendored SDK already supports.
- Stop buttons should call `session.stopScreenshare()` /
  `session.stopCamera()` directly (same calls as `CallWidget`), and the
  preview `InkWell` should reuse `EventBus.doOpenRoom(roomId, clientId:
  ...)` from the row above.
- Strings: add `Intl.message` getters (LIVE, "Screen", "Camera", "Stop
  sharing", "Turn off camera") on the panel state; colour the pill with
  `ColorScheme.error` / `onError` like the deafened badge.
- Tests: a `unit_test/live_voice_panel_test.dart` can reuse the
  `FakeVoipSession`/`FakeVoipStream` shape from `deafen_test.dart`, but
  `CallSessionPanel` reads `clientManager!` and `EventBus`; consider
  extracting the LIVE section into a widget that takes the session and
  callbacks so it can be pumped with `createTestApp` without globals, and
  make `buildVideoRenderer` on the fake return a `SizedBox` so no WebRTC
  platform channel is touched.
