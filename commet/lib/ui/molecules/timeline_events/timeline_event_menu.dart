import 'package:commet/client/components/direct_messages/direct_message_component.dart';
import 'package:commet/client/components/emoticon/emoticon_component.dart';
import 'package:commet/client/components/pinned_messages/pinned_messages_component.dart';
import 'package:commet/client/components/push_notification/notification_content.dart';
import 'package:commet/client/components/push_notification/notification_manager.dart';
import 'package:commet/client/timeline.dart';
import 'package:commet/client/timeline_events/timeline_event.dart';
import 'package:commet/client/timeline_events/timeline_event_emote.dart';
import 'package:commet/client/timeline_events/timeline_event_message.dart';
import 'package:commet/client/timeline_events/timeline_event_sticker.dart';
import 'package:commet/main.dart';
import 'package:commet/ui/atoms/code_block.dart';
import 'package:commet/ui/molecules/emoji_picker.dart';
import 'package:commet/ui/navigation/adaptive_dialog.dart';
import 'package:commet/utils/common_strings.dart';
import 'package:commet/utils/download_utils.dart';
import 'package:commet/utils/event_bus.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

class TimelineEventMenu {
  final Timeline timeline;
  final TimelineEvent event;

  late final List<TimelineEventMenuEntry> primaryActions;
  late final List<TimelineEventMenuEntry> secondaryActions;

  final Function(TimelineEvent event)? setEditingEvent;
  final Function(TimelineEvent event)? setReplyingEvent;
  final Function()? onActionFinished;

  final bool isThreadTimeline;

  String get promptPinMessage => Intl.message("Pin Message",
      desc: "Label for the menu option to pin a message",
      name: "promptPinMessage");

  String get promptReplyInThread => Intl.message("Reply In Thread",
      desc: "Label for the menu option to reply to a message inside a thread",
      name: "promptReplyInThread");

  String get promptShowSource => Intl.message("Show Source",
      desc: "Label for the menu option to view the JSON source of an event",
      name: "promptShowSource");

  TimelineEventMenu({
    required this.timeline,
    required this.event,
    this.setEditingEvent,
    this.setReplyingEvent,
    this.onActionFinished,
    this.isThreadTimeline = false,
  }) {
    bool canEditEvent = event is TimelineEventMessage &&
        timeline.room.permissions.canUserEditMessages &&
        event.senderId == timeline.room.client.self!.identifier &&
        setEditingEvent != null;

    bool canDeleteEvent = timeline.canDeleteEvent(event);

    bool canReply = event is TimelineEventMessage ||
        event is TimelineEventSticker ||
        event is TimelineEventEmote;

    bool canSaveAttachment = false;
    if (event is TimelineEventMessage) {
      canSaveAttachment =
          (event as TimelineEventMessage).attachments?.isNotEmpty == true;
    }
    var emoticons = timeline.room.getComponent<RoomEmoticonComponent>();
    bool canAddReaction =
        (event is TimelineEventMessage || event is TimelineEventSticker) &&
            emoticons != null;

    bool canReplyInThread = !isThreadTimeline && event is TimelineEventMessage;

    bool canCopy = event is TimelineEventMessage;

    var pins = timeline.room.getComponent<PinnedMessagesComponent>();
    bool canPin = pins?.canPinMessages == true;

    primaryActions = [
      if (canEditEvent)
        TimelineEventMenuEntry(
            name: CommonStrings.promptEdit,
            icon: Icons.edit,
            action: (BuildContext context) {
              setEditingEvent?.call(event);
              onActionFinished?.call();
            }),
      if (canReply)
        TimelineEventMenuEntry(
            name: CommonStrings.promptReply,
            icon: Icons.reply,
            action: (BuildContext context) {
              setReplyingEvent?.call(event);
              onActionFinished?.call();
            }),
      if (canSaveAttachment)
        TimelineEventMenuEntry(
            name: CommonStrings.promptDownload,
            icon: Icons.download,
            action: (BuildContext context) {
              var attachment =
                  (event as TimelineEventMessage).attachments?.firstOrNull;
              if (attachment != null) {
                DownloadUtils.downloadAttachment(attachment);
              }
              onActionFinished?.call();
            }),
      if (canAddReaction)
        TimelineEventMenuEntry(
          name: CommonStrings.promptAddReaction,
          icon: Icons.add_reaction,
          secondaryMenuBuilder: (context, dismissSecondaryMenu) {
            return EmojiPicker(emoticons.availableEmoji,
                preferredTooltipDirection: AxisDirection.left,
                onEmoticonPressed: (emote) async {
              timeline.room.addReaction(event, emote);
              await Future.delayed(const Duration(milliseconds: 100));
              dismissSecondaryMenu();
            });
          },
        ),
      if (canReplyInThread)
        TimelineEventMenuEntry(
          name: promptReplyInThread,
          icon: Icons.message_rounded,
          action: (context) {
            EventBus.openThread.add((
              timeline.client.identifier,
              timeline.room.identifier,
              event.eventId
            ));
            onActionFinished?.call();
          },
        ),
      if (canDeleteEvent)
        TimelineEventMenuEntry(
            name: CommonStrings.promptDelete,
            icon: Icons.delete,
            action: (BuildContext context) => {
                  AdaptiveDialog.confirmation(context).then((value) {
                    if (value == true) {
                      timeline.deleteEvent(event);
                    }
                    onActionFinished?.call();
                  })
                }),
    ];

    secondaryActions = [
      if (canPin)
        TimelineEventMenuEntry(
            name: promptPinMessage,
            icon: Icons.push_pin,
            action: (context) {
              pins!.pinMessage(event.eventId);
            }),
      if (canCopy)
        TimelineEventMenuEntry(
            name: CommonStrings.promptCopy,
            icon: Icons.copy,
            action: (context) {
              Clipboard.setData(
                ClipboardData(
                    text: (event as TimelineEventMessage).plainTextBody),
              );

              onActionFinished?.call();
            }),
      TimelineEventMenuEntry(
          name: promptShowSource,
          icon: Icons.code,
          action: (BuildContext context) {
            onActionFinished?.call();
            AdaptiveDialog.show(
              context,
              title: "Source",
              builder: (context) {
                return SelectionArea(
                  child: Codeblock(text: event.source, language: "json"),
                );
              },
            );
          }),
      if (preferences.developerMode && event is TimelineEventMessage)
        TimelineEventMenuEntry(
            name: "Show Notification",
            icon: Icons.notification_add,
            action: (BuildContext context) async {
              var room = timeline.room;
              var user = await room.fetchMember(event.senderId);
              var content = MessageNotificationContent(
                senderName: user.displayName,
                senderImage: user.avatar,
                senderId: user.identifier,
                roomName: room.displayName,
                roomId: room.identifier,
                roomImage: await room.getShortcutImage(),
                content:
                    (event as TimelineEventMessage).body ?? "Sent a message",
                clientId: room.client.identifier,
                eventId: event.eventId,
                isDirectMessage: room.client
                        .getComponent<DirectMessagesComponent>()
                        ?.isRoomDirectMessage(room) ??
                    false,
              );

              NotificationManager.notify(content, bypassModifiers: true);
              onActionFinished?.call();
            }),
    ];
  }
}

class TimelineEventMenuEntry {
  final String name;
  final Function(BuildContext context)? action;
  final IconData icon;

  final Widget Function(BuildContext context, Function() dismissMenu)?
      secondaryMenuBuilder;

  TimelineEventMenuEntry(
      {required this.name,
      required this.icon,
      this.action,
      this.secondaryMenuBuilder});
}
