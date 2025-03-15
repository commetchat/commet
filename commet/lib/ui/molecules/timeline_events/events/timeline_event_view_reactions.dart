import 'package:commet/client/components/emoticon/emoticon.dart';
import 'package:commet/client/timeline.dart';
import 'package:commet/client/timeline_events/timeline_event.dart';
import 'package:commet/client/timeline_events/timeline_event_feature_reactions.dart';
import 'package:commet/ui/atoms/emoji_reaction.dart';
import 'package:commet/ui/molecules/timeline_events/timeline_event_layout.dart';
import 'package:flutter/material.dart';

import 'package:flutter/material.dart' as material;

class TimelineEventViewReactions extends StatefulWidget {
  const TimelineEventViewReactions(
      {required this.initialIndex, required this.timeline, super.key});

  final int initialIndex;
  final Timeline timeline;

  @override
  State<TimelineEventViewReactions> createState() =>
      _TimelineEventViewReactionsState();
}

class _TimelineEventViewReactionsState extends State<TimelineEventViewReactions>
    implements TimelineEventViewWidget {
  late Map<Emoticon, Set<String>> reactions;

  late final String? currentUserIdentifier;
  late final TimelineEvent event;

  @override
  void initState() {
    event = widget.timeline.events[widget.initialIndex];
    currentUserIdentifier = widget.timeline.client.self?.identifier;
    setStateFromIndex(widget.initialIndex);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Wrap(
        spacing: 3,
        runSpacing: 3,
        direction: material.Axis.horizontal,
        children: reactions.keys.map((key) {
          var value = reactions[key]!;
          return EmojiReaction(
              emoji: key,
              onTapped: onReactionTapped,
              numReactions: value.length,
              highlighted: value.contains(currentUserIdentifier));
        }).toList());
  }

  onReactionTapped(Emoticon emote) {
    if (reactions[emote]?.contains(currentUserIdentifier) == true) {
      widget.timeline.room.removeReaction(event, emote);
    } else {
      widget.timeline.room.addReaction(event, emote);
    }
  }

  @override
  void update(int newIndex) {
    setStateFromIndex(newIndex);
  }

  void setStateFromIndex(int index) {
    setState(() {
      final event = widget.timeline.events[index];
      if (event is TimelineEventFeatureReactions) {
        reactions = (event as TimelineEventFeatureReactions)
            .getReactions(widget.timeline);
      }
    });
  }
}
