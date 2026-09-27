// Changes to a call's microphone capture run one at a time, and one that
// never finishes (a getUserMedia left behind a permission prompt) does not
// hold every later repair up for the rest of the call.
import 'dart:async';

import 'package:commet/client/matrix/components/voip_room/livekit_microphone.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('changes run one after the other', () async {
    final changes = CaptureChanges();
    final order = <String>[];
    final first = Completer<void>();
    final a = changes.run(() async {
      order.add('a starts');
      await first.future;
      order.add('a ends');
    });
    final b = changes.run(() async => order.add('b'));
    await Future<void>.delayed(Duration.zero);
    expect(order, ['a starts']);
    first.complete();
    await Future.wait([a, b]);
    expect(order, ['a starts', 'a ends', 'b']);
  });

  test('a failed change does not stop the next', () async {
    final changes = CaptureChanges();
    final failed = changes.run<void>(() async => throw Exception('busy'));
    await expectLater(failed, throwsException);
    expect(await changes.run(() async => 'next'), 'next');
  });

  test('a change that never finishes lets the next one run after the limit',
      () async {
    final changes = CaptureChanges(limit: const Duration(milliseconds: 200));
    unawaited(changes.run(() => Completer<void>().future));
    final next = await changes
        .run(() async => 'ran')
        .timeout(const Duration(seconds: 5));
    expect(next, 'ran');
  });
}
