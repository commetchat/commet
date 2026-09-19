# DJ booth

Music everyone in a voice room hears at the same moment, played by one
member (the DJ) from YouTube, SoundCloud and Spotify links, with a queue
everyone can see and a volume each listener sets for themselves. It replaces
Discord's music bots, which YouTube and Discord have shut down one after the
other.

## Shape

The DJ's desktop client downloads each song with yt-dlp, decodes it in Rust
and publishes it as its own stereo LiveKit track
(`commet-dj-music`, 128 kbps Opus, DTX and RED off). Listeners just receive
that track, so:

- everyone is in sync by construction, and late joiners hear the song live;
- browsers and Android listen without yt-dlp, and without YouTube's ads;
- the music arrives through WebRTC playout, so the echo canceller removes it
  from every listener's microphone, loudspeaker users included;
- each listener's volume is the playback volume of that one track
  (`preferences.djMusicVolume`, one level for all music, apart from voices).

Only desktop (Linux, Windows) can DJ: it needs the Rust player
(`librust_lib_commet` is not built for Android or web) and to run yt-dlp.
The download happens on the DJ's home connection, which YouTube treats far
better than the datacenter addresses the bots ran from.

The DJ hears their own music through a second, in-process WebRTC connection
receiving the same track (`_LocalMonitor` in `native_dj_engine.dart`). A
media player would bypass WebRTC's playout, and a DJ on loudspeakers would
send the music back into the room through their microphone.

## Pieces

| Where | What |
|-------|------|
| `commet/lib/client/components/dj/` | Platform-free booth: models, wire protocol, link parsing, the `DjSession` state machine. Unit tested in `commet/unit_test/dj/`. |
| `commet/lib/client/matrix/components/dj/` | LiveKit transport, `DjBooths` (one booth per call, opened and closed by `MatrixLivekitVoipSession`), platform switch (`dj_platform*.dart`). |
| `.../dj/native/` | Desktop only: `DjTools` (yt-dlp and Deno, found on PATH or downloaded with consent), `YtDlp`, `NativeDjLinkResolver` (yt-dlp, Spotify embed pages), `DjSongCache`, `NativeDjEngine`, FFI bindings. |
| `rust/dj_audio` | The player: symphonia decode (AAC/MP4 incl. fragmented, MP3, Vorbis, FLAC, WAV), resampling to 48 kHz stereo, a ring buffer filled by a decoder thread, fades, gain. C ABI `commet_music_*`, linked into `librust_lib_commet`. |
| `third_party/flutter-webrtc` | `commetCreateMusicTrack` / `commetStopMusicTrack` and `commet_music_source.h`: a kCustom audio source fed by a 10 ms pacing thread calling `commet_music_pull`. |
| `third_party/livekit-client-sdk-flutter` | `AudioPublishOptions.stereo`: `TF_STEREO` on the track, `stereo=1;sprop-stereo=1` in our offer, and the subscriber answer mirrors stereo where the server offers it. |
| `commet/lib/ui/organisms/dj/` | Booth panel, now-playing pill, spinning record, member badges and right-click actions, tools prompt. |

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
  the pass. A target that fails or says no answers `pfail`. The DJ's queue
  is locked while a pass is pending.
- **Request.** A desktop listener asks; the DJ's state lists them, which puts
  a ✋ next to their name for everyone. Web and Android get an explanation
  instead of the request action. Hands go down when the booth empties.
- **Release or leave.** The booth empties but everyone keeps the queue and
  position, paused, so the next DJ picks up where it stopped.

This is not a security boundary (a modified client can say anything on the
data channel) but it keeps honest clients consistent. What a peer's state
can make a new DJ fetch is limited: https links to public hosts and
`ytsearch1:` queries only, and without yt-dlp's generic extractor.

Booth messages (a song that failed, a handoff that didn't happen) show as a
toast on the root navigator's overlay, wherever the user is: the app has no
Scaffold for snack bars.

## yt-dlp

- Found on PATH, else downloaded from its GitHub releases into
  `<app support>/dj-tools/` after the user agrees; the managed copy runs
  `yt-dlp -U` once a day.
- YouTube needs a JavaScript runtime: Deno ≥ 2.3 or Node ≥ 22 from PATH, else
  Deno is downloaded the same way (about 45 MB).
- Formats are picked for the Rust decoder: AAC in MP4 over plain HTTP first
  (YouTube itag 140), then MP3 (SoundCloud), Vorbis, FLAC. Opus/WebM-only
  sources fail with a readable error.
- Spotify's audio is DRM protected: its public embed page gives title,
  artists and length (album and playlist pages list about 50 tracks), and
  each song plays from yt-dlp's `ytsearch1:` best YouTube match.
- Songs are cached in `<app cache>/dj-songs/` (1.5 GB, oldest first), keyed
  by source, and the next two queued songs are fetched ahead.
- On Windows yt-dlp runs detached (`ProcessStartMode.detachedWithStdio`) so no
  console window flashes; success is read from its output.

## Known gaps

- The queue lives only in the call: when everyone leaves, it is gone.
- Only the DJ edits the queue.
- Spotify playlists beyond the embed page's first ~50 tracks are not read.
- A song whose only formats are Opus/WebM, or YouTube HLS in MPEG-TS, can't
  be decoded.
- Listening on web depends on the LiveKit audio element volume (0..100 %); on
  desktop the music can be boosted to 150 %.
- Downloading YouTube audio without ads is against YouTube's terms.
