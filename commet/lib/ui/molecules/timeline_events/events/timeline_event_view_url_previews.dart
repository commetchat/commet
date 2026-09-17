import 'package:commet/client/components/url_preview/url_preview_component.dart';
import 'package:commet/client/timeline.dart';
import 'package:commet/client/timeline_events/timeline_event.dart';
import 'package:commet/debug/log.dart';
import 'package:commet/diagnostic/benchmark_values.dart';
import 'package:commet/ui/molecules/timeline_events/timeline_event_layout.dart';
import 'package:commet/ui/molecules/url_preview_widget.dart';
import 'package:commet/utils/links/link_utils.dart';
import 'package:flutter/material.dart';

class TimelineEventViewUrlPreviews extends StatefulWidget {
  const TimelineEventViewUrlPreviews(
      {required this.event,
      required this.timeline,
      required this.component,
      super.key});

  /// The message this preview belongs to, as its message view last loaded it.
  /// Not looked up by index: a message view's index goes stale when newer
  /// messages are inserted below it.
  final TimelineEvent event;
  final Timeline timeline;
  final UrlPreviewComponent component;

  @override
  State<TimelineEventViewUrlPreviews> createState() =>
      _TimelineEventViewUrlPreviewsState();
}

enum _FetchState { idle, fetching, done }

class _TimelineEventViewUrlPreviewsState
    extends State<TimelineEventViewUrlPreviews>
    implements TimelineEventViewWidget {
  UrlPreviewData? data;

  /// A message is fetched at most once: a finished fetch that found nothing
  /// isn't retried on every rebuild (hover, read receipts).
  _FetchState fetchState = _FetchState.idle;

  GlobalKey key = GlobalKey();

  @override
  Widget build(BuildContext context) {
    BenchmarkValues.numTimelineUrlPreviewBuilt += 1;

    if (data == UrlPreviewComponent.invalidPreviewData) return Container();
    if (fetchState == _FetchState.done && data == null) return Container();

    return Padding(
        padding: const EdgeInsets.fromLTRB(0, 2, 40, 2),
        child: UrlPreviewWidget(
          key: key,
          data,
          onOpenLink: () {
            LinkUtils.open(data!.uri, context: context);
          },
        ));
  }

  /// [newIndex] is current when this is called, unlike the index a message
  /// view builds us with later.
  @override
  void update(int newIndex) {
    load(widget.timeline.events[newIndex]);
  }

  @override
  void initState() {
    super.initState();
    load(widget.event);
  }

  @override
  void didUpdateWidget(covariant TimelineEventViewUrlPreviews oldWidget) {
    super.didUpdateWidget(oldWidget);
    // A message we just sent is first built while still sending, so the fetch
    // was skipped. The message view rebuilds us once the event has synced.
    load(widget.event);
  }

  void load(TimelineEvent event) {
    if (data != null || fetchState != _FetchState.idle) return;

    final cached = widget.component.getCachedPreview(widget.timeline, event);
    if (cached != null) {
      setState(() {
        data = cached;
        key = GlobalKey();
      });
      return;
    }

    if (event.status == TimelineEventStatus.synced) {
      fetchPreview(event);
    }
  }

  Future<void> fetchPreview(TimelineEvent event) async {
    fetchState = _FetchState.fetching;
    UrlPreviewData? value;
    try {
      value = await widget.component.getPreview(widget.timeline, event);
      final image = value?.image;
      if (image != null && mounted) {
        await precacheImage(image, context);
      }
    } catch (e, s) {
      Log.onError(e, s, content: 'Failed to get url preview');
      value = null;
    }

    if (!mounted) return;
    setState(() {
      fetchState = _FetchState.done;
      data = value;
      key = GlobalKey();
    });
  }
}
