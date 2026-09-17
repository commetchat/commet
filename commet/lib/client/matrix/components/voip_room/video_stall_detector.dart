/// What a remote video stream should do after a stats sample.
enum VideoStallAction {
  none,

  /// The first frame was decoded. Rebuilding the renderer attaches it again,
  /// which is what used to recover a tile left black until something else
  /// happened to rebuild the call view.
  firstFrame,

  /// The track is subscribed, active and on screen, but nothing was decoded
  /// for [VideoStallDetector.stallAfter]: subscribe to it again.
  recover,
}

/// Notices a subscribed remote video that never shows a frame (issue #47).
///
/// Only a track that has not decoded anything yet counts as stalled: a shared
/// screen that does not change sends no new frames, so a frame counter that
/// stops moving is not a problem.
class VideoStallDetector {
  VideoStallDetector({
    this.stallAfter = const Duration(seconds: 6),
    this.maxRecoveries = 3,
  });

  final Duration stallAfter;

  /// Recoveries allowed before a frame shows up. Stops a track that can never
  /// be decoded from being resubscribed forever.
  final int maxRecoveries;

  DateTime? _waitingSince;
  bool _sawFrame = false;
  int _recoveries = 0;

  int get recoveries => _recoveries;

  /// [watching] is false while no frames are expected: not subscribed, muted,
  /// paused by the server, or not on screen (adaptive stream pauses it).
  VideoStallAction sample({
    required bool watching,
    required num? framesDecoded,
    required DateTime now,
  }) {
    if (!watching) {
      _waitingSince = null;
      return VideoStallAction.none;
    }

    if (framesDecoded != null && framesDecoded > 0) {
      _waitingSince = null;
      if (_sawFrame) return VideoStallAction.none;
      _sawFrame = true;
      _recoveries = 0;
      return VideoStallAction.firstFrame;
    }

    if (_sawFrame) return VideoStallAction.none;

    final since = _waitingSince ??= now;
    if (now.difference(since) < stallAfter) return VideoStallAction.none;
    if (_recoveries >= maxRecoveries) return VideoStallAction.none;

    _recoveries++;
    _waitingSince = null;
    return VideoStallAction.recover;
  }

  /// A new track replaced the old one: its frame counter starts over, and so
  /// does its recovery budget. Without that, a tile that was resubscribed
  /// three times without ever being on screen could never recover again.
  void trackChanged() {
    _waitingSince = null;
    _sawFrame = false;
    _recoveries = 0;
  }
}
