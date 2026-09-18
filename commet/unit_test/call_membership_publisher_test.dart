import 'dart:async';

import 'package:commet/client/components/activities/activities_component.dart';
import 'package:commet/client/matrix/components/voip_room/call_membership_publisher.dart';
import 'package:flutter_test/flutter_test.dart';

const screen = CallMembershipState(media: {LiveMedia.screen});
const screenAndCamera =
    CallMembershipState(media: {LiveMedia.screen, LiveMedia.camera});
const camera = CallMembershipState(media: {LiveMedia.camera});
const muted = CallMembershipState(voice: {VoiceState.muted});
const nothing = CallMembershipState();

void main() {
  late List<CallMembershipState> writes;
  late Completer<void>? pendingWrite;
  late int failuresLeft;
  late CallMembershipPublisher publisher;

  setUp(() {
    writes = [];
    pendingWrite = null;
    failuresLeft = 0;
    publisher = CallMembershipPublisher(
      write: (state) async {
        writes.add(state);
        if (failuresLeft > 0) {
          failuresLeft--;
          throw Exception('M_LIMIT_EXCEEDED');
        }
        await pendingWrite?.future;
      },
      debounce: const Duration(milliseconds: 750),
      minInterval: const Duration(seconds: 2),
    );
  });

  // testWidgets fails a test that leaves timers behind.
  Future<void> finish() => publisher.stop();

  testWidgets('publishes a change once it settles', (tester) async {
    publisher.update(screen);
    await tester.pump(const Duration(milliseconds: 700));
    expect(writes, isEmpty);

    await tester.pump(const Duration(milliseconds: 100));
    expect(writes, [screen]);

    await finish();
  });

  testWidgets('a quick toggle back to where it started writes nothing',
      (tester) async {
    publisher.update(screen);
    await tester.pump(const Duration(milliseconds: 100));
    publisher.update(nothing);
    await tester.pump(const Duration(seconds: 5));

    expect(writes, isEmpty);

    await finish();
  });

  testWidgets('waits between writes and then sends the newest value',
      (tester) async {
    publisher.update(screen);
    await tester.pump(const Duration(milliseconds: 800));
    publisher.update(screenAndCamera);
    await tester.pump(const Duration(milliseconds: 800));
    publisher.update(camera);
    await tester.pump(const Duration(milliseconds: 800));
    expect(writes, [screen]);

    await tester.pump(const Duration(seconds: 2));
    expect(writes, [screen, camera]);

    await finish();
  });

  testWidgets('writes one value at a time', (tester) async {
    pendingWrite = Completer();
    publisher.update(screen);
    await tester.pump(const Duration(milliseconds: 800));
    publisher.update(camera);
    await tester.pump(const Duration(seconds: 5));
    expect(writes, [screen]);

    pendingWrite!.complete();
    pendingWrite = null;
    await tester.pump(const Duration(seconds: 3));
    expect(writes, [screen, camera]);

    await finish();
  });

  testWidgets('a failed write is tried again later', (tester) async {
    failuresLeft = 1;
    publisher.update(screen);
    await tester.pump(const Duration(milliseconds: 800));
    expect(writes, [screen]);

    await tester.pump(const Duration(seconds: 5));
    expect(writes, [screen, screen]);

    await tester.pump(const Duration(seconds: 30));
    expect(writes, [screen, screen]);

    await finish();
  });

  testWidgets(
      'stopping drops what is pending and waits for the write in flight',
      (tester) async {
    pendingWrite = Completer();
    publisher.update(screen);
    await tester.pump(const Duration(milliseconds: 800));
    publisher.update(camera);

    var stopped = false;
    unawaited(publisher.stop().then((_) => stopped = true));
    await tester.pump();
    expect(stopped, isFalse);

    pendingWrite!.complete();
    await tester.pump();
    expect(stopped, isTrue);

    publisher.update(screenAndCamera);
    await tester.pump(const Duration(seconds: 10));
    expect(writes, [screen]);
  });

  testWidgets('muting is a change even though the streams are the same',
      (tester) async {
    publisher.update(muted);
    await tester.pump(const Duration(milliseconds: 800));
    expect(writes, [muted]);

    // Same value again: nothing to say.
    publisher.update(muted);
    await tester.pump(const Duration(seconds: 5));
    expect(writes, [muted]);

    publisher.update(nothing);
    await tester.pump(const Duration(seconds: 5));
    expect(writes, [muted, nothing]);

    await finish();
  });
}
