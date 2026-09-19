// The DJ's player on desktop: songs are downloaded with yt-dlp, decoded by
// the Rust player, and published as a stereo LiveKit track named
// MatrixLivekitVoipStream.musicTrackName, apart from the DJ's microphone.
//
// The DJ hears their own music through a second, in-process WebRTC
// connection that receives the same track (_LocalMonitor). Playing it
// through WebRTC's playout, and not a media player, puts it in the echo
// canceller's reference, so a DJ on loudspeakers doesn't send the music
// back into the room through their microphone.
import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:commet/client/components/dj/dj_engine.dart';
import 'package:commet/client/components/dj/dj_models.dart';
import 'package:commet/client/matrix/components/dj/native/dj_music_player.dart';
import 'package:commet/client/matrix/components/dj/native/dj_tools.dart';
import 'package:commet/client/matrix/components/dj/native/yt_dlp.dart';
import 'package:commet/client/matrix/components/voip_room/matrix_livekit_voip_stream.dart';
import 'package:commet/debug/log.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart' as rtc;
// The stream flutter-webrtc returns for native tracks; getDisplayMedia builds
// its own the same way.
// ignore: implementation_imports
import 'package:flutter_webrtc/src/native/media_stream_impl.dart';
import 'package:livekit_client/livekit_client.dart' as lk;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Downloaded songs, shared by every booth this app runs.
class DjSongCache {
  DjSongCache._();
  static final DjSongCache instance = DjSongCache._();

  /// Kept on disk at most, oldest dropped first.
  static const maxBytes = 1500 * 1024 * 1024;

  Directory? _dir;
  final Map<String, Future<YtDlpDownload>> _inFlight = {};

  /// Songs used since the app started: never trimmed, one may be playing.
  final Set<String> _used = {};

  Future<Directory> get directory async {
    final dir = _dir ??= Directory(
        p.join((await getApplicationCacheDirectory()).path, 'dj-songs'));
    if (!await dir.exists()) await dir.create(recursive: true);
    return dir;
  }

  static String _keyOf(String source) =>
      sha1.convert(utf8.encode(source)).toString().substring(0, 20);

  /// Only what the booth itself would queue: web links, and the YouTube
  /// searches Spotify songs become. A state from another client names the
  /// songs a new DJ fetches, and must not point it anywhere else.
  static bool isFetchable(String source) {
    if (source.startsWith('ytsearch1:')) return source.length > 10;
    final uri = Uri.tryParse(source);
    if (uri == null || uri.scheme != 'https' || uri.host.isEmpty) return false;
    final host = uri.host.toLowerCase();
    // No addresses: a link names a site, not a machine on someone's network.
    // The system resolver reads forms like 127.1 or 0x7f.1 as addresses too.
    return InternetAddress.tryParse(host) == null &&
        !RegExp(r'^[0-9a-fx.]+$').hasMatch(host) &&
        host != 'localhost' &&
        !host.endsWith('.localhost') &&
        !host.endsWith('.local') &&
        !host.endsWith('.internal') &&
        host.contains('.');
  }

  /// Whether [host] resolves only to public addresses. A name can point at
  /// this machine or its network (`127.0.0.1.nip.io`); unresolvable counts
  /// as not public.
  static Future<bool> hostIsPublic(String host) async {
    try {
      final addresses = await InternetAddress.lookup(host)
          .timeout(const Duration(seconds: 5));
      return addresses.isNotEmpty && !addresses.any(isPrivateAddress);
    } catch (_) {
      return false;
    }
  }

  static bool isPrivateAddress(InternetAddress address) {
    if (address.isLoopback || address.isLinkLocal || address.isMulticast) {
      return true;
    }
    final b = address.rawAddress;
    if (address.type == InternetAddressType.IPv4) {
      return b[0] == 0 ||
          b[0] == 10 ||
          (b[0] == 100 && b[1] >= 64 && b[1] < 128) ||
          (b[0] == 172 && b[1] >= 16 && b[1] < 32) ||
          (b[0] == 192 && b[1] == 168);
    }
    // fc00::/7 unique local; ::ffff:a.b.c.d mapped IPv4.
    if ((b[0] & 0xfe) == 0xfc) return true;
    final mapped = b.sublist(0, 10).every((x) => x == 0) &&
        b[10] == 0xff &&
        b[11] == 0xff;
    return mapped &&
        isPrivateAddress(InternetAddress.fromRawAddress(b.sublist(12)));
  }

  /// The song's audio file, downloading it once however many ask.
  /// [trusted] sources (queued by this user) may use yt-dlp's generic
  /// extractor, which fetches any web page; others, which came from another
  /// client's state, only reach the sites yt-dlp knows.
  Future<YtDlpDownload> fetch(String source, {bool trusted = false}) {
    if (!isFetchable(source)) {
      return Future.error(StateError("that link can't be played"));
    }
    final key = _keyOf(source);
    _used.add(key);
    return _inFlight[key] ??= _fetch(source, key, trusted: trusted)
        .whenComplete(() => _inFlight.remove(key));
  }

  Future<YtDlpDownload> _fetch(String source, String key,
      {required bool trusted}) async {
    final dir = await directory;
    final infoFile = File(p.join(dir.path, '$key.json'));
    if (await infoFile.exists()) {
      try {
        final info = jsonDecode(await infoFile.readAsString());
        final path = info is Map ? info['filepath'] : null;
        if (path is String && await File(path).exists()) {
          // Touched, so trimming keeps what is played often.
          final now = DateTime.now();
          await infoFile.setLastModified(now);
          await File(path).setLastModified(now);
          return YtDlpDownload(path, Map<String, Object?>.from(info));
        }
      } catch (_) {}
    }

    // No record of a finished download: whatever is there under this key
    // is left from one that was cut short, and yt-dlp would take it as done.
    await for (final entry in dir.list()) {
      final name = p.basename(entry.path);
      if (entry is File && name.startsWith('$key.') && !name.endsWith('.part')) {
        await entry.delete().catchError((_) => entry);
      }
    }

    if (!trusted && !source.startsWith('ytsearch1:')) {
      final host = Uri.parse(source).host;
      if (!await hostIsPublic(host)) {
        throw StateError("that link can't be played");
      }
    }

    final tools = await DjTools.instance.locate();
    if (tools == null) throw StateError('The DJ tools are not set up');
    final download = await YtDlp(tools).download(source,
        directory: dir.path, name: key, knownSitesOnly: !trusted);
    await infoFile.writeAsString(jsonEncode(download.info));
    unawaited(_trim(dir));
    return download;
  }

  bool _trimming = false;

  Future<void> _trim(Directory dir) async {
    if (_trimming) return;
    _trimming = true;
    try {
      // By song: its audio and its record go together, newest touch first.
      final byKey = <String, List<(File, FileStat)>>{};
      await for (final entry in dir.list()) {
        if (entry is! File) continue;
        final key = p.basename(entry.path).split('.').first;
        byKey.putIfAbsent(key, () => []).add((entry, await entry.stat()));
      }
      final songs = byKey.entries.toList()
        ..sort((a, b) => _newest(a.value).compareTo(_newest(b.value)));
      var total = songs.fold<int>(
          0, (sum, s) => sum + s.value.fold<int>(0, (t, f) => t + f.$2.size));
      for (final song in songs) {
        if (total <= maxBytes) break;
        if (_used.contains(song.key) || _inFlight.containsKey(song.key)) {
          continue;
        }
        for (final (file, stat) in song.value) {
          await file.delete().catchError((_) => file);
          total -= stat.size;
        }
      }
    } catch (e, s) {
      Log.onError(e, s, content: 'DJ booth: could not trim the song cache');
    } finally {
      _trimming = false;
    }
  }

  static DateTime _newest(List<(File, FileStat)> files) => files
      .map((f) => f.$2.modified)
      .reduce((a, b) => a.isAfter(b) ? a : b);
}

class NativeDjEngine implements DjPlaybackEngine {
  final lk.Room room;
  final DjMusicBindings bindings;

  NativeDjEngine(this.room, this.bindings, {double monitorVolume = 1})
      : _monitorVolume = monitorVolume;

  DjMusicPlayer? _player;
  rtc.MediaStream? _stream;
  lk.LocalAudioTrack? _lkTrack;
  final _LocalMonitor _monitor = _LocalMonitor();
  double _monitorVolume;

  /// Tracks ids for the Rust player, which counts them in integers.
  final Map<String, int> _numbers = {};
  int _nextNumber = 1;
  String? _loadedId;

  /// Files [prepare] fetched, by track id.
  final Map<String, YtDlpDownload> _downloads = {};

  Future<void>? _starting;
  bool _shutDown = false;

  /// Set once flutter-webrtc answered: its pacing thread pulls from the
  /// player until commetStopMusicTrack([_feederTrackId]) returns.
  bool _feederStarted = false;
  String? _feederTrackId;

  @override
  Future<void> start() => _starting ??= _start();

  Future<void> _start() async {
    final participant = room.localParticipant;
    if (participant == null) throw StateError('Not connected to the call');
    final player = _player = DjMusicPlayer(bindings);

    final response = await rtc.WebRTC.invokeMethod(
        'commetCreateMusicTrack', <String, dynamic>{
      'ctx': player.handleAddress,
      'pull': player.pullAddress,
    });
    if (response == null) throw StateError('No music track');
    // The pacing thread runs from here on: remembered before anything else
    // can fail, so shutdown always stops it before freeing the player.
    final audio = response['audioTracks'];
    _feederTrackId = audio is List && audio.isNotEmpty && audio.first is Map
        ? (audio.first as Map)['id'] as String?
        : null;
    _feederStarted = true;
    final stream = MediaStreamNative(response['streamId'], 'local')
      ..setMediaTracks(response['audioTracks'], response['videoTracks']);
    _stream = stream;
    final track = stream.getAudioTracks().first;
    if (_shutDown) return;

    // ignore: invalid_use_of_internal_member
    final lkTrack = _lkTrack = lk.LocalAudioTrack(lk.TrackSource.unknown,
        stream, track, const lk.AudioCaptureOptions());
    await participant.publishAudioTrack(lkTrack,
        publishOptions: const lk.AudioPublishOptions(
          name: MatrixLivekitVoipStream.musicTrackName,
          // Music has no pauses DTX could save on, and the quiet ends of
          // songs must not be cut. No RED: it doubles 128 kbps for little.
          dtx: false,
          red: false,
          stereo: true,
          encoding: lk.AudioEncoding(maxBitrate: 128000),
        ));
    if (_shutDown) return;

    try {
      await _monitor.start(stream, track, _monitorVolume);
    } catch (e, s) {
      // The room still hears the music; only the DJ doesn't.
      Log.onError(e, s, content: 'DJ booth: could not start the monitor');
    }
  }

  @override
  Future<void> shutdown() async {
    if (_shutDown) return;
    _shutDown = true;
    // A start still on its way would publish after we are done: let it
    // finish, then undo all of it.
    await _starting?.catchError((_) {});

    final player = _player;
    // A short fade instead of a click when the booth changes hands.
    player?.setPaused(true);
    await Future<void>.delayed(const Duration(milliseconds: 40));

    await _monitor.stop();

    // By track, not by the publication we got: a full reconnect republishes
    // it under a new sid.
    final lkTrack = _lkTrack;
    final participant = room.localParticipant;
    if (lkTrack != null && participant != null) {
      for (final publication in participant.trackPublications.values
          .where((pub) => identical(pub.track, lkTrack))
          .toList()) {
        try {
          await participant.removePublishedTrack(publication.sid);
        } catch (e, s) {
          Log.onError(e, s,
              content: 'DJ booth: could not unpublish the music');
        }
      }
    }

    // The pacing thread must be gone before the player is freed.
    var feederStopped = !_feederStarted;
    final feeder = _feederTrackId;
    if (feeder != null) {
      try {
        await rtc.WebRTC.invokeMethod(
            'commetStopMusicTrack', <String, dynamic>{'trackId': feeder});
        feederStopped = true;
      } catch (e, s) {
        Log.onError(e, s, content: 'DJ booth: could not stop the music track');
      }
    }
    try {
      await lkTrack?.stop();
      await _stream?.dispose();
    } catch (_) {}
    if (feederStopped) {
      player?.free();
    } else if (player != null) {
      // Leaked on purpose: freeing it under a live thread would crash.
      player.stop();
    }
    _player = null;
  }

  @override
  Future<DjTrackInfo> prepare(DjTrack track) async {
    final self = room.localParticipant?.identity;
    final download = await DjSongCache.instance.fetch(track.source,
        trusted: self != null && track.addedBy == djUserIdOf(self));
    _downloads[track.id] = download;
    return _infoOf(download.info);
  }

  static DjTrackInfo _infoOf(Map<String, Object?> info) {
    String? text(String key) {
      final v = info[key];
      return v is String && v.trim().isNotEmpty ? v.trim() : null;
    }

    final duration = info['duration'];
    return DjTrackInfo(
      title: text('title'),
      artist: (text('artist') ??
              text('creator') ??
              text('uploader') ??
              text('channel'))
          ?.replaceFirst(RegExp(r'\s+-\s+Topic$'), ''),
      durationMs: duration is num && duration.isFinite && duration > 0
          ? (duration * 1000).round()
          : null,
      thumbnail: text('thumbnail'),
    );
  }

  @override
  void load(DjTrack track, {required int positionMs, required bool paused}) {
    final download = _downloads[track.id];
    final player = _player;
    if (download == null) throw StateError('the song was not fetched');
    if (player == null || _shutDown) throw StateError('the booth is closed');
    final number = _numbers.putIfAbsent(track.id, () => _nextNumber++);
    player.setPaused(paused);
    player.open(download.path, positionMs: positionMs, trackId: number);
    _loadedId = track.id;
  }

  @override
  void setPaused(bool paused) => _player?.setPaused(paused);

  @override
  Future<void> seek(int positionMs) async => _player?.seek(positionMs);

  @override
  void unload() {
    _player?.stop();
    _loadedId = null;
  }

  @override
  DjEngineStatus get status {
    final player = _player;
    if (player == null || player.isFreed) return DjEngineStatus.idle;
    final s = player.status;
    final loaded = _loadedId;
    final sameTrack = loaded != null && _numbers[loaded] == s.trackId;
    return DjEngineStatus(
      state: switch (s.state) {
        MusicState.idle => DjEngineState.idle,
        MusicState.playing => DjEngineState.playing,
        MusicState.paused => DjEngineState.paused,
        MusicState.ended => DjEngineState.ended,
        MusicState.error => DjEngineState.error,
        MusicState.buffering => DjEngineState.buffering,
      },
      trackId: sameTrack ? loaded : null,
      positionMs: s.positionMs,
      durationMs: s.durationMs,
    );
  }

  @override
  set monitorVolume(double volume) {
    _monitorVolume = volume;
    _monitor.setVolume(volume);
  }
}

/// Plays a local track to this machine's speakers through WebRTC: a sending
/// and a receiving peer connection in the same process, linked directly.
class _LocalMonitor {
  rtc.RTCPeerConnection? _sender;
  rtc.RTCPeerConnection? _receiver;
  rtc.MediaStreamTrack? _remote;
  double _volume = 1;
  bool _stopped = false;

  Future<void> start(
      rtc.MediaStream stream, rtc.MediaStreamTrack track, double volume) async {
    _volume = volume;
    final config = <String, dynamic>{
      'iceServers': <Map<String, dynamic>>[],
      'sdpSemantics': 'unified-plan',
    };
    final sender = _sender = await rtc.createPeerConnection(config);
    final receiver = _receiver = await rtc.createPeerConnection(config);
    if (_stopped) return _dispose(sender, receiver);

    // Candidates can come before the other side has a description.
    final toReceiver = <rtc.RTCIceCandidate>[];
    final toSender = <rtc.RTCIceCandidate>[];
    var linked = false;
    sender.onIceCandidate = (c) {
      if (c.candidate == null || _stopped) return;
      linked ? receiver.addCandidate(c) : toReceiver.add(c);
    };
    receiver.onIceCandidate = (c) {
      if (c.candidate == null || _stopped) return;
      linked ? sender.addCandidate(c) : toSender.add(c);
    };
    receiver.onTrack = (event) {
      if (event.track.kind != 'audio') return;
      _remote = event.track;
      rtc.Helper.setVolume(_volume, event.track);
    };

    await sender.addTrack(track, stream);
    final offer = await sender.createOffer();
    offer.sdp = _stereo(offer.sdp);
    await sender.setLocalDescription(offer);
    await receiver.setRemoteDescription(offer);
    final answer = await receiver.createAnswer();
    answer.sdp = _stereo(answer.sdp);
    await receiver.setLocalDescription(answer);
    await sender.setRemoteDescription(answer);
    if (_stopped) return;
    linked = true;
    for (final c in toReceiver) {
      await receiver.addCandidate(c);
    }
    for (final c in toSender) {
      await sender.addCandidate(c);
    }
  }

  /// Asks for stereo Opus in both directions.
  static String? _stereo(String? sdp) {
    if (sdp == null) return null;
    final opus =
        RegExp(r'a=rtpmap:(\d+) opus/48000/2', caseSensitive: false)
            .firstMatch(sdp);
    if (opus == null) return sdp;
    final pt = opus[1];
    return sdp.replaceAllMapped(RegExp('a=fmtp:$pt ([^\r\n]*)'), (m) {
      final params = m[1]!.split(';');
      for (final wanted in [
        'stereo=1',
        'sprop-stereo=1',
        'maxaveragebitrate=256000'
      ]) {
        if (!params.contains(wanted)) params.add(wanted);
      }
      return 'a=fmtp:$pt ${params.join(';')}';
    });
  }

  void setVolume(double volume) {
    _volume = volume;
    final remote = _remote;
    if (remote != null) rtc.Helper.setVolume(volume, remote);
  }

  Future<void> stop() async {
    _stopped = true;
    final sender = _sender;
    final receiver = _receiver;
    _sender = null;
    _receiver = null;
    _remote = null;
    await _dispose(sender, receiver);
  }

  static Future<void> _dispose(
      rtc.RTCPeerConnection? sender, rtc.RTCPeerConnection? receiver) async {
    for (final pc in [sender, receiver]) {
      if (pc == null) continue;
      try {
        // dispose, which closes too: close first would drop the connection
        // from the plugin's map and leave its observer behind.
        await pc.dispose();
      } catch (e, s) {
        Log.onError(e, s, content: 'DJ booth: could not close the monitor');
      }
    }
  }
}
