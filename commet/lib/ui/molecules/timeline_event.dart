import 'package:commet/config/build_config.dart';
import 'package:commet/ui/atoms/generic_room_event.dart';
import 'package:commet/ui/molecules/message.dart';
import 'package:flutter/material.dart' as m;
import 'package:flutter/widgets.dart';
import 'package:tiamat/atoms/icon_button.dart';
import 'package:tiamat/config/style/theme_extensions.dart';
import 'package:tiamat/tiamat.dart' as tiamat;

import '../../client/client.dart';
import '../../generated/l10n.dart';
import '../atoms/message_attachment.dart';
import '../atoms/tooltip.dart' as t;

class TimelineEventView extends StatefulWidget {
  const TimelineEventView(
      {required this.event,
      required this.timeline,
      super.key,
      this.onDelete,
      this.hovered = false,
      this.showSender = true,
      this.setReplyingEvent,
      this.onDoubleTap,
      this.onLongPress,
      this.debugInfo});
  final TimelineEvent event;
  final bool hovered;
  final Function? onDelete;
  final bool showSender;
  final String? debugInfo;
  final Timeline timeline;
  final Function()? onDoubleTap;
  final Function()? onLongPress;
  final Function(TimelineEvent? event)? setReplyingEvent;

  @override
  State<TimelineEventView> createState() => _TimelineEventState();
}

class _TimelineEventState extends State<TimelineEventView> {
  TimelineEvent? relatedEvent;

  @override
  void initState() {
    if (widget.event.relatedEventId != null) {
      relatedEvent = widget.timeline.tryGetEvent(widget.event.relatedEventId!);
      if (relatedEvent == null) {
        fetchRelatedEvent();
      }
    }

    super.initState();
  }

  void fetchRelatedEvent() async {
    var event =
        await widget.timeline.fetchEventById(widget.event.relatedEventId!);
    if (mounted)
      setState(() {
        relatedEvent = event;
      });
  }

  @override
  Widget build(BuildContext context) {
    var display = eventToWidget(widget.event);
    return AnimatedContainer(
        duration: const Duration(milliseconds: 100),
        color: widget.hovered ? m.Colors.red : m.Colors.transparent,
        child: display);
  }

  Widget? eventToWidget(TimelineEvent event) {
    if (event.status == TimelineEventStatus.removed) return const SizedBox();
    switch (widget.event.type) {
      case EventType.message:
      case EventType.sticker:
        return Message(
          senderName: widget.event.sender.displayName,
          senderColor: widget.event.sender.color,
          senderAvatar: widget.event.sender.avatar,
          sentTimeStamp: widget.event.originServerTs,
          onDoubleTap: widget.onDoubleTap,
          onLongPress: widget.onLongPress,
          showSender: widget.showSender,
          replyBody: relatedEvent?.body ??
              (relatedEvent?.type == EventType.sticker
                  ? T.current.messagePlaceholderSticker
                  : null),
          replySenderName: relatedEvent?.sender.displayName,
          replySenderColor: relatedEvent?.sender.color,
          edited: widget.event.edited,
          body: buildBody(),
          menuBuilder: BuildConfig.DESKTOP ? buildMenu : null,
        );
      case EventType.roomCreated:
        return GenericRoomEvent(
            T.current.userCreatedRoom(event.sender.displayName),
            m.Icons.room_preferences_outlined);
      case EventType.memberJoined:
        return GenericRoomEvent(
            T.current.userJoinedRoom(event.sender.displayName),
            m.Icons.waving_hand_rounded);
      case EventType.memberLeft:
        return GenericRoomEvent(
            T.current.userLeftRoom(event.sender.displayName),
            m.Icons.subdirectory_arrow_left_rounded);
      default:
        break;
    }

    if (BuildConfig.DEBUG) {
      return m.Padding(
        padding: const EdgeInsets.all(8.0),
        child: Placeholder(
            child: event.source != null
                ? tiamat.Text.tiny(event.source!)
                : const Placeholder(
                    fallbackHeight: 20,
                  )),
      );
    }
    return null;
  }

  Widget buildMenu(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          color: m.Theme.of(context).colorScheme.surface,
          border: Border.all(
              color: m.Theme.of(context).extension<ExtraColors>()!.surfaceLow2,
              width: 1)),
      child: m.Padding(
        padding: const EdgeInsets.fromLTRB(4, 0, 4, 0),
        child: Row(
          children: [
            buildMenuEntry(m.Icons.reply, "Reply", () {
              widget.setReplyingEvent!.call(widget.event);
            }),
            buildMenuEntry(m.Icons.add_reaction, "Add Reaction", () => null),
            if (canUserEditEvent())
              buildMenuEntry(m.Icons.edit, "Edit", () => null),
            buildMenuEntry(m.Icons.more_vert, "Options", () => null)
          ],
        ),
      ),
    );
  }

  Widget buildMenuEntry(IconData icon, String label, Function()? callback) {
    const double size = 32;
    return t.Tooltip(
      text: label,
      child: m.Padding(
        padding: const EdgeInsets.fromLTRB(0, 0, 0, 0),
        child: m.SizedBox(
          width: size,
          height: size,
          child: IconButton(
            size: 20,
            icon: icon,
            onPressed: () => callback?.call(),
          ),
        ),
      ),
    );
  }

  bool canUserEditEvent() {
    return widget.timeline.room.permissions.canUserEditMessages &&
        widget.event.sender == widget.timeline.room.client.user;
  }

  Widget buildBody() {
    bool selectableText = BuildConfig.DESKTOP;
    return m.Material(
      color: m.Colors.transparent,
      child: Column(
        children: [
          if (widget.event.bodyFormat != null)
            selectableText
                ? m.SelectionArea(child: widget.event.formattedContent!)
                : widget.event.formattedContent!
          else if (widget.event.body != null)
            selectableText
                ? m.SelectionArea(child: tiamat.Text.body(widget.event.body!))
                : tiamat.Text.body(widget.event.body!),
          if (widget.event.attachments != null)
            Wrap(
              children: widget.event.attachments!
                  .map((e) => Padding(
                        padding: const EdgeInsets.fromLTRB(0, 8, 8, 8),
                        child: MessageAttachment(
                          e,
                          ignorePointer: widget.event.type == EventType.sticker,
                        ),
                      ))
                  .toList(),
            ),
        ],
      ),
    );
  }
}
