// ignore_for_file: depend_on_referenced_packages

import 'package:flutter_driver/flutter_driver.dart';
import 'dart:convert' show JsonEncoder;

import 'package:file/file.dart';
import 'package:integration_test/integration_test_driver.dart' as test;
import 'package:path/path.dart' as path;

Future<void> main() {
  return test.integrationDriver(
    responseDataCallback: (data) async {
      if (data != null) {
        var result = List<Map<String, dynamic>>.empty(growable: true);

        for (var key in data.keys) {
          final timeline = Timeline.fromJson(
            data[key] as Map<String, dynamic>,
          );

          final summary = TimelineSummary.summarize(timeline);

          result.addAll([
            {
              "name": "$key - Average Build Time",
              "value": summary.computeAverageFrameBuildTimeMillis(),
              "unit": "ms"
            },
            {
              "name": "$key - Average Raster Time",
              "value": summary.computeAverageFrameRasterizerTimeMillis(),
              "unit": "ms"
            },
            {
              "name": "$key - Standard Deviation of Frame Rasterizer Time",
              "value":
                  summary.computeStandardDeviationFrameRasterizerTimeMillis(),
              "unit": "ms"
            },
            {
              "name": "$key - Worst Build Time",
              "value": summary.computeWorstFrameBuildTimeMillis(),
              "unit": "ms"
            },
            {
              "name": "$key - Worst Raster Time",
              "value": summary.computeWorstFrameRasterizerTimeMillis(),
              "unit": "ms"
            },
            {
              "name": "$key - 95th Percentile Build Time",
              "value": summary.computePercentileFrameBuildTimeMillis(95),
              "unit": "ms"
            },
            {
              "name": "$key - 95th Percentile Raster Time",
              "value": summary.computePercentileFrameRasterizerTimeMillis(95),
              "unit": "ms"
            },
            {
              "name": "$key - 50th Percentile Build Time",
              "value": summary.computePercentileFrameBuildTimeMillis(50),
              "unit": "ms"
            },
            {
              "name": "$key - 50th Percentile Raster Time",
              "value": summary.computePercentileFrameRasterizerTimeMillis(50),
              "unit": "ms"
            },
            {
              "name": "$key - Frames missed build budget",
              "value": summary.computeMissedFrameBuildBudgetCount(),
              "unit": "Frames"
            },
            {
              "name": "$key - Frame Count",
              "value": summary.countFrames(),
              "unit": "Frames"
            },
            {
              "name": "$key - Raster Count",
              "value": summary.countRasterizations(),
              "unit": "Rasterizations"
            },
            {
              "name": "$key - New generation garbage collections",
              "value": summary.newGenerationGarbageCollections(),
              "unit": "Collections"
            },
            {
              "name": "$key - Old generation garbage collections",
              "value": summary.oldGenerationGarbageCollections(),
              "unit": "Collections"
            },
          ]);
        }

        final File file = fs.file(
            path.join(testOutputsDirectory, 'customSmallerIsBetter.json'));

        const JsonEncoder prettyEncoder = JsonEncoder.withIndent('  ');
        await file.writeAsString(prettyEncoder.convert(result));
      }
    },
  );
}
