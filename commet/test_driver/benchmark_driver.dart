import 'package:flutter_driver/flutter_driver.dart';
import 'dart:convert' show JsonEncoder, json;

import 'package:file/file.dart';
import 'package:integration_test/integration_test_driver.dart' as test;
import 'package:path/path.dart' as path;

Future<void> main() {
  return test.integrationDriver(
    responseDataCallback: (data) async {
      if (data != null) {
        final timeline = Timeline.fromJson(
          data['scrolling_timeline'] as Map<String, dynamic>,
        );

        // Convert the Timeline into a TimelineSummary that's easier to
        // read and understand.
        final summary = TimelineSummary.summarize(timeline);

        // Then, write the entire timeline to disk in a json format.
        // This file can be opened in the Chrome browser's tracing tools
        // found by navigating to chrome://tracing.
        // Optionally, save the summary to disk by setting includeSummary
        // to true

        var lowerIsBetter = [
          {
            "name": "Average Build Time",
            "value": summary.computeAverageFrameBuildTimeMillis(),
            "unit": "ms"
          },
          {
            "name": "Average Raster Time",
            "value": summary.computeAverageFrameRasterizerTimeMillis(),
            "unit": "ms"
          },
          {
            "name": "Worst Build Time",
            "value": summary.computeWorstFrameBuildTimeMillis(),
            "unit": "ms"
          },
          {
            "name": "Worst Raster Time",
            "value": summary.computeWorstFrameRasterizerTimeMillis(),
            "unit": "ms"
          },
          {
            "name": "95th Percentile Build Time",
            "value": summary.computePercentileFrameBuildTimeMillis(95),
            "unit": "ms"
          }
        ];

        final File file = fs.file(
            path.join(testOutputsDirectory, 'customSmallerIsBetter.json'));

        const JsonEncoder prettyEncoder = JsonEncoder.withIndent('  ');
        await file.writeAsString(prettyEncoder.convert(lowerIsBetter));
      }
    },
  );
}
