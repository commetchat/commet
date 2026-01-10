import 'package:commet/client/client.dart';
import 'package:commet/client/matrix/components/profile/matrix_profile_component.dart';
import 'package:commet/client/matrix/matrix_client.dart';
import 'package:commet/diagnostic/mocks/matrix_client_component_mocks.dart';
import 'package:commet/ui/molecules/room_timeline_widget/room_timeline_widget_view.dart';
import 'package:commet/ui/pages/developer/benchmarks/benchmark_utils.dart';
import 'package:flutter/material.dart';

import 'package:matrix/matrix.dart' as matrix;

class BenchmarkTimelineViewer extends StatefulWidget {
  const BenchmarkTimelineViewer({super.key});

  @override
  State<BenchmarkTimelineViewer> createState() =>
      _BenchmarkTimelineViewerState();
}

class _BenchmarkTimelineViewerState extends State<BenchmarkTimelineViewer> {
  Timeline? timeline;

  @override
  void initState() {
    MatrixClient.create("benchmark").then((client) {
      client.mockComponents();
      client.self = MatrixProfile(client,
          matrix.Profile(userId: '@benchy:matrix.org', displayName: 'benchy'));

      var room = client.createRoomWithData();
      timeline = room.getBenchmarkTimeline();
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.of(context).pop(),
        child: const Icon(Icons.chevron_left),
      ),
      body: timeline != null
          ? RoomTimelineWidgetView(
              key: const ValueKey("timeline-viewer-benchmark"),
              timeline: timeline!,
              // doMessageOverlayMenu: false,
            )
          : Container(),
    );
  }
}
