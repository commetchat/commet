import 'package:commet/diagnostic/benchmark_values.dart';
import 'package:commet/ui/pages/developer/benchmarks/benchmark_utils.dart';
import 'package:commet/ui/pages/developer/benchmarks/timeline_viewer_benchmark.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:tiamat/config/style/theme_dark.dart';

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

    var reportKey = 'TimelineViewer Scrolling';

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
      reportKey: reportKey,
    );

    binding.reportData?[reportKey]["extra_values"] = [
      {
        "name": "$reportKey - Timeline Event Build Count",
        "value": BenchmarkValues.numTimelineEventsBuilt,
        "unit": "Builds",
      }
    ];
  });
}
