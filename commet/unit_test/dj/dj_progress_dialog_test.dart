// The progress dialog the source extension install shows while it reads or
// downloads something. A quick task (reading a small .zip) used to finish
// before the dialog was built, and its pop() then closed the confirmation
// shown next: the install looked stuck on "Starting…".
//
// The dialog's progress bar animates for as long as it shows, so these pump
// for set times rather than until nothing moves.
import 'dart:async';

import 'package:commet/ui/organisms/dj/dj_prompts.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late BuildContext appContext;

  Widget app() => MaterialApp(
        home: Builder(builder: (context) {
          appContext = context;
          return const SizedBox();
        }),
      );

  Future<void> settle(WidgetTester tester) async {
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
  }

  testWidgets('a task that finishes at once leaves the next dialog alone',
      (tester) async {
    await tester.pumpWidget(app());

    int? got;
    unawaited(() async {
      got = await runWithProgressDialog<int>(
          appContext, 'Reading the extension', (_, __) async => 42);
      // What the install shows next: the confirmation.
      await showDialog<void>(
        context: appContext,
        builder: (_) => const AlertDialog(title: Text('Install it?')),
      );
    }());
    await settle(tester);

    expect(got, 42);
    expect(find.text('Reading the extension'), findsNothing);
    expect(find.text('Install it?'), findsOneWidget);
  });

  testWidgets('a slow task shows its progress, then goes', (tester) async {
    await tester.pumpWidget(app());

    late void Function(String, double?) report;
    final finish = Completer<int>();
    final flow =
        runWithProgressDialog<int>(appContext, 'Installing', (onProgress, _) {
      report = onProgress;
      return finish.future;
    });
    await settle(tester);
    expect(find.text('Installing'), findsOneWidget);
    expect(find.text('Starting…'), findsOneWidget);

    report('Deno', 0.5);
    await tester.pump();
    expect(find.text('Downloading Deno…'), findsOneWidget);

    finish.complete(1);
    await settle(tester);
    expect(await flow, 1);
    expect(find.text('Installing'), findsNothing);
  });

  testWidgets('Cancel stops the task and closes the dialog', (tester) async {
    await tester.pumpWidget(app());

    var stopped = false;
    final flow =
        runWithProgressDialog<int>(appContext, 'Reading', (_, cancel) async {
      while (!cancel.cancelled) {
        await Future<void>.delayed(const Duration(milliseconds: 50));
      }
      stopped = true;
      return 7;
    });
    await settle(tester);
    await tester.tap(find.text('Cancel'));
    await settle(tester);

    expect(stopped, isTrue);
    expect(await flow, 7);
    expect(find.text('Reading'), findsNothing);
  });
}
