import 'package:commet/config/build_config.dart';
import 'package:commet/ui/atoms/generic_room_event.dart';
import 'package:commet/ui/molecules/message.dart';
import 'package:flutter/material.dart' as m;
import 'package:flutter/widgets.dart';
import 'package:tiamat/atoms/icon_button.dart';
import 'package:tiamat/config/style/theme_extensions.dart';
import 'package:tiamat/tiamat.dart' as tiamat;

import '../../client/client.dart';
import '../../client/components/emoticon/emoticon.dart';
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
      this.setEditingEvent,
      this.onDoubleTap,
      this.onReactionTapped,
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
  final Function()? setReplyingEvent;
  final Function()? setEditingEvent;
  final Function(Emoticon emote)? onReactionTapped;

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

    widget.timeline.client.fetchPeer(widget.event.senderId).loading?.then((_) {
      if (mounted) setState(() {});
    });

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
        child: Opacity(
            opacity:
                widget.event.status == TimelineEventStatus.sending ? 0.5 : 1,
            child: display));
  }

  String get displayName =>
      widget.timeline.room.client.fetchPeer(widget.event.senderId).displayName;

  ImageProvider? get avatar =>
      widget.timeline.room.client.fetchPeer(widget.event.senderId).avatar;

  Color get color => widget.timeline.room.getColorOfUser(widget.event.senderId);

  Color get replyColor => relatedEvent == null
      ? m.Theme.of(context).colorScheme.onPrimary
      : widget.timeline.room.getColorOfUser(relatedEvent!.senderId);

  String? get relatedEventDisplayName => relatedEvent == null
      ? null
      : widget.timeline.client.fetchPeer(relatedEvent!.senderId).displayName;

  Widget? eventToWidget(TimelineEvent event) {
    if (event.status == TimelineEventStatus.removed) return const SizedBox();
    switch (widget.event.type) {
      case EventType.message:
      case EventType.sticker:
        return Message(
          senderName: displayName,
          senderColor: color,
          senderAvatar: avatar,
          sentTimeStamp: widget.event.originServerTs,
          onDoubleTap: widget.onDoubleTap,
          onLongPress: widget.onLongPress,
          showSender: widget.showSender,
          reactions: widget.event.reactions,
          currentUserIdentifier: widget.timeline.room.client.user!.identifier,
          replyBody: relatedEvent?.body ??
              (relatedEvent?.type == EventType.sticker
                  ? T.current.messagePlaceholderSticker
                  : null),
          replySenderName: relatedEventDisplayName,
          replySenderColor: replyColor,
          isInReply: widget.event.relatedEventId != null,
          edited: widget.event.edited,
          onReactionTapped: widget.onReactionTapped,
          body: buildBody(),
          menuBuilder: BuildConfig.DESKTOP ? buildMenu : null,
        );
      case EventType.roomCreated:
        return GenericRoomEvent(T.current.userCreatedRoom(displayName),
            m.Icons.room_preferences_outlined);
      case EventType.memberJoined:
        return GenericRoomEvent(
            T.current.userJoinedRoom(displayName), m.Icons.waving_hand_rounded);
      case EventType.memberLeft:
        return GenericRoomEvent(T.current.userLeftRoom(displayName),
            m.Icons.subdirectory_arrow_left_rounded);
      case EventType.memberAvatar:
        return GenericRoomEvent(
            T.current.userUpdatedAvatar(displayName), m.Icons.person);
      case EventType.memberDisplayName:
        return GenericRoomEvent(
            T.current.userUpdatedDisplayName(displayName), m.Icons.edit);
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
    return m.Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: DecoratedBox(
        decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            color: m.Theme.of(context).colorScheme.surface,
            border: Border.all(
                color:
                    m.Theme.of(context).extension<ExtraColors>()!.surfaceLow2,
                width: 1)),
        child: m.Padding(
          padding: const EdgeInsets.fromLTRB(4, 0, 4, 0),
          child: Row(
            children: [
              buildMenuEntry(m.Icons.reply, "Reply", () {
                widget.setReplyingEvent!.call();
              }),
              buildMenuEntry(m.Icons.add_reaction, "Add Reaction", () => null),
              if (canUserEditEvent() && widget.event.editable)
                buildMenuEntry(m.Icons.edit, "Edit", () {
                  widget.setEditingEvent?.call();
                }),
              buildMenuEntry(m.Icons.more_vert, "Options", () => null)
            ],
          ),
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
        widget.event.senderId == widget.timeline.room.client.user!.identifier;
  }

  Widget buildBody() {
    switch (widget.event.type) {
      case EventType.message:
        return buildMessageBody();
      case EventType.sticker:
        return buildStickerBody();
      default:
        return const Placeholder(
          fallbackHeight: 50,
        );
    }
  }

  Widget buildMessageBody() {
    return m.Material(
      color: m.Colors.transparent,
      child: Column(
        children: [
          buildMessageText(),
          if (widget.event.attachments != null) buildMessageAttachments()
        ],
      ),
    );
  }

  Widget buildMessageAttachments() {
    return Wrap(
      children: widget.event.attachments!
          .map((e) => Padding(
                padding: const EdgeInsets.fromLTRB(0, 8, 8, 8),
                child: MessageAttachment(
                  e,
                ),
              ))
          .toList(),
    );
  }

  Widget buildMessageText() {
    const bool selectableText = BuildConfig.DESKTOP || BuildConfig.WEB;

    if (widget.event.bodyFormat != null)
      return selectableText
          ? m.SelectionArea(child: widget.event.formattedContent!)
          : widget.event.formattedContent!;

    if (widget.event.body != null)
      return selectableText
          ? m.SelectionArea(child: tiamat.Text.body(widget.event.body!))
          : tiamat.Text.body(widget.event.body!);

    return const SizedBox();
  }

  Widget buildStickerBody() {
    return m.Material(
      color: m.Colors.transparent,
      child: Column(
        children: [
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
