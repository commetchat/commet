import 'dart:math';

import 'package:commet/client/timeline.dart';

enum SplitTimelinePart { Historical, Recent, None }

class SplitTimeline {
  Timeline timeline;
  late List<TimelineEvent> historical;
  late List<TimelineEvent> recent;
  final int chunkSize;

  SplitTimeline(this.timeline, {this.chunkSize = 30}) {
    int recentEndIndex = min(timeline.events.length - 1, chunkSize);
    int historyEndIndex = min(timeline.events.length - 1, recentEndIndex + chunkSize);
    if (timeline.events.length == 0) {
      recentEndIndex = 0;
      historyEndIndex = 0;
    }
    recent = List.from(timeline.events.sublist(0, recentEndIndex), growable: true);
    historical = List.from(timeline.events.sublist(recentEndIndex, historyEndIndex), growable: true);

    timeline.onEventAdded.stream.listen((index) {
      onEventAdded(index);
    });

    timeline.onRemove.stream.listen((index) {
      onEventRemoved(index);
    });
  }

  SplitTimelinePart whichList(int index) {
    if (index < recent.length) {
      return SplitTimelinePart.Recent;
    }

    if (index < recent.length + historical.length) {
      return SplitTimelinePart.Historical;
    }

    return SplitTimelinePart.None;
  }

  bool isMoreHistoryAvailable() {
    return (recent.length + historical.length) < timeline.events.length;
  }

  void loadMoreHistory() {
    int startIndex = recent.length + historical.length;
    int endIndex = min(startIndex + chunkSize, timeline.events.length);

    print("Loading history from ${startIndex} -> ${endIndex}");

    List<TimelineEvent> eventsToAdd = timeline.events.sublist(startIndex, endIndex);
    historical.addAll(eventsToAdd);
  }

  int numEventsLoaded() {
    return recent.length + historical.length;
  }

  int getHistoryIndex(int timelineIndex) {
    if (timelineIndex < recent.length) return -1;
    return timelineIndex - recent.length;
  }

  int getHistoryDisplayIndex(int listbuilderIteration) {
    return listbuilderIteration;
  }

  int getRecentDisplayIndex(int listbuilderIteration) {
    return recent.length - listbuilderIteration - 1;
  }

  int getRecentIndex(int timelineIndex) {
    if (timelineIndex >= recent.length) return -1;
    return timelineIndex;
  }

  int getTimelineIndex(int splitIndex, SplitTimelinePart part) {
    switch (part) {
      case SplitTimelinePart.Historical:
        return splitIndex + recent.length;
      case SplitTimelinePart.Recent:
        return splitIndex;
      case SplitTimelinePart.None:
        return -1;
    }
  }

  SplitTimelinePart whichListToInsert(int index) {
    if (index < recent.length) {
      return SplitTimelinePart.Recent;
    }

    if (index < recent.length + historical.length + 1) {
      return SplitTimelinePart.Historical;
    }

    throw Exception("Trying to insert in to list which is not sized appropriately");
  }

  void onEventAdded(int timelineIndex) {
    print("SplitTimeline event added: ${timelineIndex}");
    var part = whichListToInsert(timelineIndex);
    print("Inserting in to: ${part}");
    switch (part) {
      case SplitTimelinePart.Historical:
        historical.insert(getHistoryIndex(timelineIndex), timeline.events[timelineIndex]);
        break;
      case SplitTimelinePart.Recent:
        recent.insert(getRecentIndex(timelineIndex), timeline.events[timelineIndex]);
        break;
      default:
        throw Exception(
            "whichListToInsert should not only return either Recent or Historical. This should be impossible");
    }
  }

  void onEventRemoved(int timelineIndex) {
    switch (whichList(timelineIndex)) {
      case SplitTimelinePart.Historical:
        historical.removeAt(getHistoryIndex(timelineIndex));
        break;
      case SplitTimelinePart.Recent:
        recent.removeAt(getRecentIndex(timelineIndex));
        break;
      case SplitTimelinePart.None:
        break;
    }
  }
}
