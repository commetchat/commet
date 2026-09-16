# Issue #9: LIVE badge for screen sharers in the sidebar voice list

Research note for https://github.com/PondLabs/roscord/issues/9, 2026-09-16.
roscord paths are relative to the repo root at `a484ef19`. This note changes no
code. External sources are pinned as follows (line numbers refer to these
revisions):

| Key | Source (raw, pinned) |
|---|---|
| MSC3401 | `matrix-org/matrix-spec-proposals@6b98d667` `proposals/3401-group-voip.md` (PR closed 2026-09-16, label `obsolete`) |
| MSC4143 | `matrix-org/matrix-spec-proposals@5c71b96c` `proposals/4143-matrix-rtc.md` (PR head, open, proposed FCP) |
| MSC4143-2024 | same file at `ec9fa8b8` (2024-12-17, the state-event revision) |
| MSC4195 / MSC4195-2024 | `hughns/matrix-spec-proposals@5ce2a2ca` / `@60727441` `proposals/4195-matrixrtc-livekit.md` |
| MSC4196 | `matrix-org/matrix-spec-proposals@2407455c` `proposals/4196-matrixrtc-m-call.md` |
| MSC4075, MSC4157 | `@0f981da3` `proposals/4075-rtc-notification-event.md`, `@6a719a89` `proposals/4157-delayed-events-widget-api.md` |
| MSC4140 / MSC4140-old | `@02a1abfb` (merged) / `@a09a883d` `proposals/4140-delayed-events-futures.md` |
| MSC4222, MSC4354 | `@32eaa210` `proposals/4222-sync-v2-state-after.md` (merged), `@4ad14b0c` `proposals/4354-sticky-events.md` |
| SPEC | `matrix-org/matrix-spec@v1.19` `data/event-schemas/schema/components/sdp_stream_metadata.yaml` |
| JS | `matrix-org/matrix-js-sdk@v42.4.0` `src/matrixrtc/…` (and `src/@types/event.ts`) |
| EC | `element-hq/element-call@v0.26.0` (= `71593f1a`) |
| RUMA | `ruma/ruma@ruma-0.17.0` `crates/ruma-events/src/call/…` |
| SYN | `element-hq/synapse@v1.161.0` |
| LKJWT | `element-hq/lk-jwt-service@v0.7.0` (= `6c761252`) |
| SDK | `~/.pub-cache/git/matrix-dart-sdk-58e0bd24c6a2d74d727dc92a24dc076144fae43b/` (commetchat `upstream-v6.1.1`, `pubspec.lock:1278-1286`) |
| LK | `third_party/livekit-client-sdk-flutter/` (2.7.0, commetchat `hkdf` @ `19f6b86d`) |
| LKDOCS | docs.livekit.io `/transport/data/state/participant-attributes/` and `/reference/other/roomservice-api/` (unversioned, fetched 2026-09-16) |

URL form: `https://raw.githubusercontent.com/<repo>/<ref>/<path>`.

## Question

Can the sidebar voice-channel list (`RoomTextButton.buildCallMember`) show a
red LIVE pill for members who share their screen, and optionally a camera icon
for camera-only members? The hard part is showing it to viewers who are not in
the call, because they only see `org.matrix.msc3401.call.member` state. The
issue lists two options:

1. Add a custom `chat.commet.streams` field to our own membership and rewrite
   it whenever sharing starts or stops. This must not break other clients,
   must work with the heartbeat and the delayed leave event, and must not
   leave a stale LIVE badge after a crash.
2. Show the badge only to viewers who are in the call.

It also asks whether a standard way already exists.

## Short answer

- **No standard exists.** No MatrixRTC MSC (4143, 4195, 4196, 4075), Element Call or matrix-js-sdk puts screen-share state anywhere a non-participant can read it. Element Call learns it only from LiveKit track publications.
- **The only standard media hint in a membership is the camera intent.** It is `m.call.intent` (`audio` or `video`), which is `application.intent` in MSC4196. Element Call rewrites its membership with it on every camera toggle.
- **The only room-state precedent is gone.** MSC3401's `feeds[].purpose: m.screenshare` was it, and that MSC was closed as obsolete today.
- **Option 1 won't break other clients.** matrix-js-sdk and ruma ignore unknown keys. matrix-dart-sdk's MatrixRTC code uses a different event type. Each client writes only its own per-device state key.
- **Nothing else can overwrite the field.** roscord builds its membership by hand, so no SDK refresh can drop it. The race to manage is between roscord's own writers: join, update and hang-up.
- **Crash safety comes from the existing delayed leave.** When roscord's 30 s MSC4140 delayed leave fires, it replaces the whole content with `{}`, so the field goes away with the membership. Do not add a separate TTL.
- **Rewrites have three constraints:**
  - Keep `created_ts`. Without it, Element Call treats every toggle as a rejoin and re-shares or rotates its keys.
  - Grow `expires` on each rewrite.
  - Publish only while a delayed leave is active. Synapse ships with delayed events disabled.
- **Recommendation: do both.** In-call viewers read the badge from LiveKit, which is authoritative and instant. Everyone else reads `"chat.commet.streams"` from our membership, rewritten about 1 s after each local publish, unpublish or mute change.

## Findings

### 1. Membership formats and media-state fields

- **MSC3401 (legacy).** Each user has one `m.call.member` state event with a `m.calls[].m.devices[]` list. Each device carries `expires_ts` and `feeds[]`, and each feed has `purpose: m.usermedia | m.screenshare` (MSC3401:128-229). The unstable type is `org.matrix.msc3401.call.member` (305-310). The MSC notes that state events are unencrypted, so they leak who is in a call (299-301). The PR was closed on 2026-09-16 as "abandoned and superseded by the MatrixRTC stack starting at #4143" (closing comment on matrix-org/matrix-spec-proposals#3401).
- **MSC4143, state-event revision.** Membership was one `m.rtc.member` state event per member, sent as `org.matrix.msc3401.call.member` (MSC4143-2024:599-601).
  - Fields were `member`, `session.application`, `created_ts`, `focus_active` and `foci_preferred`, plus "Additional fields … depending on the application type" (61-81, 129-134).
  - Leaving meant writing empty content (155-170).
  - The delayed leave event had to be scheduled before the join event was sent (226-248).
  - The shape clients actually send is flatter. js-sdk calls it `SessionMembershipData`: `application`, `call_id`, `device_id`, `focus_active`, `foci_preferred`, `created_ts`, `scope`, `expires` (a duration measured from `created_ts`), `m.call.intent` and `membershipID` (JS `membershipData/session.ts:26-98`).
- **MSC4143, current revision.** Membership moved to sticky `m.rtc.member` room events (MSC4354) with `slot_id`, `member`, `application`, `transports` and `sticky_key`. The `application` object may carry application-specific properties (MSC4143:158-221, esp. 184-189).
  - These events must be encrypted in encrypted rooms (417-419).
  - The MSC recommends a delayed leave of 15-30 s (323-331).
  - It describes state-event membership as an earlier iteration (652-655).
  - Nothing in it describes published media.
- **MSC4195 (LiveKit transport).**
  - The legacy revision defines two focus objects: `{type: livekit, livekit_service_url}` for `foci_preferred` and `{type: livekit, focus_selection: oldest_membership}` for `focus_active` (MSC4195-2024:15-65).
  - The current revision uses an `m.livekit` entry in `transports.published` (MSC4195:49-98) and gives every token `canUpdateOwnMetadata` (361-384).
  - It warns that anyone who can get a token can see "whether participants are publishing audio, video or a screenshare" without joining, and says clients SHOULD warn about LiveKit participants they cannot map to a member (716-732).
- **MSC4196 (the `m.call` application).** It defines `application.intent` (`audio` | `video`): "Clients SHOULD set this field when joining and update it as they en- or disable their video stream" (MSC4196:87-97).
  - Screen sharing is plain LiveKit publishing (141-149).
  - `intent` is optional because it tells the whole room whether a member's camera is on (181-186).
  - The MSC has no screen-share field.
- **MSC4075 (notifications).** It carries no media state and defers audio/video to the MSC4196 `intent` (MSC4075:162-163, 333-335).
- **MSC4140 (delayed events, merged).**
  - A server may send a delayed event up to 30 s late, and normal rate limits apply (MSC4140:84-88).
  - `restart` resets the timer to now + delay (164-176).
  - Unstable endpoints are listed at 632-644.
  - An older revision says a delayed state event is cancelled only when a *different* user writes the same state (MSC4140-old:287-300).
- **Less relevant proposals.**
  - MSC4157 only exposes delayed events to Element Call when it runs as a widget (MSC4157:1-15).
  - MSC4222 notes that state can change outside the timeline (MSC4222:1-13), which matters for the refresh trigger in section 4.
  - MSC4354 explains that state written by unprivileged users "can never be cleaned up as the DAG is append-only" (MSC4354:9-16).
- **Spec v1.19.** The only screen-share vocabulary in the spec is 1:1 call `sdp_stream_metadata` (`purpose: m.usermedia|m.screenshare`, `audio_muted`, `video_muted`). It travels in call events between the two call parties, not in room state (SPEC:1-43).

### 2. Element Call and matrix-js-sdk

- **Writing.** js-sdk writes `org.matrix.msc3401.call.member` (`@types/event.ts:157`) at the state key `_{user}_{device}_m.call`, which is the same key format roscord uses (JS `MembershipManager.ts:770-782`).
  - `makeMyMembership` builds a fixed set of keys from scratch on every write and adds `created_ts: ownMembership.createdTs()` on updates (788-819).
  - It never reads or merges other keys, and it only writes its own state key.
- **Parsing.** Unknown keys are ignored.
  - `checkSessionsMembershipData` checks only the keys it knows (`session.ts:106-146`).
  - The parsed membership keeps the whole content (`CallMembership.ts:66-86`).
  - The pre-filter only requires `application` plus at least one more key (`MatrixRTCSession.ts:973-990`).
- **A content-only change still counts as a change.**
  - `CallMembership.equal` deep-compares the whole content (`CallMembership.ts:105-107`), so any difference emits `MembershipsChanged` and calls `encryptionManager.onMembershipsUpdate` (`MatrixRTCSession.ts:894-930`).
  - Key sharing identifies a member by `(userId, deviceId, createdTs())` (`RTCEncryptionManager.ts:374-410`), where `createdTs() = created_ts ?? origin_server_ts` (`CallMembership.ts:324-334`). A rewrite without `created_ts` therefore looks like a leave followed by a join, which triggers a key re-share or rotation (`RTCEncryptionManager.ts:405-440`).
  - Member ordering and the `oldest_membership` SFU choice also use `createdTs()` (`MatrixRTCSession.ts:435`, `CallMembership.ts:401-422`).
- **Expiry.** A membership expires at `createdTs() + (expires ?? 4 h)` (`CallMembership.ts:37, 340-382`). Expired members are dropped (`MatrixRTCSession.ts:993-1017`), and a timer re-checks at the next expiry (745-764).
- **Heartbeat and refresh.**
  - The delayed leave has content `{}`, an 8 s delay and a restart every 5 s. The membership is rewritten about once an hour with `expires` = 4 h × n (`MembershipManager.ts:84, 392-410, 476-483, 726-750`).
  - After every join write, js-sdk restarts the delayed event and reschedules it if it is gone, "due to lack of element-hq/synapse#17810" (486-509, 687-724).
- **Camera intent.** `updateCallIntent` rewrites the membership when the intent changes (300-310). Element Call calls it on every camera toggle (EC `src/state/CallViewModel/localMember/LocalMember.ts:674-686`).
- **Screen share in Element Call is LiveKit-only.**
  - `observeSharingScreen$` watches `TrackPublished`/`TrackUnpublished` and reads `isScreenShareEnabled` (LocalMember.ts:956-964). Remote participants are handled the same way in `src/state/media/WrappedUserMediaViewModel.ts:125-143`.
  - Toggling only calls `participant.setScreenShareEnabled` (LocalMember.ts:874-895).
  - `setAttributes` and `setMetadata` appear nowhere in `EC/src` (grep: 0 hits).
  - Element Call's widget capability list confirms the only state it writes is its own call.member keys (`src/widget.ts:120-151`).
- **Modes.**
  - Element Call defaults to `Compatibility` mode, which means state events and multi-SFU. Sticky events are used only in `Matrix_2_0` mode (`src/config/ConfigOptions.ts:14-25`, `src/state/CallViewModel/CallViewModel.ts:536`, LocalMember.ts:1060).
  - js-sdk reads both sticky and state memberships (`MatrixRTCSession.ts:1058-1090`).
- **ruma (Rust event types).**
  - `SessionMembershipData` has no `deny_unknown_fields`, so unknown keys are ignored (RUMA `member/member_data.rs:247-282`).
  - Join time is `MIN(created_ts, origin_server_ts)`, and expiry is join time + `expires` (275-281, 145-155).

### 3. matrix-dart-sdk 6.1.1 (MatrixRTC code roscord does not use)

- **Separate event type.** The SDK's `GroupCallSession` writes `com.famedly.call.member` with a `memberships` array (SDK `lib/matrix_api_lite/model/event_types.dart:103`, `lib/src/voip/models/call_membership.dart:3-31`). `VoIP` only reacts to that type (`lib/src/voip/voip.dart:121-126`).
  - roscord creates `VoIP` only for 1:1 calls (`commet/lib/client/matrix/components/voip/matrix_voip_component.dart:52`) and writes the MSC3401 event type itself (section 4).
  - The SDK therefore never touches roscord's LiveKit membership.
- **A parse→serialize round trip drops unknown keys.**
  - `CallMembership.fromJson` reads fixed fields, and `toJson` emits a fixed map: `call_id`, `application`, `scope`, `foci_active`, `device_id`, `expires_ts`, `membershipID`, `feeds` (`call_membership.dart:87-129`).
  - `updateFamedlyCallMemberStateEvent` rebuilds the whole array from those parsed objects (`lib/src/voip/utils/famedly_call_extension.dart:100-129`).
- **Expiry.**
  - `expires_ts` is absolute: now + 6 min, rewritten every 2 min (`lib/src/voip/group_call_session.dart:213-256`, `utils/voip_constants.dart:58-59`).
  - `isExpired` is true once `expires_ts` is older than now − 6 min (`call_membership.dart:159-166`), and readers keep only `!isExpired` memberships (`group_call_session.dart:275-287`).
- **Delayed leave.** It uses an 18 s delay with a restart every 4 s, and is scheduled before the join write (`famedly_call_extension.dart:199-292`, `voip_constants.dart:64-65`). If the server reports that we left while we are still in the call, the SDK joins again (`group_call_session.dart:326-352`).
- **Per-stream `feeds`.** They are only sent for mesh calls. The LiveKit backend returns `null` (`backend/mesh_backend.dart:1011-1019`, `backend/livekit_backend.dart:551-553`).
- **State plumbing.**
  - `room.states` stores the raw `Event`, content untouched. `Room.setState` emits `client.onRoomState` (`lib/src/room.dart:148-172`, `lib/src/client.dart:1844-1845`) for both the `state` and `timeline` sections of a sync (`client.dart:3130-3145`).
  - `setRoomStateWithKey` is a bare PUT with no local echo (`lib/matrix_api_lite/generated/api.dart:4894-4914`).

### 4. roscord today

- **Join.** `MatrixLivekitBackend.join()` PUTs the membership at `_{mxid}_{device}_m.call` (`commet/lib/client/matrix/components/voip_room/matrix_livekit_backend.dart:169-190`) before `lkRoom.connect` (192).
  - The content has `application`, `call_id: ""`, `device_id`, `expires: 14400000`, `foci_preferred`, `focus_active` (`oldest_membership`) and `scope`.
  - It has no `created_ts`, `membershipID` or `m.call.intent`.
  - The focus lookup sorts memberships by `originServerTs` and accepts only `oldest_membership` (57-102).
  - The membership is never rewritten during a call, so `expires` stays at 4 h from the join. Under js-sdk's expiry rule (section 2), longer calls drop out of other clients' lists.
- **Heartbeat.** The session constructor calls `startHeartbeat()` (`…/voip_room/matrix_livekit_voip_session.dart:66`).
  - If `/versions` advertises `org.matrix.msc4140`, it PUTs `{}` to the same key with `org.matrix.msc4140.delay=30000`, then POSTs `restart` every 25 s (559-592).
  - Failed restarts are not handled: a 404 is ignored and nothing is rescheduled. If the flag is missing, there is no heartbeat at all (562-565).
  - The join is written before the delayed leave exists, which is the reverse of the order in MSC4143-2024:236-246.
  - Synapse advertises the flag only when `max_event_delay_duration` and `max_delayed_events_per_user` are both set, and the first defaults to `null` (SYN `synapse/config/server.py:997-999`, `rust/src/handlers/versions.rs:233-235, 319`, `docs/usage/configuration/config_documentation.md:843-850`).
- **Leave.** `hangUpCall()` runs `clearRoomCallState()` (a PUT of `{}`), `disconnectCall()` and `stopHeartbeat()` (the cancel) concurrently (306-324, 531-557).
- **Local media.** The session already listens for track published, unpublished, muted and unmuted events (39-49, 151-201, 268-292). `isSharingScreen` and `isCameraEnabled` read LiveKit directly (337-346).
- **Reading.** `MatrixActivitiesComponent.getSessions()` walks the call.member state (`commet/lib/client/matrix/components/room_activities/matrix_activities_component.dart:67-140`).
  - It skips entries with empty content, without `application`, or where `originServerTs + expires` has passed.
  - It skips our own device's entry unless `CallManager` has a session for the room.
  - Every other entry adds its `senderId` to `participants`.
  - `MatrixVoipRoomComponent.isMembershipExpired` applies the same expiry rule (`…/voip_room/matrix_voip_room_component.dart:62-73`).
  - `created_ts` is ignored, and there is no expiry timer.
- **Refresh.**
  - `onSessionsChanged` fires only for call.member events in `update.timeline` (`matrix_activities_component.dart:148-159`) and for `CallManager.currentSessions` add/remove (47-63).
  - It does not fire on `session.onStateChanged` or on state-section updates.
  - The event type is in `importantStateEvents` (`commet/lib/client/matrix/matrix_client.dart:341-347`).
- **Rendering.**
  - `RoomActivitySession.participants` is a `Set<String>` (`commet/lib/client/components/activities/activities_component.dart:6-29`).
  - `RoomTextButton` recomputes on `onSessionsChanged` (`commet/lib/ui/atoms/room_text_button.dart:107-113, 139-144`) and draws each member with `buildCallMember`. Today its footer only shows third-party widget icons (330-332, 370-417).
  - Reusable pieces already exist: `TinyPill` (`commet/lib/ui/atoms/tiny_pill.dart:5-30`) and the "LIVE" string `labelLive` (`commet/lib/ui/molecules/call_session_live_panel.dart:30-31`).
- **Other readers** of the membership content only use `device_id`: the E2EE key provider (`…/voip_room/matrix_livekit_encryption_key_provider.dart:153-201`) and the soundboard transport (`commet/lib/client/matrix/components/soundboard/matrix_todevice_soundboard_transport.dart:63-80`). An extra key does not affect them.

### 5. LiveKit side

- **Events (LK 2.7.0).**
  - Remote participants emit `TrackPublishedEvent` and `TrackUnpublishedEvent` (LK `lib/src/events.dart:212-241`).
  - Local and remote participants both emit `TrackMutedEvent` and `TrackUnmutedEvent` (338-366).
  - Leaving emits `ParticipantDisconnectedEvent` (187-197).
  - Track sources include `screenShareVideo` and `camera` (`lib/src/types/other.dart:90-96`).
  - `isScreenShareEnabled()` and `isCameraEnabled()` mean "a publication for that source exists and is not muted" (`lib/src/participant/participant.dart:301-319`).
- **Every change reaches roscord's existing listeners.**
  - Turning screen share off unpublishes the video and its audio track, while turning the camera off only mutes it (`lib/src/participant/local.dart:789-809`).
  - A track stopped from the OS or browser also ends up unpublished: `TrackEndedEvent` → `removePublishedTrack` → `LocalTrackUnpublishedEvent` (local.dart:244-248, 528-532, 588-592).
  - A remote participant who disconnects has all their publications removed, with notifications, first (`lib/src/core/room.dart:945-955`).
  - `MatrixLivekitVoipStream.typeOf` maps `screenShareVideo` to `VoipStreamType.screenshare` (`…/voip_room/matrix_livekit_voip_stream.dart:136-148`).
- **Attributes and metadata are not an alternative.**
  - Setting them requires `canUpdateOwnMetadata` (local.dart:653-677). lk-jwt-service grants it on every token, including legacy `/sfu/get` (LKJWT `src/handler.rs:50-72, 825-860`).
  - LiveKit says they are "stored and managed by the LiveKit server, and are automatically synchronized to new participants who join the room later", with a 64 KiB limit (LKDOCS attributes page).
  - Reading participants from outside the room takes the server-side RoomService API with `roomAdmin` (LKDOCS RoomService page). Attributes are therefore visible only to connected participants.
  - The only way to see attributes or publications without joining is to connect as a lurker, which MSC4195 treats as an attack that clients should flag (MSC4195:716-732).
  - For this feature they add nothing over track publications.
- **Identity mapping.**
  - Legacy tokens use the identity `{mxid}:{device_id}` (LKJWT `handler.rs:848`), which is also how js-sdk maps legacy memberships (JS `CallMembership.ts:94-101`).
  - roscord keeps the first two `:` segments instead (session 126-127, 193-194). That breaks when the server name has a port.
  - In `Matrix_2_0` mode Element Call uses hashed identities (MSC4195:150-165).
  - Members who publish on another SFU (Element Call's `multi_sfu`, JS `MembershipManager.ts:793-802`) never appear in roscord's single LiveKit room.

## Recommendation

### Decision

Implement Option 1, with Option 2 as an overlay on top:

- **(a) Reader and LiveKit overlay.** In-call viewers derive badges from LiveKit. This needs no protocol change and covers members of any client on our SFU.
- **(b) Writer.** `chat.commet.streams` in our own membership covers everyone else.

(a) can ship first as a smaller PR.

### Data shape

```jsonc
// type org.matrix.msc3401.call.member, state_key "_@alice:example.org_DEVICEID_m.call"
{
  "application": "m.call", "call_id": "", "scope": "m.room",
  "device_id": "DEVICEID",
  "focus_active": { "type": "livekit", "focus_selection": "oldest_membership" },
  "foci_preferred": [ /* unchanged */ ],
  "expires": 14400000,               // on rewrite: (now - created_ts) + 4 h
  "created_ts": 1789000000000,       // join time; present on every rewrite
  "m.call.intent": "audio",          // optional: "video" iff camera on
  "chat.commet.streams": ["screen", "camera"]  // subset; [] when nothing is live
}
```

- `chat.commet.streams` is an array of strings. Readers ignore unknown values and treat a non-list value as absent.
- The join write already includes `[]`, so "key present" means "this member reports its streams".
- `screen` → LIVE pill. `camera` without `screen` → camera icon.
- `m.call.intent` comes at no extra cost because it rides the same write. It is what Element clients read (section 2).

### Write path

1. **One pure module**, e.g. `commet/lib/client/matrix/components/voip_room/matrix_call_membership.dart`, with `buildJoinedContent(...)`, `liveStreamsOf(content)`, `joinTimeOf(event)` (`created_ts ?? origin_server_ts`) and `isExpired(event, now)`. `join()` (backend 172-190) and the updater both use it. Its tests can sit next to `commet/unit_test/voice_channel_member_list_test.dart`.
2. **Desired state.** In `MatrixLivekitVoipSession`, compute the desired streams from `localParticipant.isScreenShareEnabled()` and `isCameraEnabled()`. Recompute on `LocalTrackPublished`/`LocalTrackUnpublished` and on `TrackMuted`/`TrackUnmuted` for the local participant, all of which are already wired (39-49). Never use calls to `setScreenShare`/`stopScreenshare` as the trigger, because they miss stops that come from the OS.
3. **Write discipline.**
   - Debounce for about 750 ms (trailing).
   - Skip the write if the value matches the last one written.
   - Keep at least 2 s between writes.
   - Allow one write in flight; the newest value wins.
   - On `M_LIMIT_EXCEEDED`, wait `retry_after_ms` and retry with the newest value.
   - Why: state PUTs share Synapse's `rc_message` budget with chat messages, default 0.2/s with a burst of 10 (SYN config docs 1658-1676, `synapse/handlers/message.py:1067-1087`, `synapse/server.py:1241-1247`). Synapse deduplicates identical content from the same sender (message.py:914-919, 1582-1589).
4. **`created_ts` and `expires`.** Take `created_ts` from `joinTimeOf` of our current event in `room.states`. Set `expires` to `now - created_ts + 4 h`. The same writer can then refresh the membership hourly, as js-sdk does, which fixes the 4 h drop-out.
5. **Heartbeat safety.**
   - Publish a non-empty list only while `heartbeatDelayId != null`.
   - Before each write, POST `restart`. On 404 or 409, schedule a new delayed leave first, then write (MSC4143-2024:236-246; JS `MembershipManager.ts:486-509, 687-724`).
   - Synapse ≥ 1.127 no longer cancels your own delayed state when you overwrite it (SYN `synapse/handlers/delayed_events.py:234-325`; `CHANGES.md` 1.127.0rc1, #17810). Other servers may still behave differently.
6. **Hang-up order.** First stop the updater: cancel the timer, await any in-flight write, and refuse writes once `state != connected`. Only then run the existing clear, disconnect and cancel (session 306-324). Otherwise the `LocalTrackUnpublished` events that `disconnectCall()` fires can schedule a write that lands after `{}`. That write would bring the membership back with no delayed leave, leaving a ghost member for up to 4 h.

### Read path

1. **Model.** Add `Map<String, Set<LiveStream>> liveStreams` to `RoomActivitySession`, holding the union across a user's devices.
2. **`getSessions()`.**
   - For each valid membership that is a full `Event`, add `liveStreamsOf(content)` to `liveStreams[sender]`. Ignore streams on `StrippedStateEvent`, which has no timestamp.
   - Compute expiry as `joinTimeOf + expires`, matching js-sdk and ruma.
3. **LiveKit overlay.** When `getCallInRoom(client, room.identifier)` returns a session, rebuild the sets from `session.streams`: `screenshare` → `screen`, `video` → `camera`, in both directions, including ourselves. These replace the state-derived sets for users present in our LiveKit room. Other users keep the state-derived sets.
4. **Refresh.**
   - In `_watchCallManager`, also subscribe to the room session's `onStateChanged`, and cancel that subscription when the session is removed.
   - Replace the timeline-only `onSync` with `client.onRoomState` filtered by room and type, or also scan `update.state`.
5. **Rendering.** Give `buildCallMember(identifier, liveStreams: …)` the member's set. Draw a red `TinyPill(labelLive)` for `screen` and `Icons.videocam` for camera-only.

### Expiry and crash safety

The LIVE state never gets its own TTL. It lives exactly as long as the membership. A timestamp TTL shorter than the membership would require periodic state writes, costing rate-limit budget and permanent DAG entries (MSC4354:9-16).

| Case | Outside viewers | In-call viewers |
|---|---|---|
| Stream stops | debounce + PUT + `/sync`, about 1-3 s | at once (`TrackUnpublished` / `TrackMuted`) |
| Member hangs up | the existing `{}` write | `ParticipantDisconnected` |
| Crash or network loss, MSC4140 on | server sends `{}` ≤ 30 s after the last restart, plus up to 30 s of allowed server slack (MSC4140:84-85) | when the SFU drops the participant |
| MSC4140 unavailable | never published, so no badge (the membership itself can linger up to 4 h, as today) | LiveKit |

To make crash cleanup take seconds, shorten the heartbeat to about a 10 s delay with a 5 s restart (js-sdk uses 8 s / 5 s). Synapse's default `rc_delayed_event_mgmt` (1/s, burst 5) allows that (SYN config docs 2019-2037). Alternatively, delegate the delayed leave to lk-jwt-service by sending `delay_id` with `/sfu/get` (LKJWT `src/requests.rs:53-68`; MSC4195:423-439).

### Failure modes

- **Rewrite without `created_ts`.** Element Call re-keys on every toggle, and the `oldest_membership` order changes. Always send `created_ts`. roscord's own `findSelectedFocus` should also sort by `joinTimeOf`.
- **Write after the delayed leave already fired** (e.g. after laptop sleep). The membership comes back with no dead man's switch. Step 5 of the write path covers this. Separately, like the Dart SDK, roscord should rejoin when it sees its own membership become `{}` while it is still connected.
- **Two roscord writers on one key.** Last write wins. All writes must go through the one builder and one queue. Two existing actions also write `{}` to our own keys and should skip the key of an active session:
  - the always-visible "Clear Memberships" context-menu item (`room_text_button.dart:289-296` → `matrix_activities_component.dart:161-183`);
  - the developer-mode "Clear Membership Status" item (`room_text_button.dart:75-80` → `matrix_voip_room_component.dart:175-194`).
- **Limited sync.** The state change arrives outside the timeline, so the badge sticks until the next event. `onRoomState` fixes this.
- **Privacy.** State events are never end-to-end encrypted, so every room member and every server in the room learns who is live. Offer a setting to opt out of publishing, as MSC4196 does for `intent`.
- **Older roscord builds and other clients** ignore the key. They show no badge, and nothing breaks.

## Open questions

- **Namespace.** Upstream Commet could define `chat.commet.streams` differently. Should we use `chat.commet.streams.v1` or a PondLabs-owned namespace? roscord already uses `chat.commet.voice_state.v1`.
- **Default and extra badges.** Should publishing default to on? Should `m.call.intent == "video"` from non-roscord members show the camera icon?
- **Heartbeat.** Should it move to 10 s / 5 s or to lk-jwt-service delegation?
- **Scope.** Should the hourly `expires` refresh and rejoin-after-leave be part of this issue or separate ones?
- **MSC4143 migration.** Once roscord moves to sticky `m.rtc.member`, the field belongs inside `application` and gets encrypted in E2EE rooms. roscord does not read sticky memberships today, so Element Call users in `Matrix_2_0` mode are already missing from the sidebar.
- **Members on other SFUs** (`multi_sfu`) and hashed LiveKit identities cannot be covered by the in-call overlay. Is falling back to state enough for them?

## Outcome (implemented for #9)

Both parts of the recommendation were implemented, with these choices for the open questions:

- **Key name.** `chat.commet.streams`, as in the issue. The join write lists `[]`.
- **Publishing.** On by default, with no setting yet. Nothing is published unless the delayed leave is armed (`heartbeatDelayId`), and a failed heartbeat restart retracts the list.
- **Writes.** `LiveMediaPublisher` debounces for 750 ms, keeps at least 2 s between writes (doubling after failures, up to 1 min), sends one write at a time with the newest value, and skips unchanged values. `hangUpCall` stops it before clearing the membership.
- **Rewrites.** `MatrixCallMembership.withLiveMedia` keeps every other key, sets `created_ts` to the join time, and moves `expires` 4 h past now. roscord's readers now count expiry from `created_ts ?? origin_server_ts`, and `findSelectedFocus` sorts by join time.
- **Reading.** Streams count only from full events. For members in our own LiveKit room, LiveKit replaces what their membership says. The list refreshes on our call's `onStateChanged` and on call.member events in the sync `state` section.
- **Not done.** `m.call.intent`, the hourly `expires` refresh on its own, rescheduling a lost delayed leave (and rejoining), the shorter 10 s / 5 s heartbeat, keeping the "Clear Memberships" actions away from an active session's key, and reading sticky `m.rtc.member` events.
