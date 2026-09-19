// Adversarial review, round 2: user journeys through the DJ booth. Each test
// states the behaviour the feature should have; a failing test is a
// confirmed bug.
import 'dart:async';

import 'package:commet/client/components/dj/dj_engine.dart';
import 'package:commet/client/components/dj/dj_models.dart';
import 'package:commet/client/components/dj/dj_session.dart';
import 'package:commet/main.dart';
import 'package:commet/ui/organisms/dj/dj_member_ui.dart';
import 'package:commet/ui/organisms/dj/dj_toast.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../dj_fakes.dart';

DjSession _session(FakeCall call, String identity,
    {Future<bool> Function()? prepare,
    FakeEngine? engine,
    Duration passTimeout = const Duration(seconds: 90)}) {
  return DjSession(
    transport: call.join(identity),
    caps: const DjCaps(canDj: true, platform: 'linux'),
    selfUserId: djUserIdOf(identity),
    engineFactory: () => engine ?? FakeEngine(identity),
    resolver: FakeResolver(),
    prepareToDj: prepare,
    passTimeout: passTimeout,
  )..start();
}

Future<void> _wait(Duration d) => Future<void>.delayed(d);

void main() {
  setUp(() async {
    // ignore: invalid_use_of_visible_for_testing_member
    SharedPreferences.setMockInitialValues({});
    await preferences.init();
  });

  testWidgets(
      "booth notices reach the user on the app's main page, which has no "
      'Scaffold', (tester) async {
    // The app: MaterialApp(navigatorKey: navigator, home: AppView(...)); no
    // Scaffold anywhere in the main page (see gif_picker.dart: "the chat has
    // no Scaffold for a snack bar").
    await tester.pumpWidget(MaterialApp(
      navigatorKey: navigator,
      home: const Material(child: Text('main page')),
    ));

    // What DjBooths._showNotice does with a notice.
    DjToast.show("Couldn't hand the booth over: they left the call",
        isError: true);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    final error = tester.takeException();
    final shown =
        find.textContaining("Couldn't hand the booth over").evaluate().isNotEmpty;
    // Let it time out.
    await tester.pump(const Duration(seconds: 8));

    expect(error, isNull,
        reason: 'debug builds assert: no descendant Scaffolds to present to');
    expect(shown, isTrue,
        reason: 'release builds queue the SnackBar and never show it');
  });

  test(
      'the DJ passes the decks and hangs up while the target is still '
      'fetching the song: the target still takes over and the music goes on',
      () async {
    final call = FakeCall();
    final dj = _session(call, '@dj:x:D1');
    final targetEngine = FakeEngine('b')..gate = Completer<void>();
    final b = _session(call, '@b:x:B1', engine: targetEngine);
    await settle();
    await dj.becomeDj();
    await settle();
    dj.addTracks([track('s1'), track('s2')]);
    await settle();
    expect(dj.isPlaying, isTrue);

    dj.passTo('@b:x:B1');
    await settle();
    expect(b.isJoining, isTrue, reason: 'b is fetching the playing song');

    // "Here, take the decks, I'm off": the hang up closes the booth first.
    await dj.dispose();
    call.leave('@dj:x:D1');
    await settle();

    targetEngine.gate!.complete();
    await settle();
    final becameDj = b.isDj;
    final queueKept = b.queue.map((t) => t.id).toList();
    await b.dispose();

    expect(becameDj, isTrue,
        reason: "the old DJ's graceful leave bumps the epoch and clears the "
            'pass, so the target steps down: the music stops for everyone');
    expect(queueKept, ['s2']);
  });

  testWidgets(
      'the raised hand of someone who asked goes away (or can be taken back) '
      'once the DJ has left', (tester) async {
    final call = FakeCall();
    final dj = _session(call, '@dj:x:D1');
    final asker = _session(call, '@a:x:A1');
    final web = DjSession(
      transport: call.join('@w:x:W1'),
      caps: const DjCaps(canDj: false, platform: 'web'),
      selfUserId: '@w:x',
    )..start();
    Future<void> drain() async {
      for (var i = 0; i < 20; i++) {
        await tester.pump();
      }
    }

    await drain();
    unawaited(dj.becomeDj());
    await drain();
    unawaited(asker.requestDj(true));
    await drain();
    expect(web.hasRequestedUser('@a:x'), isTrue);

    // The DJ hangs up.
    unawaited(dj.dispose());
    await drain();
    call.leave('@dj:x:D1');
    await drain();
    expect(web.djIdentity, isNull, reason: 'the booth is free');

    // The asker tries to take the hand down: nothing happens.
    unawaited(asker.requestDj(false));
    await drain();

    await tester.pumpWidget(MaterialApp(
        home: Scaffold(body: DjMemberBadges(dj: web, userId: '@a:x'))));
    final handShown = find.text(djHandEmoji).evaluate().isNotEmpty;
    final askerStillAsking = asker.hasRequested;
    await tester.pumpWidget(const SizedBox());
    unawaited(asker.dispose());
    unawaited(web.dispose());
    await drain();

    expect(handShown, isFalse,
        reason: 'a ✋ "Asked to be the DJ" stays next to them for everyone, '
            'with no DJ to ask');
    expect(askerStillAsking, isFalse,
        reason: 'requestDj(false) returns early when the booth has no DJ');
  });

  test(
      'a target who says "Not now" to the setup prompt during a pass is not '
      'shown an error written about someone else', () async {
    final call = FakeCall();
    final dj = _session(call, '@dj:x:D1');
    final b = _session(call, '@b:x:B1', prepare: () async => false);
    final notices = <DjNotice>[];
    b.notices.listen(notices.add);
    await settle();
    await dj.becomeDj();
    await settle();
    dj.addTracks([track('s1')]);
    await settle();

    dj.passTo('@b:x:B1');
    await settle();
    await dj.dispose();
    await b.dispose();

    final messages = notices.map((n) => n.message).toList();
    expect(
        notices.where(
            (n) => n.isError && n.message.contains("they aren't set up")),
        isEmpty,
        reason: 'the user just chose "Not now" and gets a red "Couldn\'t take '
            'over the booth: they aren\'t set up to DJ": $messages');
  });

  test('someone handed the decks without asking is told they are the DJ now',
      () async {
    final call = FakeCall();
    final dj = _session(call, '@dj:x:D1');
    final b = _session(call, '@b:x:B1');
    final notices = <DjNotice>[];
    b.notices.listen(notices.add);
    await settle();
    await dj.becomeDj();
    await settle();
    dj.addTracks([track('s1')]);
    await settle();

    dj.passTo('@b:x:B1'); // b never asked
    await settle();
    final becameDj = b.isDj;
    await dj.dispose();
    await b.dispose();

    expect(becameDj, isTrue, reason: 'taken over with no user action');
    expect(notices, isNotEmpty,
        reason: 'with the booth closed, nothing tells b that their app is '
            'now playing music to the whole call');
  });

  test(
      'the pass times out while the target is still on the setup prompt: '
      'the target is told the handover was called off', () async {
    final call = FakeCall();
    final dj =
        _session(call, '@dj:x:D1', passTimeout: const Duration(milliseconds: 200));
    final consent = Completer<bool>();
    final b = _session(call, '@b:x:B1', prepare: () => consent.future);
    final notices = <DjNotice>[];
    b.notices.listen(notices.add);
    await settle();
    await dj.becomeDj();
    await settle();
    dj.addTracks([track('s1')]);
    await settle();

    dj.passTo('@b:x:B1');
    await settle();
    expect(b.isJoining, isTrue);
    await _wait(const Duration(milliseconds: 300));
    await settle();
    expect(dj.passTarget, isNull, reason: 'the DJ gave up');

    // The user finally clicks "Download" and the tools install.
    consent.complete(true);
    await settle();
    final role = b.role;
    await dj.dispose();
    await b.dispose();

    expect(role, DjRole.listener);
    expect(notices, isNotEmpty,
        reason: 'b agreed to download ~60 MB to take the decks, and the '
            'booth silently drops the pass');
  });
}
