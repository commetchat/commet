import 'package:commet/diagnostic/diagnostics.dart';
import 'package:flutter/material.dart';

import 'package:tiamat/tiamat.dart' as tiamat;

class CumulativeDiagnosticsWidget extends StatefulWidget {
  const CumulativeDiagnosticsWidget({required this.diagnostics, super.key});

  final CumulativeDiagnostics diagnostics;

  @override
  State<CumulativeDiagnosticsWidget> createState() =>
      _CumulativeDiagnosticsWidgetState();
}

class _CumulativeDiagnosticsWidgetState
    extends State<CumulativeDiagnosticsWidget> {
  late List<CumulativeMeasurement> measurements;

  @override
  void initState() {
    measurements = widget.diagnostics.measurements.values.toList();
    measurements.sort(
      (a, b) => b.totalDuration.compareTo(a.totalDuration),
    );

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return ExpansionTile(
        title: tiamat.Text.labelEmphasised(widget.diagnostics.name),
        initiallyExpanded: false,
        backgroundColor: Theme.of(context).colorScheme.surfaceContainerLow,
        collapsedBackgroundColor:
            Theme.of(context).colorScheme.surfaceContainerLow,
        children: measurements
            .mapIndexed((e, i) => Container(
                  color: i % 2 == 0
                      ? Theme.of(context).colorScheme.surfaceDim
                      : Theme.of(context).colorScheme.surfaceContainerHigh,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 2, 20, 2),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Flexible(
                            child: Padding(
                          padding: const EdgeInsets.fromLTRB(0, 2, 8, 2),
                          child: tiamat.Text.labelLow(
                            e.name,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        )),
                        tiamat.Text.labelLow(
                          [
                            "${e.numCalls} calls",
                            "${(e.totalDuration.inMilliseconds / e.numCalls).round()}ms avg",
                            "${e.totalDuration.inMilliseconds}ms total",
                          ].join("   -   "),
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        )
                      ],
                    ),
                  ),
                ))
            .toList());
  }
}
