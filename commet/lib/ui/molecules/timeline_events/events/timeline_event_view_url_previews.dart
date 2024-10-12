import 'package:commet/client/components/url_preview/url_preview_component.dart';
import 'package:commet/client/timeline.dart';
import 'package:commet/diagnostic/benchmark_values.dart';
import 'package:commet/ui/molecules/timeline_events/timeline_event_layout.dart';
import 'package:commet/ui/molecules/url_preview_widget.dart';
import 'package:commet/utils/link_utils.dart';
import 'package:flutter/material.dart';

class TimelineEventViewUrlPreviews extends StatefulWidget {
  const TimelineEventViewUrlPreviews(
      {required this.initialIndex,
      required this.timeline,
      required this.component,
      super.key});

  final int initialIndex;
  final Timeline timeline;
  final UrlPreviewComponent component;

  @override
  State<TimelineEventViewUrlPreviews> createState() =>
      _TimelineEventViewUrlPreviewsState();
}

class _TimelineEventViewUrlPreviewsState
    extends State<TimelineEventViewUrlPreviews>
    implements TimelineEventViewWidget {
  UrlPreviewData? data;
  bool loading = false;

  GlobalKey key = GlobalKey();

  @override
  Widget build(BuildContext context) {
    BenchmarkValues.numTimelineUrlPreviewBuilt += 1;
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 2, 40, 2),
      child: (loading || data != null)
          ? UrlPreviewWidget(
              key: key,
              data,
              onTap: () {
                LinkUtils.open(data!.uri);
              },
            )
          : Container(),
    );
  }

  @override
  void update(int newIndex) {
    setStateFromIndex(newIndex);
  }

  @override
  void initState() {
    setStateFromIndex(widget.initialIndex);
    super.initState();
  }

  void setStateFromIndex(int index) {
    var event = widget.timeline.events[index];
    var cachedData =
        widget.component.getCachedPreview(widget.timeline.room, event);

    if (cachedData != null) {
      setState(() {
        data = cachedData;
        key = GlobalKey();
      });
    } else {
      setState(() {
        loading = true;
      });

      if (event.status == TimelineEventStatus.synced) {
        widget.component.getPreview(widget.timeline.room, event).then(
          (value) async {
            if (mounted) {
              final image = value?.image;
              if (image != null) {
                if (context.mounted) {
                  await precacheImage(image, context);
                }
              }

              if (mounted)
                setState(() {
                  loading = false;
                  data = value;
                  key = GlobalKey();
                });
            }
          },
        );
      }
    }
  }
}
