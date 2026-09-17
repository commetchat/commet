import 'package:commet/client/matrix/components/voip_room/video_stall_detector.dart';
import 'package:test/test.dart';

void main() {
  late VideoStallDetector detector;
  final start = DateTime(2026, 9, 16, 12);

  DateTime at(int seconds) => start.add(Duration(seconds: seconds));

  VideoStallAction sample(int seconds,
          {bool watching = true, num? framesDecoded = 0}) =>
      detector.sample(
          watching: watching, framesDecoded: framesDecoded, now: at(seconds));

  setUp(() {
    detector = VideoStallDetector(
        stallAfter: const Duration(seconds: 6), maxRecoveries: 3);
  });

  test('a video that never decodes a frame gets subscribed again', () {
    expect(sample(0), VideoStallAction.none);
    expect(sample(4), VideoStallAction.none);
    expect(sample(6), VideoStallAction.recover);
  });

  test('the first decoded frame rebuilds the renderer once', () {
    expect(sample(0), VideoStallAction.none);
    expect(sample(2, framesDecoded: 1), VideoStallAction.firstFrame);
    expect(sample(4, framesDecoded: 30), VideoStallAction.none);
  });

  test('a static shared screen that stops sending frames is not a stall', () {
    sample(0, framesDecoded: 1);
    expect(sample(60, framesDecoded: 1), VideoStallAction.none);
  });

  test('video nobody expects frames from does not count toward a stall', () {
    expect(sample(0, watching: false), VideoStallAction.none);
    expect(sample(10, watching: false), VideoStallAction.none);
    // Back on screen: the wait starts now, not when it was hidden.
    expect(sample(12), VideoStallAction.none);
    expect(sample(16), VideoStallAction.none);
    expect(sample(18), VideoStallAction.recover);
  });

  test('missing stats count as no frames', () {
    sample(0, framesDecoded: null);
    expect(sample(6, framesDecoded: null), VideoStallAction.recover);
  });

  test('gives up after a few recoveries that bring no frame', () {
    expect(sample(0), VideoStallAction.none);
    expect(sample(6), VideoStallAction.recover);
    // Each attempt is given the full wait again before the next one.
    expect(sample(12), VideoStallAction.none);
    expect(sample(18), VideoStallAction.recover);
    expect(sample(24), VideoStallAction.none);
    expect(sample(30), VideoStallAction.recover);
    // Out of attempts: a track that can never be decoded is left alone.
    expect(sample(36), VideoStallAction.none);
    expect(sample(60), VideoStallAction.none);
  });

  test('a replaced track gets the recovery budget back', () {
    sample(0);
    for (final seconds in [6, 18, 30]) {
      expect(sample(seconds), VideoStallAction.recover);
      expect(sample(seconds + 6), VideoStallAction.none);
    }
    expect(sample(42), VideoStallAction.none);

    // A tile that spent its budget while it had no size on screen still
    // recovers once a new track arrives (issue #47).
    detector.trackChanged();
    expect(sample(44), VideoStallAction.none);
    expect(sample(50), VideoStallAction.recover);
  });

  test('a new track is watched from scratch and a frame resets the budget', () {
    sample(0);
    sample(6);
    detector.trackChanged();
    expect(sample(7, framesDecoded: 5), VideoStallAction.firstFrame);
    expect(detector.recoveries, 0);

    // The track is replaced (a resubscribe after a network blip).
    detector.trackChanged();
    expect(sample(8), VideoStallAction.none);
    expect(sample(14), VideoStallAction.recover);
    expect(sample(15, framesDecoded: 1), VideoStallAction.firstFrame);
  });
}
