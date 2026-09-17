# Issue #10: own user missing from the sidebar voice member list

Research against the source tree at the time of writing (branch
`t3code/solve-github-issue-ten`, HEAD `906de7c1`). All paths are relative to
the repo root; line numbers refer to the current files.

## Summary

The issue's diagnosis is correct in every particular. The stale-membership
filter added in `37ab8327` decides whether our own `call.member` state event is
real by asking `CallManager.getCallInRoom(...)`. That call only returns a
session after `MatrixLivekitVoipSession`'s constructor runs, which happens
after `lkRoom.connect()` completes. Our own membership state event is PUT to
the homeserver *before* `connect()`, and the sync that echoes it back is the
only thing that ever fires `ActivitiesComponent.onSessionsChanged`. When that
sync lands during the connect window (the common case: connect involves a
WebSocket handshake plus SFU negotiation, while `/sync` is long-polling
continuously), `RoomTextButton` rebuilds its list from `getSessions()` at a
moment when `getCallInRoom` is still `null`, drops our entry as a "leftover",
and nothing ever re-runs the check. No later event (heartbeat, LiveKit
connection, `CallManager.currentSessions.onAdd`) reaches `RoomTextButton`.

The same race exists, independently, in
`MatrixVoipRoomComponent.getCurrentParticipants()` (used by `VoipRoomView`),
which gates on `currentSession != null`, a field assigned only after
`backend.join()` returns.

## Claims: confirmed / refuted

| # | Claim from the issue | Verdict | Evidence |
|---|---|---|---|
| 1 | Sidebar shows others but not us after joining | Confirmed (by code path) | `commet/lib/ui/atoms/room_text_button.dart:126-131` rebuilds from `getSessions()`; filter at `matrix_activities_component.dart:66-73` drops our entry when no session is registered. |
| 2 | Race with the stale filter from `37ab8327` | Confirmed | `git show 37ab8327 -- commet/lib/client/matrix/components/room_activities/matrix_activities_component.dart` adds exactly lines 63-73 (the `getCallInRoom(...) == null` test). |
| 3 | `MatrixLivekitBackend.join()` writes `call.member` first | Confirmed | `commet/lib/client/matrix/components/voip_room/matrix_livekit_backend.dart:172-190` (`setRoomStateWithKey`), then `:192` (`lkRoom.connect`), then `:213` (`MatrixLivekitVoipSession(...)`). |
| 4 | Session is registered with CallManager only in the session constructor | Confirmed | `commet/lib/client/matrix/components/voip_room/matrix_livekit_voip_session.dart:35-36`: `clientManager?.callManager.onClientSessionStarted(this)` is the first line of the constructor. `CallManager.onClientSessionStarted` adds to `currentSessions` at `commet/lib/client/call_manager.dart:64-66`. |
| 5 | If sync arrives in between, `getSessions()` skips our membership | Confirmed | `matrix_activities_component.dart:66-73`. `getCallInRoom` (`call_manager.dart:121-126`) searches `currentSessions`, empty until step 4. |
| 6 | `onSessionsChanged` fires only for `call.member` timeline events in sync | Confirmed | `matrix_activities_component.dart:111-122` (`onSync`), driven from `commet/lib/client/matrix/matrix_client.dart:287-288, 314-327`. There is no other `_onParticipantsChanged.add` call site. |
| 7 | `RoomTextButton` does not listen to `CallManager` | Confirmed | `room_text_button.dart:94-100` subscribes only to `room.onUpdate`, `CalendarRoom.onEventsChanged` and `ActivitiesComponent.onSessionsChanged`. No import of `call_manager.dart`. |
| 8 | Nothing re-checks the list after the session is registered | Confirmed | `room.onUpdate` triggers `setState` only (`:155-157`) without recomputing `activitySessions`. Heartbeat (`matrix_livekit_voip_session.dart:586-591`) only restarts an MSC4140 delayed event and never writes a timeline state event. |

Additional finding not in the issue: the SDK's `setRoomStateWithKey` is a bare
HTTP PUT with no local echo into `room.states`
(`~/.pub-cache/git/matrix-dart-sdk-58e0bd24.../lib/matrix_api_lite/generated/api.dart:4894-4914`).
`room.states` is only updated from `/sync` via `room.setState(event)`
(`.../lib/src/client.dart:3140-3145`) and `onSync.add(sync)` is emitted
afterwards (`:2609`). So the sync is guaranteed to carry our state and to
trigger `onSessionsChanged` exactly once; the question is only *when* relative
to `connect()`.

## Code walkthrough

### `MatrixActivitiesComponent` (`commet/lib/client/matrix/components/room_activities/matrix_activities_component.dart`)

- Constructed per room by the registry at
  `commet/lib/client/components/component_registry.dart:93` with
  `(MatrixClient, MatrixRoom)`. It implements `ActivitiesComponent` and
  `MatrixRoomSyncListener` (`:16-19`).
- `getSessions()` (`:33-106`) iterates `room.matrixRoom.states["org.matrix.msc3401.call.member"]`,
  groups entries by `application`, skips empty content, skips entries whose
  `expires` window has elapsed (`:49-61`), and, since `37ab8327`, skips our own
  device's `m.call` membership when
  `clientManager?.callManager.getCallInRoom(client, room.identifier) == null`
  (`:66-73`). It reads the global `clientManager` from
  `commet/lib/main.dart:65`.
- `onSessionsChanged` (`:109`) is `_onParticipantsChanged.stream`, fed only by
  `onSync` (`:112-122`), which fires once per `call.member` event found in
  `update.timeline.events`.
- `onSync` is reached from `MatrixClient.onMatrixClientSync`
  (`matrix_client.dart:287-293`) -> `_handleComponentSync` (`:314-327`), which
  runs after the SDK has already applied the state.

Intent of the filter (`git show 37ab8327`): the commit is a large vendoring
commit ("Add Windows WASAPI Loopback Audio Capturer Implementation") that
also adds the 13-line filter with the comment "A call membership written by
this device is only real while this device is actually in the call;
otherwise it is a leftover from a previous run that was closed without
hanging up." The same commit adds the parallel `_hasActiveSession` filter to
`MatrixVoipRoomComponent.getCurrentParticipants` (`matrix_voip_room_component.dart:52-53, 92-97`).
The goal is to hide leftovers from a crashed/closed run, not to hide a
membership that is in the middle of being established.

### Join ordering (`matrix_livekit_backend.dart:104-214`)

1. `:107` fetch foci, `:116` OpenID token, `:136` POST `/sfu/get`.
2. `:166-168` create `lk.Room`, `prepareConnection`.
3. `:172-190` **PUT our `call.member` state event** (`expires: 14400000`,
   `device_id`, `focus_active`, ...).
4. `:192` `await lkRoom.connect(sfuUrl, jwt)` (network round trips).
5. `:194-210` enable microphone.
6. `:213` `return MatrixLivekitVoipSession(room, lkRoom, ...)` -> constructor
   `:35-36` registers with `CallManager`.
7. Back in `MatrixVoipRoomComponent.joinCall` (`matrix_voip_room_component.dart:149-153`)
   `currentSession` is assigned only after `await backend.join()`.

### `CallManager` (`commet/lib/client/call_manager.dart`)

- `currentSessions` is a `NotifyingList<VoipSession>` (`:38-39`) with
  synchronous broadcast streams `onAdd`, `onRemove`, `onListUpdated`
  (`commet/lib/utils/notifying_list.dart:28-36, 90-93`).
- `onClientSessionStarted` (`:64-104`) does `currentSessions.add(event)`.
  It is called directly by the LiveKit session constructor; the
  `VoipComponent.onSessionStarted` stream subscribed at `:58` only carries
  legacy 1:1 `MatrixVoipSession`s (`matrix_voip_component.dart:183-191`).
- `onSessionEnded` (`:106-119`) removes by `sessionId`; called from
  `MatrixLivekitVoipSession.hangUpCall` (`:323`).
- `getCallInRoom(client, roomId)` (`:121-126`) = first session with matching
  client and room.
- There is no `onSessionStarted` emission for LiveKit sessions on
  `CallManager._onSessionStarted` (`:20-21, 36`); it is declared but never
  `.add`ed anywhere in this file. `currentSessions.onAdd/onRemove` are the
  usable signals.

### `RoomTextButton` (`commet/lib/ui/atoms/room_text_button.dart`)

- Rendered per room by the sidebar (`commet/lib/ui/atoms/space_list.dart:140, 206`).
- `initState` (`:90-124`): subscribes to `room.onUpdate`,
  `calendarRoom.onEventsChanged`, `activities.onSessionsChanged`; computes
  `activitySessions = activities.getSessions()` once.
- `onSessionsChanged` (`:126-131`) recomputes and `setState`s.
- `onRoomUpdate` (`:155-157`) only `setState`s; it does not recompute.
- `buildActivities`/`buildActivity`/`buildCallMember` (`:247-404`) render
  `activity.participants`.

### Interfaces

- `ActivitiesComponent` (`commet/lib/client/components/activities/activities_component.dart:31-38`):
  `List<RoomActivitySession> getSessions()`, `Stream<void> get onSessionsChanged`,
  `Future<void> clearMemberships(RoomActivitySession)`.
- `RoomActivitySession` (`:6-29`): `Set<String> participants`, `application`,
  `thirdparty`, `icon`, `associatedWidget`, `knownName`.
- `VoipRoomComponent` (`commet/lib/client/components/voip_room/voip_room_component.dart:5-25`):
  `getCurrentParticipants()`, `onParticipantsChanged`, `currentSession`,
  `joinCall()`, `clearStaleOwnMembership()`.
- `VoipSession` (`commet/lib/client/components/voip/voip_session.dart:32-80`):
  `client`, `roomId`, `state`, `onStateChanged`, `onConnectionStateChanged`, ...

## Sequence of the race (text diagram)

```
User            VoipRoomView        MatrixVoipRoomComponent   MatrixLivekitBackend       Homeserver /sync      MatrixClient          MatrixActivitiesComponent   RoomTextButton        CallManager
 |  click join       |                        |                        |                      |                     |                          |                      |                   |
 |------------------>| joinRoomCall()         |                        |                      |                     |                          |                      |                   |
 |                   |--- joinCall() -------->|--- join() ------------>|                      |                     |                          |                      |                   |
 |                   |                        |                        | PUT call.member ---->|                     |                          |                      |                   |
 |                   |                        |                        |<-- 200 event_id -----|                     |                          |                      |                   |
 |                   |                        |                        | await lkRoom.connect() ... (WS handshake, hundreds of ms)             |                      |                   |
 |                   |                        |                        |                      |-- sync w/ our call.member in timeline -------->|                      |                   |
 |                   |                        |                        |                      |                     | SDK: room.setState(ev)   |                      |                   |
 |                   |                        |                        |                      |                     | onSync -> _handleComponentSync                  |                   |
 |                   |                        |                        |                      |                     |--- onSync(update) ------>|                      |                   |
 |                   |                        |                        |                      |                     |                          |-- onSessionsChanged ->|                   |
 |                   |                        |                        |                      |                     |                          |<-- getSessions() -----|                   |
 |                   |                        |                        |                      |                     |                          |--- getCallInRoom() ------------------------>|
 |                   |                        |                        |                      |                     |                          |<-- null (currentSessions empty) ------------|
 |                   |                        |                        |                      |                     |  own entry SKIPPED       |  list = others only  |                   |
 |                   |                        |                        | connect() resolves   |                     |                          |                      |                   |
 |                   |                        |                        | new MatrixLivekitVoipSession() ----------------------------------------------------------------------------------->| currentSessions.add
 |                   |                        |<-- session ------------|                      |                     |                          |                      |                   |
 |                   |<-- session ------------| currentSession = s     |                      |                     |                          |                      |                   |
 |                   | setState (call UI)     |                        |                      |                     |  (no further event)      |  STILL others only   |                   |
```

If the sync instead lands after `connect()` resolves (slow homeserver, fast
SFU), `getCallInRoom` is non-null and we appear. The bug is therefore timing
dependent but common.

## Candidate fixes

### A. Make `MatrixActivitiesComponent` (and `RoomTextButton`) also react to `CallManager.currentSessions`

Subscribe in the component to `clientManager!.callManager.currentSessions.onListUpdated`
(or `onAdd`/`onRemove`) and forward to `_onParticipantsChanged` when the
added/removed session belongs to this room. `RoomTextButton` then recomputes
via its existing `onSessionsChanged` subscription.

- Pros: smallest change; keeps the filter's semantics exactly (state is the
  source of truth, session presence is a gate) and also fixes the mirror
  problem on hang-up (our entry would otherwise remain until the sync with the
  cleared state arrives). Fixes the sidebar for any future path that registers
  a session.
- Cons: the component now depends on the global `clientManager` for a stream,
  not just a lookup; need care that `clientManager` may be null at construction
  time in background-service mode (`main.dart:65`, `ClientManager.init(isBackgroundService:)`),
  and the per-room subscription must be cancelled (no `dispose` exists on
  `RoomComponent` today; check `commet/lib/client/components/room_component.dart`).
- Test: unit test with a `ClientManager()` + real `CallManager` (as
  `commet/unit_test/deafen_test.dart:213-216` does) and a `FakeVoipSession`
  whose `client`/`roomId` match; assert `onSessionsChanged` emits when
  `callManager.onClientSessionStarted(fake)` is called. This needs the
  component to accept the `CallManager` via constructor/injection (see D)
  because it reads the global today.

### B. Move the "leftover" decision out of the read path: gate on `MatrixVoipRoomComponent` join intent

Add a `joining`/`pendingOwnMembership` flag (or an in-flight `Future`) on
`MatrixVoipRoomComponent`, set before `backend.join()` and cleared when it
completes, and have both filters treat "session present OR join in flight"
as "we are in the call". `MatrixActivitiesComponent` can reach it via
`room.getComponent<VoipRoomComponent>()`.

- Pros: fixes both `getSessions()` and `getCurrentParticipants()` in one
  concept; no new streams.
- Cons: still needs a notification to `RoomTextButton` when the join completes
  or fails (otherwise a failed join leaves a phantom entry until the next
  `call.member` sync), so it ends up needing A's stream anyway. Adds state to
  the interface.
- Test: unit test of `getSessions()` with a fake `VoipRoomComponent` reporting
  `joinInFlight = true` and no CallManager session.

### C. Reorder `join()`: register the session (or write the state event) so the state never precedes the session

E.g. write the `call.member` state event *after* `lkRoom.connect()` and after
constructing the session, or construct the session object before writing state.

- Pros: eliminates the window at the source.
- Cons: the ordering is deliberate for MatrixRTC focus selection
  (`findSelectedFocus` reads `focus_active` from existing memberships,
  `:57-102`); other clients rely on seeing the membership early; constructing
  the session before `connect()` breaks `addInitialStreams()` and
  `keyProvider.init(livekitRoom.localParticipant!...)` (`:64`, non-null
  assertion on `localParticipant`). Also does not fix the hang-up mirror case.
  Riskiest option.
- Test: only integration (synapse + LiveKit), see `commet/integration_test/`.

### D. Make the component testable: inject the `CallManager` lookup

Regardless of A/B, replace the direct `clientManager?.callManager` read at
`matrix_activities_component.dart:70` with an injectable
`VoipSession? Function(String roomId)` or a `CallManager?` parameter defaulting
to the global. `component_registry.dart:93` keeps constructing it as today.

- Pros: unlocks unit tests for `getSessions()` without booting
  `ClientManager.init()` (which needs preferences/database).
- Cons: `getSessions()` still needs a `MatrixRoom` with `room.matrixRoom.states`
  populated; `MatrixRoom` wraps an SDK `Room`, so a test needs either a real
  SDK `Client` with a fake database (the SDK ships `FakeMatrixApi` /
  `getClient()` helpers under its `test/` dir but they are not exported) or a
  refactor that extracts the pure filtering into a static function taking
  `Iterable<StrippedStateEvent>`, `selfId`, `deviceId`, `hasSession`. The
  latter is the practical route.

## Existing test infrastructure

- Unit tests live in `commet/unit_test/`; the ones touching this area are
  `deafen_test.dart` (builds `ClientManager()` and `CallManager(clientManager)`
  directly, uses a `FakeVoipSession implements VoipSession` with
  `noSuchMethod`, `:11-88, 211-216`) and `screen_share_audio_test.dart`
  (widget tests with `createTestApp`). No test references
  `MatrixActivitiesComponent`, `RoomTextButton`, `getSessions` or
  `onSessionsChanged`.
- `ClientManager()` has a no-arg constructor that creates its `CallManager`
  (`commet/lib/client/client_manager.dart:26-28`), so a `CallManager` is cheap
  to build in a test. `CallManager.onClientSessionStarted` calls
  `event.client.getRoom(...)`, `AudioProcessingManager.instance`, and
  `event.onConnectionStateChanged.listen`, so a fake session must implement
  `client`, `roomId`, `state`, `sessionId`, `onConnectionStateChanged`
  (the deafen test avoids this by adding to `currentSessions` directly, which
  is also what a test for A can do since `NotifyingList.add` fires `onAdd`
  synchronously, `notifying_list.dart:118-121`).
- Integration tests (`commet/integration_test/matrix/*`) drive a real synapse;
  none cover voice rooms.
- `MatrixActivitiesComponent` cannot currently be unit-tested end to end
  because `getSessions()` needs an SDK-backed `MatrixRoom` and the global
  `clientManager`.

## Recommended approach

Do A + D together, and apply the same stream to `MatrixVoipRoomComponent`:

1. Extract the pure membership filter from `getSessions()` into a function
   (e.g. `static bool isLiveMembership(StrippedStateEvent, {required String? selfId, required String? deviceId, required bool hasOwnSession})`)
   shared with `MatrixVoipRoomComponent.getCurrentParticipants`, which already
   has `isMembershipExpired` and `_isOwnDeviceMembership` helpers
   (`matrix_voip_room_component.dart:55-73`). Unit-test it with hand-built
   `StrippedStateEvent`s (no SDK client needed).
2. In `MatrixActivitiesComponent`, subscribe to
   `clientManager?.callManager.currentSessions.onListUpdated` (guarded for a
   null `clientManager`), and re-emit on `_onParticipantsChanged` when any
   added/removed session's `roomId == room.identifier` (use `onAdd`/`onRemove`
   for the room check). Do the same in `MatrixVoipRoomComponent` for
   `onParticipantsChanged` so `VoipRoomView` is fixed too. Inject the
   `CallManager` (constructor parameter with default to the global) so a test
   can drive it with `ClientManager()`'s `CallManager` and a
   `FakeVoipSession` added to `currentSessions`.
3. Leave `join()` ordering alone (option C rejected for the reasons above).

This removes the race for both list consumers, covers the symmetric hang-up
case, is testable with the existing `deafen_test.dart` pattern, and does not
touch the vendored SDKs.
