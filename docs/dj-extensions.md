# DJ source extensions

The DJ booth (`docs/dj-booth.md`) plays two kinds of songs: files from the
DJ's own disk, and songs a **source extension** finds for a pasted link. The
app knows no music site. An extension is a program the user installs on
their desktop client; the booth asks it what a link holds and has it
download each song, then plays and publishes the result like a local file.

Extensions are desktop only (Linux, Windows), like DJing itself. They are
not made or shipped with Roscord.

## Package

A `.zip` with `roscord-extension.json` at its root, next to whatever the
extension runs (scripts, data). Installed from a file the user picks or an
`https://` link they paste, into `<app support>/dj-extensions/<id>/`. The
app records where it came from, so it can be installed again from there to
update it.

```json
{
  "protocol": 1,
  "id": "org.example.music",
  "name": "Example music",
  "version": "1.0.0",
  "description": "One line shown in the install prompt and the list.",
  "homepage": "https://example.org/music-extension",
  "hosts": ["example.org", "music.example.net"],
  "hint": "Paste an Example link",
  "downloads": [
    {
      "id": "deno",
      "name": "Deno",
      "size": "45 MB",
      "files": {
        "windows-x64": {
          "url": "https://github.com/denoland/deno/releases/latest/download/deno-x86_64-pc-windows-msvc.zip",
          "unzip": "deno.exe"
        },
        "linux-x64": {
          "url": "https://github.com/denoland/deno/releases/latest/download/deno-x86_64-unknown-linux-gnu.zip",
          "unzip": "deno"
        }
      }
    }
  ],
  "run": {
    "command": "{dep:deno}",
    "args": ["run", "--allow-all", "--no-prompt", "{dir}/main.ts"]
  }
}
```

- `protocol`: `1`. Anything else is refused.
- `id`: 3 to 64 characters of `a-z 0-9 . _ -`, unique. Installing the same
  id again replaces the installed one.
- `hosts`: the links it takes. A link's host matches an entry equal to it or
  ending in `.` + it (`www.example.org` matches `example.org`). `"*"` takes
  any link no other extension claims.
- `hint`: the add bar's placeholder while this extension is installed.
- `downloads`: programs fetched at install time, after the user agrees, with
  progress shown. Platforms are `windows-x64`, `linux-x64` and
  `linux-arm64`; an extension with a download that has no file for this
  platform can't be installed here. `unzip` names the file to take out of a
  `.zip` download; without it the download is the program. `sha256`
  (lowercase hex) is checked when present. Each program lands at
  `<dir>/deps/<id>` (`.exe` added on Windows) and is made executable.
- `run`: how to start the extension. `{dir}` is the extension's folder,
  `{dep:<id>}` the path of a download. The booth appends the verb and the
  request (below).

The install prompt says the extension runs a program with the user's
permissions and lists the downloads with their sizes. Nothing is fetched
before the user agrees.

## Protocol

One process per request. The booth starts `command args… <verb> <request>`,
where `<request>` is one JSON object as a single argument, and reads JSON
objects from the process's stdout, one per line. Other lines are ignored;
stderr is kept for the log. stdin is empty. The working directory is
`{dir}`. On Windows the process gets a console with no window
(`CREATE_NO_WINDOW`), which whatever it starts inherits, so nothing in the
tree flashes a window; that is also why the request is an argument and not
stdin or the environment.

Every request carries `"protocol": 1` and `"data"`: a folder the extension
may keep things in (`<dir>/data`, created before the first request).
`<dir>/deps` is writable too, so a download can update itself.

The process is killed when it runs over its time (below). On Windows it runs
in a job object of its own, and the kill ends the whole job: whatever it
started goes too. A program it leaves running after it has ended normally
(an updater, say) is left alone. On Linux only the process gets the
signal, so an extension that starts other programs should end them when it
goes.

### `resolve`

What a pasted link holds. 90 seconds.

```json
{"protocol": 1, "data": "/…/dj-extensions/org.example.music/data",
 "url": "https://example.org/album/123"}
```

Answer:

```json
{"tracks": [
  {"source": "https://example.org/track/1", "title": "Song",
   "artist": "Artist", "durationMs": 215000,
   "thumbnail": "https://example.org/art/1.jpg", "label": "Example"}
]}
```

or `{"error": "Nothing playable in that link"}`.

- `source` (required, at most 900 characters): whatever the extension wants
  back in `fetch`. It travels to everyone in the call, so it must not carry
  anything private.
- `title` (required), `artist`, `durationMs`, `thumbnail` (`https://`).
- `link`: the page to open for the song, when it isn't `source`. A track
  with a `link` keeps the title and artist given here; one without has them
  replaced by what `fetch` reports.
- `label`: at most 16 characters, shown on the song's chip in the queue.

### `fetch`

Downloads one song's audio. 10 minutes.

```json
{"protocol": 1, "data": "/…/data", "source": "https://example.org/track/1",
 "directory": "/…/dj-songs", "name": "3f2a9c…", "trusted": true}
```

The song goes to `<directory>/<name>.<ext>`, written in place: the booth
plays it while it grows, so no temporary name and no rewriting once done.
Before the first byte:

```json
{"started": {"path": "/…/dj-songs/3f2a9c….webm", "size": 3481234,
  "durationMs": 215000, "title": "Song", "artist": "Artist",
  "thumbnail": "https://…", "audio": "opus 132 kbps, 48 kHz stereo"}}
```

`path` is required; `size` lets the player tell a slow download from the
end of the file, so it is the exact size in bytes or left out, never an
estimate. `audio` goes in the log. When the whole file is written:

```json
{"done": {"path": "/…/dj-songs/3f2a9c….webm"}}
```

with the same `path` as `started` (an extension that ends up writing another
file sends an error instead), or `{"error": "why"}` at any point. A process
that ends without `done` failed. The booth reads stdout until it closes, so
helper programs the extension starts must not hold on to it.

The player reads Opus in WebM or Ogg, AAC in MP4 (fragmented too), MP3,
Vorbis, FLAC and WAV. MPEG-TS it can't.

`trusted` is false when the song came from another client's booth state (a
DJ who took over the decks fetches the queue the previous DJ built). Such a
source was not checked by this user, so an untrusted fetch must only reach
sites the extension knows, never fetch an arbitrary page. Before asking,
the booth refuses an untrusted `http(s)` source whose host is not public
(`localhost`, private and link-local addresses).

## In the booth

- Queued songs from an extension have the source
  `ext:<extension id>:<source>`. A DJ without that extension can't play
  them, and the booth skips them with a notice.
- Sources queued by clients older than extensions (plain links) go to the
  first installed extension whose `hosts` match, else the first installed.
- Local files are `file:<id>`, known only to the DJ who added them (the path
  stays on their machine; the file name, as the title, is what the room
  sees). Another DJ skips them. A DJ can't hand over the decks while one is
  playing.
