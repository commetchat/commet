import 'package:calendar_view/calendar_view.dart';
import 'package:commet_calendar_widget/calendar.dart';
import 'package:commet_calendar_widget/unavailability_painter.dart';
import 'package:flutter/material.dart';

import 'package:tiamat/tiamat.dart' as tiamat;

class EventViewBox extends StatelessWidget {
  const EventViewBox(this.event, this.calendar,
      {required this.boundary,
      this.onEventTapped,
      this.avatarRadius = 12,
      super.key});
  final MatrixCalendar calendar;
  final CalendarEventData<MatrixCalendarEventState> event;
  final Function(MatrixCalendarEventState)? onEventTapped;
  final Rect boundary;
  final double avatarRadius;

  @override
  Widget build(BuildContext context) {
    bool unavailability = event.event!.isUnavailability;
    var color = calendar.config.processEventColor(
      event.color,
      context,
    );
    var aspectRatio = boundary.width / boundary.height;
    bool rotate = aspectRatio < 0.7 && boundary.width < 70;

    int rotation = rotate ? 1 : 0;
    return Opacity(
      opacity: event.event!.loaded != true ? 0.3 : 1.0,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
        ),
        child: ClipRect(
          child: Material(
            clipBehavior: Clip.antiAlias,
            borderRadius: BorderRadius.circular(8),
            color:
                unavailability ? Theme.of(context).colorScheme.surface : color,
            child: InkWell(
              onTap: () => onEventTapped?.call(event.event!),
              child: Stack(
                children: [
                  unavailability
                      ? CustomPaint(
                          painter: UnavailabilityPainter(color: color),
                          child: SizedBox(
                            width: double.infinity,
                            height: double.infinity,
                            child: Align(
                              alignment: rotate
                                  ? AlignmentGeometry.topRight
                                  : AlignmentGeometry.topLeft,
                              child: DecoratedBox(
                                decoration: BoxDecoration(
                                    color: color,
                                    borderRadius: rotate
                                        ? BorderRadius.only(
                                            bottomLeft: Radius.circular(8))
                                        : BorderRadius.only(
                                            bottomRight: Radius.circular(8))),
                                child: Padding(
                                  padding: const EdgeInsets.all(3),
                                  child: RotatedBox(
                                    quarterTurns: rotation,
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        RotatedBox(
                                          quarterTurns: -rotation,
                                          child: tiamat.Avatar(
                                            radius: avatarRadius,
                                            placeholderColor: calendar.config
                                                .getColorFromUser(
                                                    event.event!.senderId!),
                                            placeholderText: calendar.config
                                                .getUserDisplayname(
                                                    event.event!.senderId!),
                                            image: calendar.config
                                                .getUserAvatar(
                                                    event.event!.senderId!),
                                          ),
                                        ),
                                        SizedBox(
                                          width: 3,
                                        ),
                                        Text(
                                          event.title,
                                          style: Theme.of(context)
                                              .textTheme
                                              .labelSmall!
                                              .copyWith(
                                                  fontSize: 10,
                                                  color: calendar.config
                                                      .processEventTextColor(
                                                          color, context)),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        )
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            if (rotate)
                              Padding(
                                padding: const EdgeInsets.fromLTRB(0, 4, 4, 0),
                                child: tiamat.Avatar(
                                  radius: avatarRadius,
                                  placeholderColor: calendar.config
                                      .getColorFromUser(event.event!.senderId!),
                                  placeholderText: calendar.config
                                      .getUserDisplayname(
                                          event.event!.senderId!),
                                  image: calendar.config
                                      .getUserAvatar(event.event!.senderId!),
                                ),
                              ),
                            RotatedBox(
                              quarterTurns: rotation,
                              child: Padding(
                                padding: const EdgeInsets.fromLTRB(2, 1, 4, 0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        if (!rotate)
                                          Padding(
                                            padding:
                                                EdgeInsetsGeometry.fromLTRB(
                                                    2, 2, 0, 0),
                                            child: tiamat.Avatar(
                                              radius: avatarRadius,
                                              placeholderColor: calendar.config
                                                  .getColorFromUser(
                                                      event.event!.senderId!),
                                              placeholderText: calendar.config
                                                  .getUserDisplayname(
                                                      event.event!.senderId!),
                                              image: calendar.config
                                                  .getUserAvatar(
                                                      event.event!.senderId!),
                                            ),
                                          ),
                                        if (rotate)
                                          Padding(
                                            padding:
                                                EdgeInsetsGeometry.fromLTRB(
                                                    2, 0, 0, 0),
                                            child: Text(
                                              event.title,
                                              maxLines: ((boundary.height - 11)
                                                          .toInt() /
                                                      (12 +
                                                          1)) // 11 calculated as sum of all top and bottom padding,  then divide by font size + 1
                                                  .toInt()
                                                  .clamp(1, 3),
                                              overflow: TextOverflow.ellipsis,
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .bodySmall
                                                  ?.copyWith(
                                                    fontSize: 12,
                                                    color: calendar.config
                                                        .processEventTextColor(
                                                      event.color,
                                                      context,
                                                    ),
                                                  ),
                                            ),
                                          ),
                                        if (!rotate)
                                          Flexible(
                                            child: Padding(
                                              padding:
                                                  EdgeInsetsGeometry.fromLTRB(
                                                      2, 0, 0, 0),
                                              child: Text(
                                                event.title,
                                                maxLines: ((boundary.height -
                                                                11)
                                                            .toInt() /
                                                        (12 +
                                                            1)) // 11 calculated as sum of all top and bottom padding,  then divide by font size + 1
                                                    .toInt()
                                                    .clamp(1, 3),
                                                overflow: TextOverflow.ellipsis,
                                                style: Theme.of(context)
                                                    .textTheme
                                                    .bodySmall
                                                    ?.copyWith(
                                                      fontSize: 12,
                                                      color: calendar.config
                                                          .processEventTextColor(
                                                        event.color,
                                                        context,
                                                      ),
                                                    ),
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                    if (event.description != null &&
                                        boundary.height > 70)
                                      Text(
                                        maxLines: 3,
                                        event.description!,
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodySmall
                                            ?.copyWith(
                                              color: calendar.config
                                                  .processEventTextColor(
                                                event.color,
                                                context,
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                      ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                  if (event.event?.remoteSourceId != null)
                    Align(
                      alignment: AlignmentGeometry.bottomRight,
                      child: ClipRRect(
                        borderRadius: BorderRadiusGeometry.only(
                            topLeft: Radius.circular(6)),
                        child: Container(
                          color: color,
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(3, 3, 4, 4),
                            child: Icon(
                              size: 10,
                              Icons.satellite_alt,
                              color: calendar.config.processEventTextColor(
                                event.color,
                                context,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class EventViewMini extends StatelessWidget {
  const EventViewMini(this.event, this.calendar,
      {this.onEventTapped, super.key});

  final MatrixCalendar calendar;
  final CalendarEventData<MatrixCalendarEventState> event;
  final Function(MatrixCalendarEventState)? onEventTapped;

  @override
  Widget build(BuildContext context) {
    var e = event;
    bool unavailability = e.event!.isUnavailability;
    var color = calendar.config.processEventColor(
      event.color,
      context,
    );

    return Material(
      borderRadius: BorderRadius.circular(8),
      clipBehavior: Clip.antiAlias,
      color: unavailability
          ? Colors.transparent
          : calendar.config.processEventColor(e.color, context),
      child: InkWell(
        onTap: () => onEventTapped?.call(e.event!),
        child: CustomPaint(
          painter: unavailability
              ? UnavailabilityPainter(color: color, vertical: false)
              : null,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.max,
            children: [
              DecoratedBox(
                decoration: BoxDecoration(
                    color: color,
                    borderRadius:
                        BorderRadius.only(bottomRight: Radius.circular(8))),
                child: Padding(
                  padding: const EdgeInsets.all(2),
                  child: Row(
                    children: [
                      tiamat.Avatar(
                        radius: 10,
                        image: calendar.config
                            .getUserAvatar(event.event!.senderId!),
                        placeholderColor: calendar.config
                            .getColorFromUser(event.event!.senderId!),
                        placeholderText: calendar.config
                            .getUserDisplayname(event.event!.senderId!),
                      ),
                      if (unavailability)
                        Padding(
                          padding: const EdgeInsets.fromLTRB(2, 0, 2, 0),
                          child: Text(
                            event.title,
                            style: Theme.of(context)
                                .textTheme
                                .labelSmall!
                                .copyWith(
                                    fontSize: 10,
                                    color: calendar.config
                                        .processEventTextColor(color, context)),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              unavailability
                  ? Expanded(
                      child: SizedBox(
                        height: 20,
                      ),
                    )
                  : Flexible(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(2, 2, 8, 2),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(
                              child: Text(
                                e.title,
                                overflow: TextOverflow.ellipsis,
                                maxLines: 3,
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(
                                      color:
                                          calendar.config.processEventTextColor(
                                        e.color,
                                        context,
                                      ),
                                    ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}
