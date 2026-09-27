# DJ booth

Music everyone in a voice room hears at the same moment, played by one
member (the DJ) from files on their computer, or from links a source
extension they installed can play (`docs/dj-extensions.md`), with a queue
everyone can see and a volume each listener sets for themselves.

## Shape

The DJ's desktop client plays each song from its file (a local one, or one
a source extension downloads, played while it downloads), decodes it in
Rust and publishes it as its own stereo LiveKit track
(`commet-dj-music`, 128 kbps Opus, DTX and RED off). Listeners just receive
that track, so:

- everyone is in sync by construction, and late joiners hear the song live;
- browsers and Android listen without any extension or file of their own;
- the music arrives through WebRTC playout, so the echo canceller removes it
  from every listener's microphone, loudspeaker users included;
- each listener's volume is the playback volume of that one track
  (`preferences.djMusicVolume`, one level for all music, apart from voices).
  The booth always sends at full level; how loud the music is, is each
  listener's own business.

Only desktop (Linux, Windows) can DJ: it needs the Rust player
(`librust_lib_commet` is not built for Android or web), and reads files and
runs extensions.

The DJ hears their own music through a second, in-process WebRTC connection
receiving the same track (`_LocalMonitor` in `native_dj_engine.dart`). A
media player would bypass WebRTC's playout, and a DJ on loudspeakers would
send the music back into the room through their microphone.

## Pieces

| Where | What |
|-------|------|
| `commet/lib/client/components/dj/` | Platform-free booth: models, wire protocol, link parsing, the `DjSession` state machine. Unit tested in `commet/unit_test/dj/`. |
| `commet/lib/client/matrix/components/dj/` | LiveKit transport, `DjBooths` (one booth per call, opened and closed by `MatrixLivekitVoipSession`), platform switch (`dj_platform*.dart`). |
| `.../dj/native/` | Desktop only: `DjExtensions` (installs and runs source extensions), `DjExtensionResolver`, `DjLocalFiles` (what `file:<id>` points at), `DjSongCache`, `NativeDjEngine`, FFI bindings. |
| `rust/dj_audio` | The player: symphonia decode (Opus in WebM/Ogg, AAC/MP4 incl. fragmented, MP3, Vorbis, FLAC, WAV) of whole files or files still downloading (`growing.rs`), resampling to 48 kHz stereo, a ring buffer filled by a decoder thread, fades, gain. C ABI `commet_music_*`, linked into `librust_lib_commet`. Opus is `opus.rs`, on the pure-Rust `opus-rs`. |
| `third_party/flutter-webrtc` | `commetCreateMusicTrack` / `commetStopMusicTrack` and `commet_music_source.h`: a kCustom audio source fed by a 10 ms pacing thread calling `commet_music_pull`. |
| `third_party/livekit-client-sdk-flutter` | `AudioPublishOptions.stereo`: `TF_STEREO` on the track, `stereo=1;sprop-stereo=1` in our offer, and the subscriber answer mirrors stereo where the server offers it. |
| `commet/lib/ui/organisms/dj/` | Booth panel, now-playing pill, spinning record, member badges and right-click actions, the extension install prompt, the listener's music volume. Installed extensions are listed in Settings, App, DJ. |

## Who is the DJ

The DJ's client owns the booth and broadcasts it over the LiveKit data
channel (topic `chat.commet.dj.v1`, reliable, sent one after another): the
full state on every change (queue, current song, position, pause, requests,
pending handoff) and a tick with the position every 2 s. States over 14 KB
are split into parts of their JSON text (not compressed, so what a sender can
make a receiver hold stays bounded). Every change of DJ bumps an epoch, and
every client applies the same rule, so they converge:

- A state names its sender as the DJ, or nobody (an empty booth).
- A higher epoch wins. At the same epoch a DJ beats an empty booth (releases
  bump the epoch, so a same-epoch empty booth only means LiveKit reported the
  DJ gone), two DJs are settled by the smaller identity, and a DJ's `seq`
  never goes backwards.
- A sender whose state lost is sent ours back, only when ours would win at
  their end too and at most once every 3 s per sender, so a claim made
  without knowing the booth ends and no disagreement can loop.
- Ticks from a DJ at an epoch we don't know (or ours, from someone we don't
  take for the DJ) make us ask with `sync`. Anyone who knows an empty booth
  answers a `sync`, so newcomers get the kept queue and the right epoch.
- A DJ nobody has heard from in 10 s counts as gone, so the booth can be
  claimed even if LiveKit still lists them.
- After a LiveKit reconnect a client sends its caps and a `sync` again.

How the epoch moves:

- **Claim.** With the booth empty, a desktop client announces itself with the
  next epoch and carries on with the kept queue, paused.
- **Pass.** The DJ names a target (with a pass id). A target that asked for
  the decks takes them; anyone else is asked first. The target fetches the
  playing song while the DJ keeps playing (telling the DJ it is still at it
  every 20 s, so the 90 s timeout doesn't run out during a download), loads
  it paused a moment ahead of the live position, announces itself with the
  next epoch and starts playing 250 ms after that announcement is out; the
  old DJ fades out when it sees it. Queue, position and pause carry over. A
  DJ who hangs up during a pass doesn't empty the booth: the target finishes
  the pass. A target that fails or says no answers `pfail`. The target
  waits for the whole song, not just its start: it picks it up mid-way. The DJ's queue
  is locked while a pass is pending.
- **Request.** A desktop listener asks; the DJ's state lists them, which puts
  a ✋ next to their name for everyone. Web and Android get an explanation
  instead of the request action. Hands go down when the booth empties.
- **Release or leave.** The booth empties but everyone keeps the queue and
  position, paused, so the next DJ picks up where it stopped.

This is not a security boundary (a modified client can say anything on the
data channel) but it keeps honest clients consistent. What a peer's state
can make a new DJ fetch is limited: files only by the id this computer gave
them, extension sources only through an extension this user installed,
told the source is untrusted, and web links only to public hosts.

Booth messages (a song that failed, a handoff that didn't happen) show as a
toast on the root navigator's overlay, wherever the user is: the app has no
Scaffold for snack bars.

## Songs

- Files: the add bar's file button picks audio files. Each is queued as
  `file:<id>`, the id a hash of its path, and the path is remembered in
  `<app support>/dj-local-files.json`. The file is played where it is, never
  copied. Another client can't play it: a DJ who takes over skips such songs
  (`DjTrackUnavailable`, which doesn't count towards stopping the booth), and
  the decks can't be handed over while one is playing.
- Links go to the source extension whose `hosts` take them, which lists the
  songs (`resolve`) and downloads each one when its turn comes (`fetch`). See
  `docs/dj-extensions.md` for the protocol and the package.
- Songs play while they download, as a video does. The extension writes the
  file in place and names it, with its size when it knows it exactly,
  before the first byte; Dart hands both to the player
  (`commet_music_file_growing`), which reads the file as it grows and waits
  for bytes that haven't arrived, then says when the download is done
  (`commet_music_file_done`). Fragmented MP4 with its index up front starts
  after the first few KB. Opening and seeking such a file happen on the
  decoder thread, so nothing waits on the network in the UI.
- A download that breaks off plays what arrived, then the song fails with
  the extension's reason.
- Downloaded songs are cached in `<app cache>/dj-songs/` (1.5 GB, oldest
  first), keyed by source, and the next two queued songs are fetched ahead.
  Only a finished download gets a record (`<key>.json`); anything else under
  its key is deleted before fetching again.
- On Windows the booth starts extensions itself, with `CreateProcessW` and
  `CREATE_NO_WINDOW` (`windows_hidden_process.dart`), and reads their output
  from files in a temporary directory. Dart can only start a child normally,
  which gives a console app its own console window, or detached, which gives
  it none and so hands a fresh console to whatever *it* starts.
  `CREATE_NO_WINDOW` gives a console with no window, which the whole tree
  inherits. Each extension also runs in a job object of its own, so a
  request killed for running too long ends everything it started
  (yt-dlp.exe, for one, is a launcher whose Python child would go on
  downloading otherwise).

## Known gaps

- The queue lives only in the call: when everyone leaves, it is gone.
- Only the DJ edits the queue.
- A song only in MPEG-TS can't be decoded.
- Opus is decoded by `opus-rs`, which plays CELT within 82 dB of libopus but
  SILK only within 15 dB, and mis-reads some multi-frame packets. The booth
  works around both: `opus.rs` splits packets into frames itself, and turns
  down any stream that is not CELT, which is why extensions should hand it
  Opus only at 96 kbps and up, and why a low-bitrate Opus file of the DJ's
  may not play. A stream that switches to SILK part way through, or that
  changes how many channels it codes (which `opus-rs` will not decode),
  stops with "its audio format isn't supported" instead of sounding wrong.
- A local file's length shows once it plays: nothing reads it before.
- An MP4 with its index at the end only starts once it has all downloaded,
  and so does fragmented MP4 whose size the extension doesn't give.
- Listening on web depends on the LiveKit audio element volume (0..100 %); on
  desktop the music can be boosted to 150 %.
