# Issue #16: soundboard emoji picker (research)

This is research for replacing the free-text emoji field in the Space
soundboard settings with the app's emoticon picker, so admins can pick custom
Space emoji (mxc). Everything here was read from the source. Paths are
relative to `commet/` unless they start with `tiamat/` or `docs/`.

## 1. `SoundboardSound` model and storage

- Class: `lib/client/components/soundboard/soundboard_sound.dart:11`. Fields:
  `soundId` (:13), `name` (:16), `emoji` (a required non-null `String`, :19),
  `sourceUrl?` (:22), `mediaUri` (:26), `mimeType` (:29), `durationMs` (:32),
  `normalizedGain` (:37) and `version` (defaults to 1, :40, :51).
- `toJson()` (:54-66) always writes `'emoji': emoji` (:57). The gain is
  stored as the integer `normalized_gain_milli` because event content must be
  canonical JSON, which has no floats (:62-64). Any new field must be a string
  or an int.
- `fromJson()` (:68-80) does `json['emoji'] as String` (:72), which **throws**
  when the key is missing. The model has no tolerant parsing for this field.
- `copyWith` (:90-109) accepts `emoji` (:92, :101). `version` is always
  copied through unchanged (:107).
- The file is pure Dart (no Flutter import), and the unit tests rely on that.
  Keep `ImageProvider` out of the model.
- Storage: there is one Matrix **state event per sound**. The type is
  `chat.commet.soundboard.sound` (`soundboard_component.dart:11`) and the
  state_key is the soundId
  (`lib/client/matrix/components/soundboard/matrix_space_soundboard_component.dart:1-9`).
  The content is exactly `sound.toJson()` (:113-118 for add, :136-141 for
  update). Empty content `{}` marks a removed sound (:52, :149-154).
- Reads come from `matrixRoom.states[...]` (:43-66). `fromJson` runs inside a
  `try/catch` that **silently skips** malformed sounds (:53-59). So if an old
  client reads a sound that has no `emoji` key, the sound disappears from that
  client's list without any error.
- The abstract API is `SpaceSoundboardComponent.addSound({required String
  emoji, ...})` (`soundboard_component.dart:22-30`) and
  `updateSound(id, {String? name, String? emoji})` (:32-36).
- The Matrix implementation calls `SoundboardValidator.sanitizeEmoji`
  in `addSound` (:99) and in `updateSound` (:134). This is the
  enforcement point, so a new custom-emoji path has to change it as well
  as the UI.

### Every consumer of `.emoji`

| Location | Use |
|---|---|
| `soundboard_sound.dart:57,72,101` | serialisation / copy |
| `matrix_space_soundboard_component.dart:99,106,134` | validate + persist |
| `lib/ui/pages/settings/categories/space/space_soundboard_settings_page.dart:118,126,154,176,228,254` | list row `Text`, edit dialog, add form |
| `lib/ui/organisms/soundboard/soundboard_panel.dart:93` | `Text(s.name.isEmpty ? '' : s.emoji, fontSize 22)` |
| `lib/ui/organisms/soundboard/soundboard_call_controller.dart:145` | `emoji: sound.emoji` passed to the overlay registry |
| `lib/ui/organisms/soundboard/soundboard_overlay_registry.dart:10,16,42,47` | `SoundboardOverlayEntry.emoji` (String) |
| `lib/ui/organisms/call_view/voip_stream_view.dart:202` | `emoji: entry.emoji` passed to the overlay widget |
| `lib/ui/organisms/soundboard/soundboard_emoji_overlay.dart:10,16,96` | `Text(widget.emoji, fontSize 34)` |
| `unit_test/soundboard/soundboard_core_test.dart:13`, `unit_test/soundboard/soundboard_session_test.dart:42` | test fixtures |

## 2. `SoundboardValidator` and its tests

- `lib/client/components/soundboard/soundboard_validation.dart`:
  - `SoundboardValidationError` has a `message` field (:4-9). The settings
    page shows that message to the admin (`space_soundboard_settings_page.dart:266`).
  - `sanitizeName` (:14-29) trims the name, collapses whitespace, strips
    control characters, enforces a length of 1..64 runes and rejects `<` and
    `>`.
  - `sanitizeEmoji` (:39-54) trims the input, rejects empty input and
    whitespace, and requires exactly one cluster from `_splitGraphemes`
    (:56-121, a hand-written approximation without ICU). It also requires
    `_containsEmoji` (:123-128), which checks the codepoints against the
    ranges in `_isEmojiCodepoint` (:130-147).
  - That range check also accepts the ASCII digits `0x30-0x39` (:146). As a
    result, `sanitizeEmoji("5")` passes today.
  - Error messages: "Emoji must be a single emoji" (:42, :48) and
    "Not an emoji" (:51).
- Tests: `unit_test/soundboard/soundboard_core_test.dart`. They use
  `package:test/test.dart` (:7) with `group`/`test`/`expect` and
  `throwsA(isA<SoundboardValidationError>())`. A shared `_sound(id)` fixture
  builds sounds with `emoji: '📢'` (:9-18).
  - The validator group is at :136-163. The emoji test at :151-162 accepts
    📢, a ZWJ family, a skin tone and a flag, and rejects `😂😂` and `abc`.
  - The state-event content group at :69-93 has a `leaves()` helper that
    asserts the JSON contains no doubles (:76-80). It also has the
    backward-compatibility test "still reads the float gain of earlier
    builds" (:87-92). A tolerant-`fromJson` test fits naturally in this
    group.
- Other files in `unit_test/soundboard/`: `soundboard_engine_test.dart`,
  `soundboard_session_test.dart`, `soundboard_normalizer_test.dart`,
  `myinstants_resolver_test.dart`, `mediakit_soundboard_player_test.dart`
  and `mp3_duration_test.dart`.

## 3. Settings page (`space_soundboard_settings_page.dart`)

- The widget only receives `SpaceSoundboardComponent soundboard` (:22-24). It
  gets no `Space` and no `Client`. The page casts the component to
  `MatrixSpaceSoundboardComponent` to reach `.client.getMatrixClient()`
  (:167-169, :203-206).
- The Space is reachable through `widget.soundboard.space`, because
  `SpaceComponent` exposes `space` (`lib/client/components/space_component.dart:7`).
- The page is built in
  `lib/ui/pages/settings/categories/space/settings_category_space.dart:119`.
  The `space` and `SpaceEmoticonComponent? emoticons` values are already in
  scope there (:73-75), so they could be passed down as well.
- **Add form**:
  - State: `_emojiCtrl` (:35, disposed at :45).
  - UI: a Row with the Name `TextInput` and a 110 px wide Emoji
    `tiamat.TextInput` with placeholder 📢 (:75-94).
  - Submit: `_addSound` (:145-198) validates first with
    `sanitizeEmoji(_emojiCtrl.text)` (:154). It then imports from MyInstants,
    uploads the audio with `mx.uploadContent` (:170-171) and calls
    `addSound(name:, emoji:, mediaUri:, ...)` (:174-182). On success it
    clears the fields (:184-186).
  - Errors are shown in `_error` through `_friendlyError` (:187-197,
    :263-278).
- **Sound list row**: `Text(s.emoji, fontSize 22)` (:118-119). The edit button
  calls `_editDialog(s.soundId, s.name, s.emoji)` (:122-127).
- **Edit dialog**:
  - `_editDialog` (:225-261) opens a Material `AlertDialog`. It creates its own
    `TextEditingController(text: emoji)` (:228) and shows
    `tiamat.TextInput(label: 'Emoji')` (:238).
  - Save calls `updateSound(soundId, name: nameCtrl.text, emoji:
    emojiCtrl.text)` (:253-254). The emoji value is sent even when it has not
    changed, so validation runs on every save.
  - Consequence: once a stored value is a custom emoji, the dialog must not
    send a unicode string for it.
- Live refresh: `_RebuildOnChange` wraps `onChanged` as a `Listenable`
  (:282-294).

## 4. Soundboard panel and avatar overlay

- The panel (`soundboard_panel.dart`) takes only `catalog`, `session`,
  `volume01` and `onVolumeChanged` (:12-24). It has **no client**, so it
  cannot build a `MatrixMxcImage` for a custom emoji.
- In the panel, each row renders the emoji with `Text(...)` at :93-94. The
  panel is opened from `call_view.dart:247-265` with `showDialog` +
  `Dialog`, and `SoundboardCallController` supplies `ctrl.catalog`.
- The controller has `session` (a `VoipSession`, :28) and reaches the client
  with `session.client` (:113). It also finds the `SpaceSoundboardComponent`
  by scanning `client.spaces` (:71-75).
- The overlay is driven locally. The wire event carries **no emoji**:
  - `SoundboardEvent` has only `type`, `version`, `sound_id`, `sender_id`,
    `event_id` and `timestamp` (`soundboard_event.dart:18-41`). It is sent over
    the LiveKit data channel, with Matrix to-device as a fallback (:3-4).
  - The receiver resolves `soundId` against its own catalog. Then
    `SoundboardCallController._syncOverlays` (:135-155) calls
    `SoundboardOverlayRegistry.instance.show(userId, soundId, emoji:
    sound.emoji, overlayMs)` (:142-147).
  - **So the protocol needs no change.** Only the local representation
    (registry entry and overlay widget) has to change.
- `SoundboardOverlayEntry` (`soundboard_overlay_registry.dart:8-20`) is a
  process-wide singleton map keyed by userId (:22-27, :39-53).
- `voip_stream_view.dart:185-210` stacks a `ListenableBuilder` over the
  avatar and builds `SoundboardEmojiOverlay(emoji: entry.emoji, durationMs:
  entry.overlayMs)` (:199-203).
- `SoundboardEmojiOverlay` (`soundboard_emoji_overlay.dart:9-20`) animates
  scale and opacity (:35-66). It renders a circle-shadowed
  `Text(widget.emoji, fontSize: 34)` (:84-98) inside an `IgnorePointer`.
  A custom emoji needs an image at about 34 to 40 px in this spot.

## 5. `EmoticonPicker` / `EmojiPicker`

- `EmoticonPicker` (`lib/ui/molecules/emoticon_picker.dart:16-47`):
  - Params: `required List<EmoticonPack> emoji`,
    `required List<EmoticonPack> stickers`, `allowGifSearch=false`,
    `onEmojiPressed`, `onStickerPressed` (both
    `void Function(Emoticon)`), `onGifPressed`, `onFavoritePicked`,
    `gifComponent`, three focus nodes, `searchDelegate` and
    `packListAxis`.
  - The tab count is 1 + (stickers non-empty) + (gif) (:73-84). If
    `stickers: []` and gifs are off, only the emoji tab exists and there is no
    tab bar (:157).
  - **Gotcha:** the emoji tab always passes the closure
    `(value) => widget.searchDelegate!.call(value)...` (:117-120). That
    closure is non-null even when `searchDelegate` is null, so a search
    **crashes** unless you supply one. The results are filtered to
    `i.emoticon.isEmoji` (:119).
  - Layout: `Column(mainAxisSize.min)` with an `Expanded` `TabBarView`
    (:108-112). It **requires a bounded height** from its parent.
- `EmojiPicker` (`lib/ui/molecules/emoji_picker.dart:12-36`):
  - Params: positional `packs`, `size` (42 on desktop, 48 on mobile),
    `onEmoticonPressed(Emoticon)`, `packButtonSize`, `onlyEmoji`,
    `onlyStickers`, `staggered`, `searchDelegate`, `focus`,
    `preferredTooltipDirection` and `packListAxis`.
  - `onlyEmoji` makes it use `pack.emoji` (:63-73). It shows a search bar
    only when `searchDelegate != null` (:221). It builds a sliver grid per
    pack (:265-288).
  - Each cell is an `InkWell` that calls `onEmoticonPressed(emoticon)`
    (:294-308) and renders it with `EmojiWidget`.
  - It can be used directly and more simply: a nullable `searchDelegate`
    here really does hide the search bar.
- The callback type is `Emoticon` (the abstract class, see §6). To tell the
  two kinds apart, use `emoticon is MatrixEmoticon` (custom, has
  `emojiUrl`) or `emoticon is UnicodeEmoticon` (`slug` is the character).
- `EmojiWidget` (`lib/ui/atoms/emoji_widget.dart:6-47`) renders
  `emoji.image` with `FadeInImage` when it is non-null (:20-33). Otherwise it
  shows `Text(emoji.slug)` in a `FittedBox` (:34-45). It can be reused
  anywhere you have an `Emoticon`.
- Hosting in `message_input.dart`:
  - `buildEmojiPicker` (:1071-1120) prepends a "Frequently Used"
    `DynamicEmoticonPack` (:1078-1087). It passes
    `emoji: widget.availibleEmoticons` (the room's
    `RoomEmoticonComponent.availableEmoji`) and
    `searchDelegate: AutofillUtils.searchEmoticon(search, client:, room:,
    limit: 50).whereType<AutofillSearchResultEmoticon>()` (:1096-1099).
    `onEmojiPressed` is `insertEmoticon` (:1101), which inserts
    `emote.slug` (:1240-1275).
  - Popover on desktop: `JustTheTooltip(isModal: true, preferredDirection:
    AxisDirection.up, controller: JustTheController, backgroundColor:
    surfaceContainerLow, content: ClipRRect(radius 8) > Material >
    SizedBox(500x500) > picker)` (:988-1014). The controller is created at
    :163 and opened with `emojiTooltipController.showTooltip(autoClose:
    false)` (:377). `just_the_tooltip` is imported at :35.
  - On mobile it is an inline panel instead (:986, :1067-1069).
- `AutofillUtils.searchEmoticon(string, {limit, required Client client, Room?
  room, threshold})` (`lib/utils/autofill_utils.dart:115-127`). With
  `room == null` it searches the **client-level**
  `EmoticonComponent.availablePacks`, not the Space's packs. A soundboard
  picker needs its own delegate, or it must pass a room.

## 6. Emoticon model and components

- `Emoticon` (`lib/client/components/emoticon/emoticon.dart:11-24`) exposes
  `ImageProvider? image`, `String slug`, `String? shortcode`, `String key` and
  `EmoticonUsage usage`, plus `isSticker` and `isEmoji`.
- `MatrixEmoticon` (`lib/client/matrix/components/emoticon/matrix_emoticon.dart:7-78`):
  - `Uri emojiUrl` (:19) is the **mxc URI**. `key` returns
    `emojiUrl.toString()` (:47).
  - `shortcode` is the **bare** name without colons (:17, :30), taken from
    the pack's `images` map key. `slug` returns `":${shortcode!}:"`
    **with** colons (:11). So for the issue's `":velho:"`, store
    `emoticon.slug`.
  - `image` is a `MatrixMxcImage(emojiUrl, client, fullResHeight: 100,
    doThumbnail: false, doFullres: true, autoLoadFullRes: true)` (:31-35).
    Use the same arguments to rebuild the image from a stored mxc.
  - `isEmoji` honours the `inherit` pack usage (:72-77).
- `MatrixMxcImage(Uri identifier, matrix.Client client, {blurhash,
  doThumbnail, doFullres, cache, autoLoadFullRes, thumbnailHeight,
  fullResHeight, matrixEvent})` extends `LODImageProvider`
  (`lib/client/matrix/matrix_mxc_image_provider.dart:11-26`). It needs a
  `matrix.Client`, which you get from `MatrixClient.getMatrixClient()`.
- `UnicodeEmoticon` (`lib/utils/emoji/unicode_emoji.dart:225-249`): `slug` is
  the emoji character and is also the `key` (:229-232). `image` is null
  (:235), `isEmoji` is true (:241) and `shortcode` is optional (:238).
- Unicode packs are `UnicodeEmojis.packs` (`unicode_emoji.dart:12-68`,
  nine groups). They are loaded by `UnicodeEmojis.load()`, which
  `lib/main.dart:239` calls **without awaiting**, so `packs` can be null very
  early at startup. `availablePacks` force-unwraps it with `packs!`.
- `EmoticonPack` (`lib/client/components/emoticon/emoji_pack.dart:7-60`) has
  `emotes`, `emoji`, `stickers`, `displayName`, `image`, `icon` and
  `getByShortcode(String)` (:36). The Matrix implementation is
  `MatrixEmoticonPack.emoji` = `emotes.where(isEmoji)`
  (`matrix_emoticon_pack.dart:124-126`).
- `EmoticonComponent` (`lib/client/components/emoticon/emoticon_component.dart:13-24`)
  has `globalPacks()`, `ownedPacks`, `availablePacks`, `canCreatePack`
  and `onStateChanged`.
  - `RoomEmoticonComponent` (:26-34) adds `availableEmoji` and
    `availableStickers`.
  - `SpaceEmoticonComponent` (:36-37) adds nothing.
- `MatrixSpaceEmoticonComponent` (`matrix_space_emoticon_component.dart:8-32`)
  extends `MatrixEmoticonComponent`, which defines:
  - `ownedPacks`: the Space's own `im.ponies.room_emotes` packs
    (`matrix_emoticon_component.dart:46-67`).
  - `availablePacks` = `globalPacks() + ownedPacks + UnicodeEmojis.packs!`
    (:322-324). `globalPacks()` returns the **user's** globally enabled packs
    from any room (:155-205). This is not only this Space's packs, and the
    list is not deduplicated.
- How to get the component: `space.getComponent<SpaceEmoticonComponent>()`
  (`lib/client/space.dart:149`), as already done in
  `settings_category_space.dart:73-74` and `space_emoji_pack_settings.dart:19`.
- Suggested pack list for the soundboard (this mirrors
  `MatrixRoomEmoticonComponent._getAvailablePacks`,
  `matrix_room_emoticon_component.dart:134-159`):
  `spaceEmoticons.ownedPacks.where((p) => p.emoji.isNotEmpty)` +
  `UnicodeEmojis.packs ?? []`.

## 7. Popover utilities

- There is no generic `showPopover` helper in `commet/` or `tiamat/`. The
  existing patterns are:
  - `just_the_tooltip`'s `JustTheTooltip`, a dependency of both packages
    (`commet/pubspec.yaml:31`, `tiamat/pubspec.yaml:18`). It is used as a
    modal popover in `message_input.dart:990-1014` and for hovers in
    `tiamat/lib/atoms/tooltip.dart:42`, `side_navigation_bar.dart:62` and
    `account_management_tab.dart:219`.
  - `tiamat/lib/atoms/context_menu.dart:285` uses its own overlay
    (`addOverlay()`), but only for menu items.
  - `showDialog` is used for the soundboard panel (`call_view.dart:250`) and
    for the edit dialog.
- Recommendation: use `JustTheTooltip(isModal: true)` with a
  `JustTheController` and a fixed `SizedBox` (for example 400x400), copying
  the message_input setup. Inside the edit `AlertDialog`, a nested
  `showDialog` hosting the picker is the simplest reliable fallback, and it
  also works on mobile and web.

## 8. Running the unit tests

The steps below come from the memory note and CI (`.github/workflows/ci.yml:69`
runs `flutter test unit_test`).

```sh
cd commet
/home/gabriel/flutter/bin/flutter pub get --offline
PATH=/home/gabriel/flutter/bin:$PATH dart run scripts/codegen.dart   # lib/generated is gitignored
/home/gabriel/flutter/bin/flutter test unit_test/soundboard
PATH=/home/gabriel/flutter/bin:$PATH dart analyze && dart format --set-exit-if-changed .
```

## Implementation notes (risks and gotchas)

1. **Backward/forward compatibility.** Older clients do
   `json['emoji'] as String` (`soundboard_sound.dart:72`) inside a
   skip-on-error loop (`matrix_space_soundboard_component.dart:53-59`).
   - A custom sound stored as only `{"emoji_mxc", "emoji_shortcode"}` will
     **vanish** from their catalog, and their clients will also ignore its
     triggers (unknown soundId).
   - Consider still writing a fallback `emoji` (for example 🔊) or the
     shortcode text alongside the mxc fields, and bumping `version` to 2.
     The new `fromJson` should accept `emoji`, `emoji_mxc` or neither.
2. **Model shape.** Make `emoji` nullable (or keep it with a fallback) and add
   `emojiMxc` and `emojiShortcode`. `copyWith` cannot clear a field with the
   `?? this.x` pattern (:101), so switching from custom back to unicode needs
   an explicit clear (a sentinel or a dedicated value type such as
   `SoundboardEmoji`).
   - Update `SpaceSoundboardComponent.addSound`/`updateSound`
     (`soundboard_component.dart:22-36`) and the Matrix implementation.
   - Also update the test fixtures (`soundboard_core_test.dart:13`,
     `soundboard_session_test.dart:42`).
3. **Validation.**
   - `sanitizeEmoji` is the enforcement point (component :99, :134).
     Add a validator for custom emoji: `mxc://server/id` format, and a
     shortcode of the form `:[^\s:]+:` with a length cap.
   - Relaxing unicode validation should still reject whitespace, markup and
     overly long strings. Picker output (`UnicodeEmoticon.slug`) is always
     valid, but the event content can be written by any client.
   - The existing digits quirk (:146) is worth noting in the tests.
4. **The edit dialog always re-sends the emoji** (:253-254). Once the input is
   a picker value, send the emoji only if it changed, or send a typed value.
5. **Rendering needs a Matrix client.**
   - The panel (`soundboard_panel.dart:12-24`) and the overlay (`:9-20`) have
     none. Pass an image builder or an `ImageProvider` down. The call
     controller can build a `MatrixMxcImage` from `session.client`
     (`soundboard_call_controller.dart:113`). The settings page can use
     `(soundboard as MatrixSpaceSoundboardComponent).client.getMatrixClient()`.
   - Use the `MatrixEmoticon` image arguments (`matrix_emoticon.dart:31-35`).
     Add an error fallback, such as the shortcode text or 🔊.
   - Put the widget in one shared place, for example a small
     `SoundboardEmojiView`, and use it in the list row, panel, overlay and
     picker button.
6. **Overlay registry** stores the emoji as a `String`
   (`soundboard_overlay_registry.dart:10`). Change it to carry the full
   sound or emoji value object. The wire protocol does not change (§4).
7. **Picker pitfalls.**
   - The `EmoticonPicker` search force-unwraps `searchDelegate`
     (`emoticon_picker.dart:117`). Either pass a Space-scoped delegate, for
     example fuzzy search over the pack emoji using
     `AutofillSearchResultEmoticon`, or use `EmojiPicker` directly with
     `onlyEmoji: true`.
   - The picker needs a bounded height.
   - `UnicodeEmojis.packs` may be null (`main.dart:239` is not awaited), so
     guard it with `?? []`.
   - `MatrixSpaceEmoticonComponent.availablePacks` also pulls in the user's
     global packs and does not deduplicate them (`matrix_emoticon_component.dart:322-324`).
     Prefer `ownedPacks` + unicode.
   - Sticker-only packs: filter with `pack.emoji.isNotEmpty` and use `onlyEmoji`.
8. **Shortcode format.** `MatrixEmoticon.shortcode` has no colons, while
   `slug` has them (`matrix_emoticon.dart:11,17`). The issue's example
   `":velho:"` corresponds to `slug`.
   - The mxc is `(emoticon as MatrixEmoticon).emojiUrl.toString()`.
   - Deleting or renaming a pack emoji does not update the sounds. The stored
     mxc keeps rendering, since media is not deleted, so the mxc is the
     source of truth and the shortcode is only a label or tooltip.
9. **Web.** `MatrixMxcImage` is already used on web for emoticons, so there
   is no extra web-specific path. `JustTheTooltip` works on web. On mobile,
   prefer a dialog or bottom sheet over a tooltip.
10. **Canonical JSON.** New fields must be strings or ints, never doubles
    (test at `soundboard_core_test.dart:76-80`).
11. **Localisation.** The page uses hard-coded English strings (for example
    :66, :88, :232), so a new button label can follow the same style.
