// The microphone watch of a call: a capture that stops handing audio to the
// sender (Windows' capture thread dying, a killed PulseAudio stream), a
// capture track that ended, and a sender that sends nothing while the user
// speaks are repaired, cheapest repair first, and never while the user is
// muted.
import 'dart:async';

import 'package:collection/collection.dart';
import 'package:commet/client/components/voip/microphone_health.dart';
import 'package:flutter_test/flutter_test.dart';

/// A microphone in a fake call, with a clock that only moves when told.
class _Call {
  DateTime now = DateTime(2026, 9, 26, 12);
  bool sending = true;
  bool ended = false;
  bool flowing = true;
  bool statsAvailable = true;
  bool talking = false;
  bool packetsFlow = true;
  bool missing = false;
  bool processing = true;
  double captured = 0;
  int packets = 0;

  final List<MicrophoneRepair> repairs = [];
  final List<MicrophoneFault> gaveUp = [];
  int recovered = 0;

  /// What each repair does to the microphone.
  void Function(MicrophoneRepair repair) onRepair = (_) {};
  Object? repairError;
  bool repairHangs = false;

  late final monitor = MicrophoneHealthMonitor(
    now: () => now,
    read: () async => MicrophoneVitals(
      sending: sending && !missing,
      // As the room reads it: missing only while the user wants to be heard.
      missing: missing && sending,
      processing: processing,
      captureEnded: ended,
      capturedSeconds: statsAvailable ? captured : null,
      packetsSent: statsAvailable ? packets : null,
      talking: talking,
    ),
    repair: (repair) async {
      repairs.add(repair);
      if (repairHangs) return Completer<void>().future;
      final error = repairError;
      if (error != null) throw error;
      onRepair(repair);
    },
    onGaveUp: gaveUp.add,
    onRecovered: () => recovered++,
  );

  /// Lets [seconds] of call go by, checking once a second as the session
  /// does.
  Future<void> run(int seconds) async {
    for (var i = 0; i < seconds; i++) {
      now = now.add(const Duration(seconds: 1));
      if (sending && flowing && !ended) captured += 1;
      if (sending && packetsFlow) packets += talking ? 50 : 2;
      await monitor.check();
    }
  }
}

void main() {
  test('a working microphone is left alone', () async {
    final call = _Call();
    await call.run(120);
    expect(call.repairs, isEmpty);
    expect(call.monitor.fault, isNull);
  });

  test('speaking or quiet, a working microphone is left alone', () async {
    final call = _Call();
    for (var i = 0; i < 20; i++) {
      call.talking = i.isEven;
      await call.run(5);
    }
    expect(call.repairs, isEmpty);
  });

  test('a capture that stops handing over audio is reopened', () async {
    final call = _Call()..onRepair = (_) {};
    await call.run(10);
    call.flowing = false;
    await call.run(3);
    expect(call.repairs, [MicrophoneRepair.reopen]);
    expect(call.monitor.fault, MicrophoneFault.captureStalled);
  });

  test('a reopen that brings the capture back ends the repairs', () async {
    final call = _Call();
    call.onRepair = (_) => call.flowing = true;
    await call.run(10);
    call.flowing = false;
    await call.run(20);
    expect(call.repairs, [MicrophoneRepair.reopen]);
    expect(call.recovered, 1);
    expect(call.monitor.fault, isNull);
    expect(call.monitor.attempts, 0);
  });

  test('repairs escalate while the capture stays dead, then keep retrying',
      () async {
    final call = _Call();
    await call.run(10);
    call.flowing = false;
    await call.run(12);
    expect(call.repairs, [
      MicrophoneRepair.reopen,
      MicrophoneRepair.restart,
      MicrophoneRepair.republish,
    ]);
    expect(call.gaveUp, [MicrophoneFault.captureStalled],
        reason: 'the user is told once the ladder is exhausted');

    await call.run(600);
    expect(call.repairs.length, greaterThan(10),
        reason: 'a dead microphone is never given up on for good');
    expect(call.repairs.skip(3), everyElement(MicrophoneRepair.republish));
    expect(call.gaveUp, hasLength(1), reason: 'told once, not every retry');

    call.onRepair = (_) => call.flowing = true;
    await call.run(120);
    expect(call.recovered, 1);
    expect(call.monitor.fault, isNull);
  });

  test('the retries are spaced out', () async {
    final call = _Call();
    await call.run(10);
    call.flowing = false;
    await call.run(3600);
    // Three quick repairs, then at most one a minute or so.
    expect(call.repairs.length, lessThan(3 + 3600 ~/ 60 + 5));
  });

  test('a muted microphone is never repaired', () async {
    final call = _Call();
    await call.run(10);
    call.sending = false;
    call.flowing = false;
    await call.run(120);
    expect(call.repairs, isEmpty);
    expect(call.monitor.fault, isNull);
  });

  test('an unmuted microphone gets time to start before it is judged',
      () async {
    final call = _Call()..sending = false;
    await call.run(10);
    call.sending = true;
    call.flowing = false;
    await call.run(2);
    expect(call.repairs, isEmpty);
    await call.run(3);
    expect(call.repairs, [MicrophoneRepair.reopen]);
  });

  test('unmuting starts the repairs over', () async {
    final call = _Call();
    await call.run(10);
    call.flowing = false;
    await call.run(12);
    expect(call.repairs, hasLength(3));

    call.sending = false;
    await call.run(5);
    call.sending = true;
    call.repairs.clear();
    await call.run(10);
    expect(call.repairs.first, MicrophoneRepair.reopen);
  });

  test('an ended capture track is repaired', () async {
    final call = _Call();
    call.onRepair = (_) => call.ended = false;
    await call.run(10);
    call.ended = true;
    await call.run(1);
    expect(call.repairs, [MicrophoneRepair.reopen]);
    expect(call.monitor.fault, MicrophoneFault.captureEnded);
    await call.run(10);
    expect(call.recovered, 1);
  });

  test('speaking while nothing is sent is repaired', () async {
    final call = _Call();
    await call.run(10);
    call.talking = true;
    call.packetsFlow = false;
    await call.run(4);
    expect(call.monitor.fault, MicrophoneFault.sendStalled);
    expect(call.repairs, [MicrophoneRepair.reopen]);
  });

  test('a microphone that is no longer published is published again', () async {
    final call = _Call();
    call.onRepair = (_) => call.missing = false;
    await call.run(10);
    call.missing = true;
    await call.run(4);
    expect(call.repairs, [MicrophoneRepair.republish],
        reason: 'nothing to reopen or restart without a microphone');
    expect(call.monitor.fault, MicrophoneFault.missing);
    await call.run(10);
    expect(call.recovered, 1);
  });

  test('a missing microphone the user muted is left alone', () async {
    final call = _Call();
    await call.run(10);
    call.missing = true;
    call.sending = false;
    await call.run(60);
    expect(call.repairs, isEmpty);
  });

  // LiveKit republishes every track after a full reconnect, one at a time:
  // the microphone is gone for a moment and must not be published twice.
  test('a microphone gone for a moment is not published again', () async {
    final call = _Call();
    await call.run(10);
    call.missing = true;
    await call.run(2);
    call.missing = false;
    await call.run(20);
    expect(call.repairs, isEmpty);
  });

  test('a capture seen once before its statistics went away is no stall',
      () async {
    final call = _Call();
    await call.run(10);
    call.statsAvailable = false;
    call.flowing = false;
    await call.run(30);
    expect(call.repairs, isEmpty);
    expect(call.monitor.captureFlowing, isNot(isFalse));
  });

  test('a read that never answers does not stop the watch', () async {
    var hang = true;
    var captured = 0.0;
    var now = DateTime(2026);
    final repairs = <MicrophoneRepair>[];
    final monitor = MicrophoneHealthMonitor(
      now: () => now,
      read: () async {
        if (hang) return Completer<MicrophoneVitals>().future;
        return MicrophoneVitals(sending: true, capturedSeconds: captured);
      },
      repair: (r) async => repairs.add(r),
    );
    await monitor.check(); // times out on the real clock
    hang = false;
    for (var i = 0; i < 10; i++) {
      now = now.add(const Duration(seconds: 1));
      await monitor.check();
    }
    expect(repairs.firstOrNull, MicrophoneRepair.reopen,
        reason: 'the frozen capture after the hung read is still repaired');
  }, timeout: const Timeout(Duration(seconds: 30)));

  test('a DSP that stops between the capture and the sender is restarted',
      () async {
    final call = _Call();
    call.onRepair = (_) => call.processing = true;
    await call.run(10);
    call.processing = false;
    await call.run(1);
    expect(call.repairs, isEmpty, reason: 'one report late is not a stall');
    await call.run(2);
    expect(call.repairs, [MicrophoneRepair.reopen]);
    expect(call.monitor.fault, MicrophoneFault.processingStalled);
    await call.run(10);
    expect(call.recovered, 1);
  });

  test('silence sends nothing with DTX, and that is fine', () async {
    final call = _Call();
    await call.run(10);
    call.talking = false;
    call.packetsFlow = false;
    await call.run(120);
    expect(call.repairs, isEmpty);
  });

  test('a new sender counting from zero is not a stall', () async {
    final call = _Call();
    await call.run(30);
    call.captured = 0;
    await call.run(30);
    expect(call.repairs, isEmpty);
  });

  test('without statistics nothing is judged on them', () async {
    final call = _Call()..statsAvailable = false;
    await call.run(10);
    call.flowing = false;
    call.talking = true;
    await call.run(60);
    expect(call.repairs, isEmpty);
  });

  test('a failing repair moves on to the next one', () async {
    final call = _Call()..repairError = Exception('device busy');
    await call.run(10);
    call.flowing = false;
    await call.run(10);
    expect(call.repairs.take(2),
        [MicrophoneRepair.reopen, MicrophoneRepair.restart]);
  });

  test('a repair that never returns does not stop the watch', () async {
    final call = _Call()..repairHangs = true;
    await call.run(10);
    call.flowing = false;
    // The hung repair times out on the real clock.
    await call.run(3);
    expect(call.repairs, [MicrophoneRepair.reopen]);
  }, timeout: const Timeout(Duration(seconds: 30)));

  test('a check still running makes the next one a no-op', () async {
    final call = _Call();
    final slow = Completer<void>();
    call.onRepair = (_) {};
    await call.run(10);
    call.flowing = false;
    call.now = call.now.add(const Duration(seconds: 3));
    final monitor = MicrophoneHealthMonitor(
      now: () => call.now,
      read: () async {
        await slow.future;
        return const MicrophoneVitals(sending: true, capturedSeconds: 0);
      },
      repair: (r) async => call.repairs.add(r),
    );
    final first = monitor.check();
    await monitor.check();
    slow.complete();
    await first;
    expect(call.repairs, isEmpty);
  });

  test('only the platform\'s repairs are used', () async {
    final call = _Call();
    final repairs = <MicrophoneRepair>[];
    var captured = 0.0;
    var now = DateTime(2026);
    final monitor = MicrophoneHealthMonitor(
      now: () => now,
      ladder: const [MicrophoneRepair.restart, MicrophoneRepair.republish],
      read: () async =>
          MicrophoneVitals(sending: true, capturedSeconds: captured),
      repair: (r) async => repairs.add(r),
    );
    for (var i = 0; i < 60; i++) {
      now = now.add(const Duration(seconds: 1));
      if (i < 10) captured += 1;
      await monitor.check();
    }
    expect(repairs.take(2),
        [MicrophoneRepair.restart, MicrophoneRepair.republish]);
    expect(repairs, isNot(contains(MicrophoneRepair.reopen)));
    expect(call.repairs, isEmpty);
  });
}
