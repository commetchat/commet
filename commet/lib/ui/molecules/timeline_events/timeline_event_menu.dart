import 'package:commet/client/components/emoticon/dynamic_emoticon_pack.dart';
import 'package:commet/client/components/emoticon/emoticon.dart';
import 'package:commet/client/components/emoticon/emoticon_component.dart';
import 'package:commet/client/components/emoticon_recent/recent_emoticon_component.dart';
import 'package:commet/client/components/message_effects/message_effect_component.dart';
import 'package:commet/client/components/photo_album_room/photo_album_room_component.dart';
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
import 'package:commet/utils/autofill_utils.dart';
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
  late final List<Emoticon> recentReactions;
  TimelineEventMenuEntry? addReactionAction;

  final Function(TimelineEvent event)? setEditingEvent;
  final Function(TimelineEvent event)? setReplyingEvent;
  final Function()? onActionFinished;

  final bool isThreadTimeline;

  String get promptPinMessage => Intl.message(
        "Pin Message",
        desc: "Label for the menu option to pin a message",
        name: "promptPinMessage",
      );

  String get promptUnpinMessage => Intl.message(
        "Unpin Message",
        desc: "Label for the menu option to unpin a message",
        name: "promptUnpinMessage",
      );

  String get promptReplyInThread => Intl.message(
        "Reply In Thread",
        desc: "Label for the menu option to reply to a message inside a thread",
        name: "promptReplyInThread",
      );

  String get promptShowSource => Intl.message(
        "Show Source",
        desc: "Label for the menu option to view the JSON source of an event",
        name: "promptShowSource",
      );

  String get promptReplayMessageEffect => Intl.message(
        "Replay Effect",
        desc:
            "If a message was sent with an effect, this prompts to replay the effect",
        name: "promptReplayMessageEffect",
      );

  String get promptCancelEventSend => Intl.message(
        "Cancel",
        desc:
            "When a message failed to send, this prompts to cancel sending the event",
        name: "promptCancelEventSend",
      );

  String get promptRetryEventSend => Intl.message(
        "Retry",
        desc:
            "When a message failed to send, this prompts to retry sending the event",
        name: "promptRetryEventSend",
      );

  TimelineEventMenu({
    required this.timeline,
    required this.event,
    this.setEditingEvent,
    this.setReplyingEvent,
    this.onActionFinished,
    this.isThreadTimeline = false,
  }) {
    bool canEditEvent = false;
    bool canSaveAttachment = false;
    bool canAddReaction = false;
    bool canReplyInThread = false;
    bool canCopy = false;
    bool canEditPinState = false;
    bool canPin = false;
    bool canUnpin = false;
    bool hasEffect = false;
    bool canReply = false;
    bool canDeleteEvent = false;

    bool canRetrySend = event.status != TimelineEventStatus.synced;
    bool canCancelSend = event.status != TimelineEventStatus.synced;

    var effects = timeline.room.client.getComponent<MessageEffectComponent>();
    var emoticons = timeline.room.getComponent<RoomEmoticonComponent>();
    var pins = timeline.room.getComponent<PinnedMessagesComponent>();
    var photos = timeline.room.getComponent<PhotoAlbumRoom>();

    if (event.status == TimelineEventStatus.synced) {
      canEditEvent = event is TimelineEventMessage &&
          timeline.room.permissions.canUserEditMessages &&
          event.senderId == timeline.room.client.self!.identifier &&
          setEditingEvent != null;

      canDeleteEvent = timeline.canDeleteEvent(event) &&
          event.status == TimelineEventStatus.synced;

      canReply = event is TimelineEventMessage ||
          event is TimelineEventSticker ||
          event is TimelineEventEmote;

      if (photos != null) {
        canReply = false;
        canEditEvent = false;
      }

      if (event is TimelineEventMessage) {
        canSaveAttachment =
            (event as TimelineEventMessage).attachments?.isNotEmpty == true;
      }

      canAddReaction =
          (event is TimelineEventMessage || event is TimelineEventSticker) &&
              emoticons != null;

      canReplyInThread = !isThreadTimeline && event is TimelineEventMessage;

      canCopy = event is TimelineEventMessage;

      canEditPinState = pins?.canPinMessages == true &&
          (event is TimelineEventMessage ||
              event is TimelineEventSticker ||
              event is TimelineEventEmote);

      bool isPinned = pins?.isMessagePinned(event.eventId) == true;

      canPin = canEditPinState && !isPinned;
      canUnpin = canEditPinState && isPinned;

      hasEffect = effects?.hasEffect(event) == true;
    }

    var reactions =
        timeline.room.client.getComponent<RecentEmoticonComponent>();
    if (reactions != null && canAddReaction) {
      recentReactions = reactions.getRecentReactionEmoticon(timeline.room);
    } else {
      recentReactions = List.empty();
    }

    if (canAddReaction) {
      var recent = timeline.room.client
          .getComponent<RecentEmoticonComponent>()
          ?.getRecentReactionEmoticon(timeline.room);

      var availableEmoji = emoticons!.availableEmoji;

      if (recent != null && recent.isNotEmpty) {
        availableEmoji.insert(
            0,
            DynamicEmoticonPack(
                identifier: "dynamic_pack_frequently_used_reactions",
                displayName: "Frequently Used",
                icon: Icons.schedule,
                emoticons: recent,
                usage: EmoticonUsage.all));
      }

      addReactionAction = TimelineEventMenuEntry(
        name: CommonStrings.promptAddReaction,
        icon: Icons.add_reaction,
        secondaryMenuBuilder: (context, dismissSecondaryMenu) {
          return EmojiPicker(availableEmoji,
              searchDelegate: (search) => AutofillUtils.searchEmoticon(search,
                      client: timeline.client, room: timeline.room, limit: 50)
                  .whereType<AutofillSearchResultEmoticon>()
                  .toList(),
              preferredTooltipDirection: AxisDirection.left,
              onEmoticonPressed: (emote) async {
                timeline.room.addReaction(event, emote);
                await Future.delayed(const Duration(milliseconds: 100));
                dismissSecondaryMenu();
              });
        },
      );
    }

    primaryActions = [
      if (canRetrySend)
        TimelineEventMenuEntry(
          name: promptRetryEventSend,
          icon: Icons.refresh,
          action: (BuildContext context) {
            timeline.room.retrySend(event);
            onActionFinished?.call();
          },
        ),
      if (canCancelSend)
        TimelineEventMenuEntry(
          name: promptCancelEventSend,
          icon: Icons.cancel,
          action: (BuildContext context) {
            timeline.room.cancelSend(event);
            onActionFinished?.call();
          },
        ),
      if (hasEffect)
        TimelineEventMenuEntry(
          name: promptReplayMessageEffect,
          icon: Icons.celebration,
          action: (BuildContext context) {
            effects?.doEffect(event);
            onActionFinished?.call();
          },
        ),
      if (canEditEvent)
        TimelineEventMenuEntry(
          name: CommonStrings.promptEdit,
          icon: Icons.edit,
          action: (BuildContext context) {
            setEditingEvent?.call(event);
            onActionFinished?.call();
          },
        ),
      if (canReply)
        TimelineEventMenuEntry(
          name: CommonStrings.promptReply,
          icon: Icons.reply,
          action: (BuildContext context) {
            setReplyingEvent?.call(event);
            onActionFinished?.call();
          },
        ),
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
      if (canDeleteEvent)
        TimelineEventMenuEntry(
          name: CommonStrings.promptDelete,
          icon: Icons.delete,
          action: (BuildContext context) {
            if (preferences.askBeforeDeletingMessageEnabled) {
              AdaptiveDialog.confirmation(context).then((value) {
                if (value == true) {
                  timeline.deleteEvent(event);
                }
                onActionFinished?.call();
              });
            } else {
              timeline.deleteEvent(event);
            }
          },
        ),
    ];

    secondaryActions = [
      if (canReplyInThread)
        TimelineEventMenuEntry(
          name: promptReplyInThread,
          icon: Icons.message_rounded,
          action: (context) {
            EventBus.openThread.add((
              timeline.client.identifier,
              timeline.room.identifier,
              event.eventId,
            ));
            onActionFinished?.call();
          },
        ),
      if (canPin)
        TimelineEventMenuEntry(
          name: promptPinMessage,
          icon: Icons.push_pin,
          action: (context) {
            pins!.pinMessage(event.eventId);
            onActionFinished?.call();
          },
        ),
      if (canUnpin)
        TimelineEventMenuEntry(
          name: promptUnpinMessage,
          icon: Icons.push_pin,
          action: (context) {
            pins!.unpinMessage(event.eventId);
            onActionFinished?.call();
          },
        ),
      if (canCopy)
        TimelineEventMenuEntry(
            name: CommonStrings.promptCopy,
            icon: Icons.copy,
            action: (context) {
              Clipboard.setData(ClipboardData(
                text: (event as TimelineEventMessage).plainTextBody,
              ));
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
              return SizedBox(
                width: 1000,
                child: SelectionArea(
                  child: ExpandableCodeBlock(
                      expanded: true, text: event.source, language: "json"),
                ),
              );
            },
          );
        },
      ),
      if (preferences.developerMode &&
          (event is TimelineEventMessage || event is TimelineEventSticker))
        TimelineEventMenuEntry(
          name: "Show Notification",
          icon: Icons.notification_add,
          action: (BuildContext context) async {
            var room = timeline.room;

            var content = await MessageNotificationContent.fromEvent(
              event,
              room,
            );
            if (content != null) {
              NotificationManager.notify(content, forceShow: true);
            }

            onActionFinished?.call();
          },
        ),
    ];
  }
}

class TimelineEventMenuEntry {
  final String name;
  final Function(BuildContext context)? action;
  final IconData icon;

  final Widget Function(BuildContext context, Function() dismissMenu)?
      secondaryMenuBuilder;

  TimelineEventMenuEntry({
    required this.name,
    required this.icon,
    this.action,
    this.secondaryMenuBuilder,
  });
}
