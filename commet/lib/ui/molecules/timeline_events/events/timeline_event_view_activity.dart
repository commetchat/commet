import 'package:commet/client/components/activities/activities_component.dart';
import 'package:commet/client/timeline.dart';
import 'package:commet/config/layout_config.dart';
import 'package:commet/ui/molecules/timeline_events/layouts/timeline_event_layout_message.dart';
import 'package:commet/ui/molecules/timeline_events/timeline_event_layout.dart';
import 'package:commet/utils/image_or_icon.dart';
import 'package:flutter/material.dart';

import 'package:tiamat/tiamat.dart' as tiamat;

class TimelineEventViewActivity extends StatefulWidget {
  const new({required this.initialIndex, required this.timeline, super.key});

  final int initialIndex;
  final Timeline timeline;
  @override
  State<TimelineEventViewActivity> createState() =>
      TimelineEventViewActivityState();
}

class TimelineEventViewActivityState extends State<TimelineEventViewActivity>
    implements TimelineEventViewWidget {
  ImageProvider? senderAvatar;
  late String senderName;
  late String senderId;
  late Color senderColor;
  late String? activityName;
  String? status;
  late ImageOrIcon? icon;

  ActivityInfo? info;

  ActivitiesComponent? comp;

  @override
  void initState() {
    comp = widget.timeline.room.getComponent<ActivitiesComponent>();
    setStateFromIndex(widget.initialIndex);

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    var scheme = ColorScheme.of(context);
    return TimelineEventLayoutMessage(
      senderName: senderName,
      senderColor: senderColor,
      senderAvatar: senderAvatar,
      showSender: true,
      formattedContent: Padding(
        padding: const EdgeInsets.fromLTRB(0, 4, 0, 4),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).desktop ? 500 : double.infinity,
          ),
          child: Container(
            decoration: BoxDecoration(
              color: scheme.surfaceContainerLow,
              //  border: BoxBorder.all(color: scheme.outline, width: 1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                spacing: 8,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (activityName != null && icon != null) ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          spacing: 12,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            SizedBox(
                              width: 32,
                              height: 32,
                              child: ClipRRect(
                                borderRadius: BorderRadiusGeometry.circular(8),
                                child: icon!.build(context),
                              ),
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                tiamat.Text.labelEmphasised(activityName!),
                                if (status != null)
                                  tiamat.Text.labelLow(status!),
                              ],
                            ),
                          ],
                        ),
                        tiamat.Button.secondary(
                          text: "Open",
                          onTap: () {
                            comp!.openActivity(info!, context);
                          },
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  void update(int newIndex) {
    setStateFromIndex(newIndex);
  }

  void setStateFromIndex(int index) {
    final e = widget.timeline.events[index];
    info = comp?.getInfoFromEvent(e, widget.timeline);

    setState(() {
      var sender = widget.timeline.room.getMemberOrFallback(e.senderId);
      senderId = sender.identifier;
      senderName = sender.displayName;
      senderAvatar = sender.avatar;
      senderColor = sender.defaultColor;
      activityName = info?.displayName;
      status = info?.status;
      icon = info?.icon;
    });
  }
}
