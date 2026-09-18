import 'dart:async';

import 'package:commet/client/components/voip/voip_session.dart';
import 'package:commet/ui/molecules/screen_share_stop_reporting.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// A session whose stop can be made to throw or to return without ending the
/// share, so the reporting helper is driven on its own instead of through the
/// heavy call widget dependencies.
class _FakeSession implements VoipSession {
  _FakeSession({this.throwOnStop = false, this.leaveShareLiveOnStop = false});

  final bool throwOnStop;
  final bool leaveShareLiveOnStop;

  bool sharing = true;
  int stopCalls = 0;

  @override
  bool get isSharingScreen => sharing;

  @override
  Future<void> stopScreenshare() async {
    stopCalls++;
    if (throwOnStop) throw StateError('the stop failed');
    if (!leaveShareLiveOnStop) sharing = false;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// A session whose stop stays in flight until the test lets it finish, and
/// leaves the share live when it does.
class _DeferredSession implements VoipSession {
  final Completer<void> _stop = Completer<void>();

  @override
  bool get isSharingScreen => true;

  @override
  Future<void> stopScreenshare() => _stop.future;

  void finishStop() => _stop.complete();

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// Pumps a minimal app with a scaffold messenger and returns a context from
/// underneath it, the way both stop surfaces do.
Future<BuildContext> _pumpApp(WidgetTester tester) async {
  late BuildContext context;
  await tester.pumpWidget(MaterialApp(
    home: Scaffold(
      body: Builder(builder: (c) {
        context = c;
        return const SizedBox.shrink();
      }),
    ),
  ));
  return context;
}

Future<void> _stop(WidgetTester tester, VoipSession session) async {
  final context = await _pumpApp(tester);

  await stopScreenshareOrReportFailure(context, session);
  await tester.pump();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('a stop that leaves the share live tells the user',
      (tester) async {
    final session = _FakeSession(leaveShareLiveOnStop: true);

    await _stop(tester, session);

    expect(session.stopCalls, 1);
    expect(session.isSharingScreen, isTrue,
        reason: 'the screen is still being captured');
    expect(find.byType(SnackBar), findsOneWidget,
        reason: 'a stop that did not end the share must not stay silent');
    expect(find.text(messageStopScreenshareFailed), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('a stop that comes back as an error tells the user',
      (tester) async {
    final session = _FakeSession(throwOnStop: true);

    await _stop(tester, session);

    expect(find.byType(SnackBar), findsOneWidget,
        reason: 'the thrown stop must not stay silent');
    expect(find.text(messageStopScreenshareFailed), findsOneWidget);
    expect(tester.takeException(), isNull,
        reason: 'the stop error escaped as an unhandled async error');
  });

  testWidgets('a stop that ends the share stays silent', (tester) async {
    final session = _FakeSession();

    await _stop(tester, session);

    expect(session.isSharingScreen, isFalse);
    expect(find.byType(SnackBar), findsNothing,
        reason: 'a stop that worked must not tell the user anything');
  });

  testWidgets('a stop that outlives the messenger does not throw',
      (tester) async {
    final session = _DeferredSession();
    final context = await _pumpApp(tester);

    // The app that would show the message goes away while the stop is still
    // in flight: reporting to the disposed messenger would throw.
    final pending = stopScreenshareOrReportFailure(context, session);
    await tester.pumpWidget(const SizedBox());
    session.finishStop();

    await pending;
    await tester.pump();
    expect(tester.takeException(), isNull);
  });
}
