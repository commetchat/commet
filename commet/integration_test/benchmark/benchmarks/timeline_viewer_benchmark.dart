import 'dart:math';

import 'package:commet/client/matrix/matrix_profile.dart';
import 'package:commet/ui/molecules/timeline_viewer.dart';
import 'package:commet/ui/pages/developer/benchmarks/benchmark_utils.dart';
import 'package:commet/ui/pages/developer/benchmarks/timeline_viewer_benchmark.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:commet/client/matrix/matrix_client.dart';
import 'package:matrix/matrix.dart' as matrix;
import 'package:tiamat/config/style/theme_dark.dart';

import '../../../lib/diagnostic/mocks/matrix_client_component_mocks.dart';

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Timeline Viewer Test', (tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(MaterialApp(
      theme: ThemeDark.theme,
      home: const Scaffold(
        body: BenchmarkTimelineViewer(),
      ),
    ));

    await tester.pump(const Duration(seconds: 1));

    final listFinder = find.byType(Scrollable);
    final itemFinder = find.text(finalEventMessage);

    await binding.traceAction(
      () async {
        // Scroll until the item to be found appears.
        await tester.scrollUntilVisible(
          itemFinder,
          50.0,
          maxScrolls: 10000,
          scrollable: listFinder,
        );
      },
      reportKey: 'TimelineViewer Scrolling',
    );
  });
}
