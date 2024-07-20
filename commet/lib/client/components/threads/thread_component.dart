import 'package:commet/client/attachment.dart';
import 'package:commet/client/client.dart';
import 'package:commet/client/components/component.dart';
import 'package:commet/client/timeline_events/timeline_event_base.dart';

abstract class ThreadsComponent<T extends Client> implements Component<T> {
  bool isEventInResponseToThread(TimelineEventBase event, Timeline timeline);

  bool isHeadOfThread(TimelineEventBase event, Timeline timeline);

  Future<Timeline?> getThreadTimeline(
      {required Timeline roomTimeline, required String threadRootEventId});

  Future<TimelineEventBase?> sendMessage({
    required String threadRootEventId,
    required Room room,
    String? message,
    TimelineEventBase? inReplyTo,
    TimelineEventBase? replaceEvent,
    List<ProcessedAttachment>? processedAttachments,
  });

  TimelineEventBase? getFirstReplyToThread(
      TimelineEventBase event, Timeline timeline);
}
