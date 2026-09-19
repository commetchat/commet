// Adversarial review of the DJ booth UI. Each test states the behaviour the
// feature should have; a failing test is a confirmed bug.
import 'dart:async';

import 'package:commet/client/client.dart';
import 'package:commet/client/components/dj/dj_engine.dart';
import 'package:commet/client/components/dj/dj_links.dart';
import 'package:commet/client/components/dj/dj_models.dart';
import 'package:commet/client/components/dj/dj_session.dart';
import 'package:commet/client/components/voip/voip_session.dart';
import 'package:commet/client/components/voip/voip_stream.dart';
import 'package:commet/client/member.dart';
import 'package:commet/main.dart';
import 'package:commet/ui/atoms/adaptive_context_menu.dart';
import 'package:commet/ui/organisms/dj/dj_booth_panel.dart';
import 'package:commet/ui/organisms/dj/dj_member_ui.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tiamat/config/style/theme_extensions.dart';
import 'package:tiamat/tiamat.dart' as tiamat;

import '../dj_fakes.dart';

class _Member implements Member {
  @override
  final String identifier;
  _Member(this.identifier);
  @override
  String get displayName => identifier.split(':').first.substring(1);
  @override
  ImageProvider? get avatar => null;
  @override
  Color get defaultColor => Colors.teal;
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Room implements Room {
  @override
  Member getMemberOrFallback(String id) => _Member(id);
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Client implements Client {
  @override
  Room? getRoom(String identifier) => _Room();
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Session implements VoipSession {
  @override
  Client get client => _Client();
  @override
  String get roomId => '!r:x';
  @override
  List<VoipStream> get streams => const [];
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// Never answers: the links stay "Adding ..." like a slow yt-dlp.
class _SlowResolver implements DjResolver {
  final _never = Completer<List<DjTrack>>();
  @override
  Future<List<DjTrack>> resolve(DjLink link, {required String addedBy}) =>
      _never.future;
}

DjSession _session(FakeCall call, String identity,
    {DjCaps caps = const DjCaps(canDj: true, platform: 'linux'),
    DjResolver? resolver}) {
  return DjSession(
    transport: call.join(identity),
    caps: caps,
    selfUserId: djUserIdOf(identity),
    engineFactory: caps.canDj ? () => FakeEngine(identity) : null,
    resolver: resolver ?? FakeResolver(),
    tickInterval: const Duration(seconds: 2),
    pollInterval: const Duration(milliseconds: 250),
  )..start();
}

Widget _app(Widget child, {Size size = const Size(380, 640)}) => MaterialApp(
      // As on the desktop app: compact density, shrink-wrapped tap targets.
      theme: ThemeData(platform: TargetPlatform.linux)
          .copyWith(extensions: const [ThemeSettings()]),
      home: Scaffold(
        body: Align(
          alignment: Alignment.topLeft,
          child: SizedBox.fromSize(size: size, child: child),
        ),
      ),
    );

Future<void> _drain(WidgetTester tester) async {
  for (var i = 0; i < 20; i++) {
    await tester.pump();
  }
}

Future<void> _teardown(WidgetTester tester, List<DjSession> sessions) async {
  await tester.pumpWidget(const SizedBox());
  for (final s in sessions) {
    unawaited(s.dispose());
  }
  await _drain(tester);
}

void main() {
  setUp(() async {
    // ignore: invalid_use_of_visible_for_testing_member
    SharedPreferences.setMockInitialValues({});
    await preferences.init();
  });

  testWidgets(
      'side panel (380 px) fits a DJ with several links being added, '
      'on a 640 px tall call', (tester) async {
    final call = FakeCall();
    final dj = _session(call, '@dj:x:D1', resolver: _SlowResolver());
    await dj.becomeDj();
    await _drain(tester);
    expect(dj.isDj, isTrue);

    dj.addLinks([
      for (var i = 0; i < 12; i++) 'https://www.youtube.com/watch?v=abcdefghij$i'
    ].join('\n'));

    await tester.pumpWidget(_app(DjBoothPanel(session: _Session(), dj: dj)));
    await tester.pump();

    final error = tester.takeException();
    await _teardown(tester, [dj]);
    expect(error, isNull,
        reason: 'the booth column is not scrollable: every pending link adds '
            'a row above the Expanded queue');
  });

  for (final height in [720.0, 560.0, 480.0, 420.0]) {
    testWidgets(
        'side panel fits a playing DJ with two people asking, ${height}px tall',
        (tester) async {
      final call = FakeCall();
      final dj = _session(call, '@dj:x:D1');
      final a = _session(call, '@a:x:A1');
      final b = _session(call, '@b:x:B1');
      await dj.becomeDj();
      await _drain(tester);
      dj.addTracks([track('s1'), track('s2'), track('s3')]);
      await _drain(tester);
      await a.requestDj(true);
      await b.requestDj(true);
      await _drain(tester);
      expect(dj.current, isNotNull);
      expect(dj.requests.length, 2);

      await tester.pumpWidget(_app(DjBoothPanel(session: _Session(), dj: dj),
          size: Size(368, height)));
      await tester.pump();
      // An overflow fails the test on its own, with the offending widget.
      await _teardown(tester, [dj, a, b]);
    });
  }

  testWidgets('links pasted while a handover is pending are not thrown away',
      (tester) async {
    final call = FakeCall();
    final dj = _session(call, '@dj:x:D1');
    final other = _session(call, '@b:x:B1');
    await dj.becomeDj();
    await _drain(tester);
    // Target that never takes the booth (no answer yet).
    other.dispose();
    dj.passTo('@b:x:B1');
    // passTo only needs caps; they arrived at start.
    await _drain(tester);

    await tester.pumpWidget(_app(DjBoothPanel(session: _Session(), dj: dj),
        size: const Size(380, 900)));
    await tester.pump();
    expect(dj.passTarget, '@b:x:B1');

    // Fixed: the add bar is locked (and says so) while the decks change
    // hands, and keeps whatever was typed before.
    final field = tester.widget<TextField>(find.byType(TextField));
    final locked = field.enabled == false;
    final hint = field.decoration?.hintText;
    await _teardown(tester, [dj]);
    expect(locked, isTrue);
    expect(hint, contains('Locked'));
  });

  testWidgets(
      'a listener whose caps never reached the DJ but who asked for the '
      'decks can be passed to', (tester) async {
    final call = FakeCall();
    final dj = _session(call, '@dj:x:D1');
    await dj.becomeDj();
    await _drain(tester);

    // The listener's single caps broadcast is lost (no retry once it has
    // the DJ's state).
    final transport = call.join('@l:x:L1')..drop.add('caps');
    final listener = DjSession(
      transport: transport,
      caps: const DjCaps(canDj: true, platform: 'linux'),
      selfUserId: '@l:x',
      engineFactory: () => FakeEngine('l'),
      resolver: FakeResolver(),
    )..start();
    await _drain(tester);
    await listener.requestDj(true);
    await _drain(tester);

    expect(dj.hasRequestedUser('@l:x'), isTrue, reason: 'the ✋ shows');
    final items =
        djMemberMenuItems(dj, userId: '@l:x', displayName: 'l');
    dj.passTo('@l:x:L1'); // what the panel's "Pass the decks" button does
    final passTarget = dj.passTarget;
    await _teardown(tester, [dj, listener]);

    expect(items.single.text, isNot(contains("can't DJ")),
        reason: 'a ✋ next to them, and the menu says their app cannot DJ');
    expect(passTarget, '@l:x:L1',
        reason: 'the enabled "Pass the decks" button does nothing');
  });

  testWidgets('right-click on a member row inside an activity box opens the '
      'member menu, not the activity one', (tester) async {
    await tester.pumpWidget(_app(
      AdaptiveContextMenu(
        items: [tiamat.ContextMenuItem(text: 'Clear Memberships')],
        child: Column(children: [
          AdaptiveContextMenu(
            items: [tiamat.ContextMenuItem(text: 'Pass the decks to b')],
            child: Container(
                key: const Key('row'),
                width: 200,
                height: 30,
                color: Colors.red),
          ),
        ]),
      ),
    ));
    await tester.tap(find.byKey(const Key('row')), buttons: kSecondaryButton);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Pass the decks to b'), findsWidgets);
    expect(find.text('Clear Memberships'), findsNothing);
  });

  testWidgets('the raised hand has a hover tooltip', (tester) async {
    final call = FakeCall();
    final dj = _session(call, '@dj:x:D1');
    final l = _session(call, '@l:x:L1');
    await dj.becomeDj();
    await _drain(tester);
    await l.requestDj(true);
    await _drain(tester);

    await tester.pumpWidget(_app(DjMemberBadges(dj: dj, userId: '@l:x')));
    expect(find.text(djHandEmoji), findsOneWidget);
    expect(find.byTooltip('Asked to be the DJ'), findsOneWidget);
    await _teardown(tester, [dj, l]);
  });

  testWidgets('editing a queued song does not use its text fields after '
      'disposing them', (tester) async {
    final call = FakeCall();
    final dj = _session(call, '@dj:x:D1');
    await dj.becomeDj();
    await _drain(tester);
    final song = track('a');

    await tester.pumpWidget(_app(Builder(
      builder: (context) => TextButton(
          onPressed: () => editDjTrack(context, dj, song),
          child: const Text('edit')),
    )));
    await tester.tap(find.text('edit'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(TextField, 'Title'));
    await tester.pump();
    await tester.enterText(find.widgetWithText(TextField, 'Title'), 'New');
    await tester.tap(find.text('Save'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    await tester.pump(const Duration(milliseconds: 300));
    final error = tester.takeException();
    await _teardown(tester, [dj]);
    expect(error, isNull);
  });
}
