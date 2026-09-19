// Seams between the DJ booth's logic (dj_session.dart) and the platform: the
// data channel it talks over, the player that turns a queued track into the
// room's music track, and the resolver that turns a pasted link into tracks.
// Production adapters live in client/matrix/components/dj/; tests fake them.
import 'dart:async';

import 'package:commet/client/components/dj/dj_links.dart';
import 'package:commet/client/components/dj/dj_models.dart';

/// A booth message from another participant, sender as LiveKit identity.
class DjIncoming {
  final String sender;
  final Map<String, Object?> message;

  const DjIncoming(this.sender, this.message);
}

abstract class DjTransport {
  /// Our LiveKit identity.
  String get selfIdentity;

  /// Sends to everyone in the call, or only to [to].
  Future<void> send(Map<String, Object?> message, {List<String>? to});

  Stream<DjIncoming> get incoming;

  Stream<String> get participantJoined;

  Stream<String> get participantLeft;

  /// We were cut off and are back. Messages sent meanwhile may be lost, and
  /// LiveKit reports everyone as having left and come back.
  Stream<void> get reconnected;

  /// Whether [identity] is in the call right now.
  bool isPresent(String identity);

  Future<void> dispose();
}

enum DjEngineState {
  /// Nothing loaded.
  idle,

  /// Loaded, waiting for audio (a stalled decoder).
  buffering,
  playing,
  paused,

  /// The loaded track played to its end.
  ended,

  /// The loaded track could not be decoded.
  error,
}

class DjEngineStatus {
  final DjEngineState state;

  /// [DjTrack.id] of the loaded track.
  final String? trackId;
  final int positionMs;

  /// 0 when unknown.
  final int durationMs;

  const DjEngineStatus(
      {required this.state,
      this.trackId,
      this.positionMs = 0,
      this.durationMs = 0});

  static const idle = DjEngineStatus(state: DjEngineState.idle);
}

/// What fetching a track learned about it.
class DjTrackInfo {
  final String? title;
  final String? artist;
  final int? durationMs;
  final String? thumbnail;

  const DjTrackInfo({this.title, this.artist, this.durationMs, this.thumbnail});
}

/// The DJ's player: fetches tracks and plays them into the published music
/// track. Only exists on the DJ's client, and only on desktop.
abstract class DjPlaybackEngine {
  /// Publishes the music track (silent until something plays).
  Future<void> start();

  /// Stops the music, unpublishes the track and releases everything.
  Future<void> shutdown();

  /// Fetches [track] so [load] can start it. Safe to call again for a track
  /// that is already here, and for several tracks at once. The slow part.
  Future<DjTrackInfo> prepare(DjTrack track);

  /// Plays a [prepare]d [track] from [positionMs], replacing whatever was
  /// loaded. Quick; throws when the file can't be played. Kept apart from
  /// [prepare] so a download that finishes late can never start a song the
  /// booth has moved past.
  void load(DjTrack track, {required int positionMs, required bool paused});

  void setPaused(bool paused);

  Future<void> seek(int positionMs);

  /// Silence, nothing loaded.
  void unload();

  DjEngineStatus get status;

  /// How loud the DJ hears their own music, 0..1.
  set monitorVolume(double volume);
}

/// Turns pasted links into tracks.
abstract class DjResolver {
  Future<List<DjTrack>> resolve(DjLink link, {required String addedBy});
}

/// Something the booth wants the user to know (a track that failed, a
/// handoff that did not happen).
class DjNotice {
  final String message;
  final bool isError;

  const DjNotice(this.message, {this.isError = false});

  @override
  String toString() => message;
}

/// A link being resolved into tracks, shown in the add bar until it lands.
class DjPendingAdd {
  final String id;
  final DjLink link;

  const DjPendingAdd(this.id, this.link);
}
