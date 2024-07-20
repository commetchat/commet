import 'package:commet/client/timeline.dart';
import 'package:commet/client/timeline_events/timeline_event_base.dart';
import 'package:commet/ui/atoms/scaled_safe_area.dart';
import 'package:commet/ui/molecules/timeline_events/timeline_event_menu.dart';
import 'package:commet/ui/molecules/timeline_events/timeline_view_entry.dart';
import 'package:flutter/material.dart';
import 'package:tiamat/atoms/seperator.dart';
import 'package:tiamat/tiamat.dart' as tiamat;

class TimelineEventMenuDialog extends StatelessWidget {
  const TimelineEventMenuDialog(
      {required this.event,
      required this.timeline,
      required this.menu,
      super.key});

  final TimelineEvent event;
  final Timeline timeline;

  final TimelineEventMenu menu;

  @override
  Widget build(BuildContext context) {
    return buildMessageMenu(context, event);
  }

  Widget buildMessageMenu(BuildContext context, TimelineEvent event) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 0, 10, 0),
      child: ScaledSafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            IgnorePointer(
              ignoring: true,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(0, 0, 0, 4),
                child: ShaderMask(
                  blendMode: BlendMode.dstIn,
                  shaderCallback: (bounds) {
                    return const LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.white,
                        Colors.transparent,
                      ],
                      stops: [0.80, 1.0],
                    ).createShader(bounds);
                  },
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxHeight: 100),
                    child: SingleChildScrollView(
                      physics: const NeverScrollableScrollPhysics(),
                      child: SizedBox(
                        child: TimelineViewEntry(
                          timeline: timeline,
                          singleEvent: true,
                          initialIndex: timeline.events.indexOf(event),
                          showDetailed: true,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            for (var action in menu.primaryActions)
              SizedBox(
                height: 50,
                child: tiamat.TextButton(action.name,
                    icon: action.icon, onTap: () => doAction(action, context)),
              ),
            const Seperator(),
            for (var action in menu.secondaryActions)
              SizedBox(
                height: 50,
                child: tiamat.TextButton(action.name,
                    icon: action.icon, onTap: () => doAction(action, context)),
              ),
          ],
        ),
      ),
    );
  }

  void doAction(TimelineEventMenuEntry entry, BuildContext context) async {
    if (entry.action != null) {
      entry.action?.call(context);
      return;
    }

    if (entry.secondaryMenuBuilder != null) {
      await showModalBottomSheet(
        context: context,
        builder: (newContext) {
          return entry.secondaryMenuBuilder!.call(newContext, () {
            Navigator.of(newContext).pop();
          });
        },
      );

      if (context.mounted) Navigator.of(context).pop();
    }
  }
}
