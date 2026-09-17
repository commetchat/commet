import 'package:livekit_client/livekit_client.dart' as lk;

/// Which remote screen shares the local user watches (issue #50).
///
/// Like Discord, a screen share doesn't play until you opt in: the session
/// connects without auto-subscribing and only subscribes to a participant's
/// screen share video and screen share audio while they are watched. Their
/// mic and camera are always subscribed.
///
/// Keyed by LiveKit participant identity, so watching survives the sharer
/// publishing their screen audio after the video, and ends with the share.
class ScreenShareWatchList {
  ScreenShareWatchList({bool Function()? autoWatch})
      : _autoWatch = autoWatch ?? _never;

  static bool _never() => false;

  final bool Function() _autoWatch;
  final Set<String> _watching = {};

  static bool isScreenShareSource(lk.TrackSource source) =>
      source == lk.TrackSource.screenShareVideo ||
      source == lk.TrackSource.screenShareAudio;

  bool isWatching(String identity) => _watching.contains(identity);

  /// Whether the local user should be subscribed to a track of [source]
  /// published by [identity].
  bool shouldSubscribe(String identity, lk.TrackSource source) =>
      !isScreenShareSource(source) || isWatching(identity);

  /// Returns whether anything changed.
  bool watch(String identity) => _watching.add(identity);

  /// Returns whether anything changed.
  bool stopWatching(String identity) => _watching.remove(identity);

  /// [identity] started sharing their screen. With auto-watch on, it plays
  /// straight away, the behaviour from before issue #50. Returns whether
  /// watching started now.
  bool onScreenSharePublished(String identity) =>
      _autoWatch() && _watching.add(identity);

  /// Stops watching everyone [stillSharing] is false for.
  void retainWhere(bool Function(String identity) stillSharing) =>
      _watching.retainWhere(stillSharing);

  /// [identity] stopped sharing their screen: their next share needs opting
  /// in again. Also called when they leave the call, which unpublishes it.
  void onScreenShareEnded(String identity) => _watching.remove(identity);
}
