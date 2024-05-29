import 'package:commet/client/components/threads/thread_component.dart';
import 'package:commet/client/components/url_preview/url_preview_component.dart';
import 'package:commet/config/build_config.dart';
import 'package:commet/main.dart';
import 'package:commet/ui/atoms/generic_room_event.dart';
import 'package:commet/ui/atoms/thread_reply_footer.dart';
import 'package:commet/ui/molecules/message.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' as m;
import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';
import 'package:tiamat/atoms/icon_button.dart';
import 'package:tiamat/tiamat.dart' as tiamat;

import '../../client/client.dart';
import '../../client/components/emoticon/emoticon.dart';
import '../atoms/message_attachment.dart';

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
      this.deleteEvent,
      this.canDeleteEvent = false,
      this.useCachedFormat = false,
      this.threadsComponent,
      this.isInThread = false,
      this.onThreadOpened,
      this.debugInfo});
  final TimelineEvent event;
  final bool hovered;
  final Function? onDelete;
  final bool showSender;
  final String? debugInfo;
  final Timeline timeline;
  final bool useCachedFormat;
  final Function()? onDoubleTap;
  final Function()? onLongPress;
  final Function()? setReplyingEvent;
  final Function()? setEditingEvent;
  final Function()? deleteEvent;
  final Function()? onThreadOpened;
  final bool canDeleteEvent;
  final bool isInThread;
  final Function(Emoticon emote)? onReactionTapped;
  final ThreadsComponent? threadsComponent;

  @override
  State<TimelineEventView> createState() => _TimelineEventState();
}

class _TimelineEventState extends State<TimelineEventView> {
  TimelineEvent? relatedEvent;

  String messagePlaceholderSticker(String user) =>
      Intl.message("$user sent a sticker",
          desc: "Message body for when a user sends a sticker",
          args: [user],
          name: "messagePlaceholderSticker");

  String get messageFailedToDecrypt => Intl.message("Failed to decrypt event",
      desc: "Placeholde text for when a message fails to decrypt",
      name: "messageFailedToDecrypt");

  String messagePlaceholderUserCreatedRoom(String user) =>
      Intl.message("$user created the room!",
          desc: "Message body for when a user created the room",
          args: [user],
          name: "messagePlaceholderUserCreatedRoom");

  String messagePlaceholderUserJoinedRoom(String user) =>
      Intl.message("$user joined the room!",
          desc: "Message body for when a user joins the room",
          args: [user],
          name: "messagePlaceholderUserJoinedRoom");

  String messagePlaceholderUserLeftRoom(String user) =>
      Intl.message("$user left the room",
          desc: "Message body for when a user leaves the room",
          args: [user],
          name: "messagePlaceholderUserLeftRoom");

  String messagePlaceholderUserUpdatedAvatar(String user) =>
      Intl.message("$user updated their avatar",
          desc: "Message body for when a user updates their avatar",
          args: [user],
          name: "messagePlaceholderUserUpdatedAvatar");

  String messagePlaceholderUserUpdatedName(String user) =>
      Intl.message("$user updated their display name",
          desc: "Message body for when a user updates their display name",
          args: [user],
          name: "messagePlaceholderUserUpdatedName");

  String messagePlaceholderUserInvited(String sender, String invitedUser) =>
      Intl.message("$sender invited $invitedUser",
          desc: "Message body for when a user invites another user to the room",
          args: [sender, invitedUser],
          name: "messagePlaceholderUserInvited");

  String messagePlaceholderUserRejectedInvite(String user) =>
      Intl.message("$user rejected the invitation",
          desc: "Message body for when a user rejected an invitation to a room",
          args: [user],
          name: "messagePlaceholderUserRejectedInvite");

  String messageUserEmote(String user, String emote) =>
      Intl.message("*$user $emote",
          desc: "Message to display when a user does a custom emote (/me)",
          args: [user, emote],
          name: "messageUserEmote");

  String get errorMessageFailedToSend => Intl.message("Failed to send",
      desc:
          "Text that is placed below a message when the message fails to send",
      name: "errorMessageFailedToSend");

  String get displayName => widget.timeline.room
      .getMemberOrFallback(widget.event.senderId)!
      .displayName;

  ImageProvider? get avatar =>
      widget.timeline.room.getMemberOrFallback(widget.event.senderId)!.avatar;

  Color get color => widget.timeline.room.getColorOfUser(widget.event.senderId);

  Color get replyColor => relatedEvent == null
      ? m.Theme.of(context).colorScheme.onPrimary
      : widget.timeline.room.getColorOfUser(relatedEvent!.senderId);

  String? get relatedEventDisplayName => relatedEvent == null
      ? null
      : widget.timeline.room
          .getMemberOrFallback(relatedEvent!.senderId)!
          .displayName;

  UrlPreviewData? urlPreviews;
  bool loadingUrlPreviews = false;
  TimelineEvent? threadReplyEvent;

  String? get threadReplyEventDisplayName => threadReplyEvent == null
      ? null
      : widget.timeline.room
          .getMemberOrFallback(threadReplyEvent!.senderId)!
          .displayName;

  Color get threadReplyColor => threadReplyEvent == null
      ? m.Theme.of(context).colorScheme.onPrimary
      : widget.timeline.room.getColorOfUser(threadReplyEvent!.senderId);

  ImageProvider? get threadReplyAvatar => threadReplyEvent == null
      ? null
      : widget.timeline.room
          .getMemberOrFallback(threadReplyEvent!.senderId)!
          .avatar;

  @override
  void initState() {
    if (widget.event.relatedEventId != null) {
      relatedEvent = widget.timeline.tryGetEvent(widget.event.relatedEventId!);
      if (relatedEvent == null) {
        fetchRelatedEvent();
      }
    }

    if (widget.threadsComponent
            ?.isHeadOfThread(widget.event, widget.timeline) ==
        true) {
      threadReplyEvent = widget.threadsComponent!
          .getFirstReplyToThread(widget.event, widget.timeline);
    }

    var component =
        widget.timeline.room.client.getComponent<UrlPreviewComponent>();
    if (component?.shouldGetPreviewData(widget.timeline.room, widget.event) ==
        true) {
      getCachedUrlPreview();
      if (urlPreviews == null) {
        loadingUrlPreviews = true;
        fetchUrlPreviews();
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

  void getCachedUrlPreview() {
    var component =
        widget.timeline.room.client.getComponent<UrlPreviewComponent>();

    if (component == null) {
      return;
    }

    var cached = component.getCachedPreview(widget.timeline.room, widget.event);
    urlPreviews = cached;
  }

  void fetchUrlPreviews() async {
    if (widget.event.links == null) {
      return;
    }

    var component =
        widget.timeline.room.client.getComponent<UrlPreviewComponent>();

    if (component == null) {
      return;
    }

    var data = await component.getPreview(widget.timeline.room, widget.event);

    if (data?.image != null) {
      if (mounted) {
        await precacheImage(data!.image!, context);
      }
    }

    if (mounted) {
      setState(() {
        urlPreviews = data;
        loadingUrlPreviews = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return eventToWidget(widget.event) ?? Container();
  }

  Widget? eventToWidget(TimelineEvent event) {
    if (event.status == TimelineEventStatus.removed) return const SizedBox();
    switch (widget.event.type) {
      case EventType.message:
      case EventType.sticker:
        if (widget.isInThread == false &&
            widget.threadsComponent
                    ?.isEventInResponseToThread(event, widget.timeline) ==
                true) {
          return null;
        }

        Widget result = Message(
          senderName: displayName,
          senderColor: color,
          senderAvatar: avatar,
          sentTimeStamp: widget.event.originServerTs,
          showDetailed: widget.hovered,
          onDoubleTap: widget.onDoubleTap,
          onLongPress: widget.onLongPress,
          showSender: widget.showSender,
          reactions: widget.event.reactions,
          currentUserIdentifier: widget.timeline.room.client.self!.identifier,
          replyBody: relatedEvent?.body ??
              (relatedEvent?.type == EventType.sticker
                  ? messagePlaceholderSticker(displayName)
                  : relatedEvent?.attachments?.firstOrNull?.name),
          replySenderName: relatedEventDisplayName,
          replySenderColor: replyColor,
          isInReply:
              widget.event.relationshipType == EventRelationshipType.reply &&
                  widget.event.relatedEventId != null,
          edited: widget.event.edited,
          onReactionTapped: widget.onReactionTapped,
          links: urlPreviews,
          loadingUrlPreviews: loadingUrlPreviews,
          body: buildBody(),
          child: event.status == TimelineEventStatus.error
              ? tiamat.Text.error(errorMessageFailedToSend)
              : null,
        );

        if (widget.threadsComponent?.isHeadOfThread(event, widget.timeline) ==
                true &&
            threadReplyEvent != null) {
          result = Column(
            mainAxisAlignment: MainAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              result,
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 0, 8, 4),
                child: ThreadReplyFooter(
                  body: threadReplyEvent!.body ?? "",
                  senderName: threadReplyEventDisplayName ?? "Unknown User",
                  senderAvatar: threadReplyAvatar,
                  senderColor: threadReplyColor,
                  onTap: widget.onThreadOpened,
                ),
              ),
            ],
          );
        }

        return result;
      case EventType.encrypted:
        return Message(
            senderName: displayName,
            senderColor: color,
            senderAvatar: avatar,
            showSender: widget.showSender,
            body: tiamat.Text.error(messageFailedToDecrypt),
            currentUserIdentifier: widget.timeline.room.client.self!.identifier,
            sentTimeStamp: widget.event.originServerTs);
      case EventType.roomCreated:
        return GenericRoomEvent(messagePlaceholderUserCreatedRoom(displayName),
            icon: m.Icons.room_preferences_outlined);
      case EventType.memberJoined:
        return GenericRoomEvent(messagePlaceholderUserJoinedRoom(displayName),
            icon: m.Icons.waving_hand_rounded);
      case EventType.memberLeft:
        return GenericRoomEvent(messagePlaceholderUserLeftRoom(displayName),
            icon: m.Icons.subdirectory_arrow_left_rounded);
      case EventType.memberAvatar:
        return GenericRoomEvent(
            messagePlaceholderUserUpdatedAvatar(displayName),
            icon: m.Icons.person);
      case EventType.memberDisplayName:
        return GenericRoomEvent(messagePlaceholderUserUpdatedName(displayName),
            icon: m.Icons.edit);
      case EventType.memberInvited:
        return GenericRoomEvent(
            messagePlaceholderUserInvited(displayName, event.stateKey!),
            icon: m.Icons.person_add);
      case EventType.memberInvitationRejected:
        return GenericRoomEvent(
            messagePlaceholderUserRejectedInvite(displayName),
            icon: m.Icons.subdirectory_arrow_left_rounded);
      case EventType.emote:
        return GenericRoomEvent(
          messageUserEmote(displayName, event.body ?? ""),
          senderImage: avatar,
        );
      default:
        break;
    }

    if (BuildConfig.DEBUG && preferences.developerMode) {
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

  Widget buildMenuEntry(IconData icon, String label, Function()? callback) {
    const double size = 32;
    return tiamat.Tooltip(
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
        widget.event.senderId == widget.timeline.room.client.self!.identifier;
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
    if (widget.event.bodyFormat != null) {
      var formatted = widget.useCachedFormat
          ? widget.event.formattedContent
          : widget.event.buildFormattedContent();

      // if the cache didnt have anything lets just build new content. This should really never happen though
      formatted ??= widget.event.buildFormattedContent();

      return formatted;
    }

    if (widget.event.body != null)
      return tiamat.Text.body("${widget.event.body}\n");

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
