// When the screen share and camera sounds play: on a start only, once,
// whatever event reported it, and never for what was already live.
import 'package:commet/client/components/voip/share_cues.dart';
import 'package:test/test.dart';

void main() {
  late DateTime clock;
  late ShareCueTracker tracker;

  setUp(() {
    clock = DateTime(2026, 9, 28, 12);
    tracker = ShareCueTracker(now: () => clock);
  });

  void later([Duration by = const Duration(seconds: 2)]) =>
      clock = clock.add(by);

  test('joining a call where people already share plays nothing', () {
    expect(
        tracker.update({
          '@a:x:D1': {ShareCue.screenShare, ShareCue.camera},
          '@b:x:D2': {ShareCue.camera},
        }),
        isEmpty);
  });

  test('a screen share starting plays its sound, once', () {
    tracker.update({'@a:x:D1': {}});
    later();
    expect(
        tracker.update({
          '@a:x:D1': {ShareCue.screenShare}
        }),
        [ShareCue.screenShare]);
    // The same share reported again (a publish, then an unmute).
    later();
    expect(
        tracker.update({
          '@a:x:D1': {ShareCue.screenShare}
        }),
        isEmpty);
  });

  test('a camera turning on plays the camera sound', () {
    tracker.update({});
    later();
    expect(
        tracker.update({
          '@b:x:D2': {ShareCue.camera}
        }),
        [ShareCue.camera]);
  });

  test('stopping plays nothing, starting again plays again', () {
    tracker.update({
      '@a:x:D1': {ShareCue.camera}
    });
    later();
    expect(tracker.update({'@a:x:D1': {}}), isEmpty);
    later();
    expect(
        tracker.update({
          '@a:x:D1': {ShareCue.camera}
        }),
        [ShareCue.camera]);
  });

  test('both starting at once play both sounds', () {
    tracker.update({});
    later();
    expect(
        tracker.update({
          '@a:x:D1': {ShareCue.screenShare, ShareCue.camera}
        }),
        [ShareCue.screenShare, ShareCue.camera]);
  });

  test('several people starting within a second make one sound', () {
    tracker.update({});
    later();
    expect(
        tracker.update({
          '@a:x:D1': {ShareCue.camera}
        }),
        [ShareCue.camera]);
    later(const Duration(milliseconds: 300));
    expect(
        tracker.update({
          '@a:x:D1': {ShareCue.camera},
          '@b:x:D2': {ShareCue.camera},
        }),
        isEmpty);
    // But someone starting after that is heard.
    later();
    expect(
        tracker.update({
          '@a:x:D1': {ShareCue.camera},
          '@b:x:D2': {ShareCue.camera},
          '@c:x:D3': {ShareCue.camera},
        }),
        [ShareCue.camera]);
  });

  test('what a reconnect brings back plays nothing', () {
    tracker.update({
      '@a:x:D1': {ShareCue.screenShare}
    });
    later();
    // LiveKit drops everyone while it reconnects, then rebuilds the room.
    tracker.reconnected();
    expect(tracker.update({}, quiet: true), isEmpty);
    later();
    expect(
        tracker.update({
          '@a:x:D1': {ShareCue.screenShare}
        }),
        isEmpty);
    // Once the room has settled, a real start is heard again.
    later(ShareCueTracker.reconnectQuiet);
    expect(
        tracker.update({
          '@a:x:D1': {ShareCue.screenShare},
          '@b:x:D2': {ShareCue.camera},
        }),
        [ShareCue.camera]);
  });

  test('a quiet update learns what is live without playing', () {
    tracker.update({});
    later();
    expect(
        tracker.update({
          '@a:x:D1': {ShareCue.screenShare}
        }, quiet: true),
        isEmpty);
    later();
    expect(
        tracker.update({
          '@a:x:D1': {ShareCue.screenShare}
        }),
        isEmpty);
  });
}
