import 'dart:async';

class VideoPlayerController {
  Future<void> Function()? _onPause;

  Future<void> Function()? _onPlay;

  Future<void> Function()? _onReplay;

  Future<void> Function(Duration percent)? _seekTo;

  Future<Duration> Function()? _getLength;

  final StreamController<bool> _isBuffering = StreamController.broadcast();

  final StreamController<bool> _isCompleted = StreamController.broadcast();

  final StreamController<Duration> _onProgressed = StreamController.broadcast();

  Stream<bool> get isBuffering => _isBuffering.stream;

  Stream<bool> get isCompleted => _isCompleted.stream;

  Stream<Duration> get onProgressed => _onProgressed.stream;

  void attach(
      {required Future<void> Function() pause,
      required Future<void> Function() play,
      required Future<void> Function() replay,
      required Future<Duration> Function() getLength,
      required Future<void> Function(Duration percent) seekTo}) {
    _onPause = pause;
    _onPlay = play;
    _onReplay = replay;
    _seekTo = seekTo;
    _getLength = getLength;
  }

  Future<void> pause() async {
    await _onPause!.call();
  }

  Future<void> play() async {
    await _onPlay!.call();
  }

  Future<void> replay() async {
    await _onReplay!.call();
  }

  Future<void> seekTo(Duration duration) async {
    await _seekTo!.call(duration);
  }

  void setBuffering(bool isBuffering) {
    _isBuffering.add(isBuffering);
  }

  void setCompleted(bool isBuffering) {
    _isCompleted.add(isBuffering);
  }

  void setProgress(Duration progress) {
    _onProgressed.add(progress);
  }

  Future<Duration> getLength() async {
    return await _getLength!.call();
  }
}
