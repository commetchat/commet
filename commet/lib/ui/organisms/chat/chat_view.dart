import 'package:commet/client/components/push_notification/notification_manager.dart';
import 'package:commet/client/room.dart';
import 'package:commet/client/timeline_events/timeline_event.dart';
import 'package:commet/config/layout_config.dart';
import 'package:commet/ui/molecules/message_input.dart';
import 'package:commet/ui/molecules/read_indicator.dart';
import 'package:commet/ui/molecules/room_timeline_widget/room_timeline_widget.dart';
import 'package:commet/ui/molecules/typing_indicators_widget.dart';
import 'package:commet/ui/organisms/chat/chat.dart';
import 'package:commet/ui/organisms/particle_player/particle_player.dart';
import 'package:commet/utils/autofill_utils.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class ChatView extends StatelessWidget {
  const ChatView(this.state, {super.key});
  final ChatState state;

  String get sendEncryptedMessagePrompt =>
      Intl.message("Send an encrypted message",
          name: "sendEncryptedMessagePrompt",
          desc: "Placeholder text for message input in an encrypted room");

  String get sendUnencryptedMessagePrompt => Intl.message("Send a message",
      name: "sendUnencryptedMessagePrompt",
      desc: "Placeholder text for message input in an unencrypted room");

  String get cantSentMessagePrompt => Intl.message(
      "You do not have permission to send a message in this room",
      name: "cantSentMessagePrompt",
      desc: "Text that explains the user cannot send a message in this room");

  String? get relatedEventSenderName => state.interactingEvent == null
      ? null
      : state.room
          .getMemberOrFallback(state.interactingEvent!.senderId)
          .displayName;

  Color? get relatedEventSenderColor => state.interactingEvent == null
      ? null
      : state.room.getColorOfUser(state.interactingEvent!.senderId);

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Expanded(
          child: Stack(
        fit: StackFit.expand,
        children: [timeline(), const ParticlePlayer()],
      )),
      input(),
    ]);
  }

  Widget timeline() {
    return state.timeline == null
        ? const Center(
            child: CircularProgressIndicator(),
          )
        : RoomTimelineWidget(
            key: ValueKey("${state.room.identifier}-timeline"),
            timeline: state.timeline!,
            setReplyingEvent: (event) => state.setInteractingEvent(event,
                type: EventInteractionType.reply),
            setEditingEvent: (event) => state.setInteractingEvent(event,
                type: EventInteractionType.edit),
            isThreadTimeline: state.isThread,
            clearNotifications: clearNotifications,
          );
  }

  void handleMarkAsRead(TimelineEvent event) async {
    // Dont update read receipts if in background
    if (WidgetsBinding.instance.lifecycleState != AppLifecycleState.resumed) {
      return;
    }

    state.room.timeline!.markAsRead(event);
  }

  clearNotifications(Room room) {
    // if we clear notifications when opening bubble, the bubble disappears
    if (state.isBubble) {
      return;
    }

    NotificationManager.clearNotifications(room);
  }

  Widget input() {
    return ClipRRect(
      child: MessageInput(
        isRoomE2EE: state.room.isE2EE,
        focusKeyboard: state.onFocusMessageInput.stream,
        attachments: state.attachments,
        interactionType: state.interactionType,
        gifComponent: state.gifs,
        onSendMessage: (message) {
          state.sendMessage(message);
          return MessageInputSendResult.success;
        },
        onTextUpdated: state.onInputTextUpdated,
        addAttachment: state.addAttachment,
        removeAttachment: state.removeAttachment,
        size: Layout.mobile ? 40 : 35,
        iconScale: Layout.mobile ? 0.6 : 0.5,
        isProcessing: state.processing,
        enabled: state.room.permissions.canSendMessage,
        relatedEventBody: state.interactingEvent?.plainTextBody,
        relatedEventSenderName: relatedEventSenderName,
        relatedEventSenderColor: relatedEventSenderColor,
        setInputText: state.setMessageInputText.stream,
        availibleEmoticons: state.emoticons?.availableEmoji,
        availibleStickers: state.emoticons?.availableStickers,
        sendSticker: state.sendSticker,
        sendGif: state.sendGif,
        editLastMessage: state.editLastMessage,
        hintText: state.room.permissions.canSendMessage
            ? state.room.isE2EE
                ? sendEncryptedMessagePrompt
                : sendUnencryptedMessagePrompt
            : cantSentMessagePrompt,
        cancelReply: () {
          state.setInteractingEvent(null);
        },
        typingIndicatorWidget: state.typingIndicators != null
            ? TypingIndicatorsWidget(
                component: state.typingIndicators!,
                key: ValueKey(
                    "room_typing_indicators_key_${state.room.identifier}"),
              )
            : null,
        readIndicator: state.receipts != null
            ? ReadIndicator(
                key: ValueKey(
                    "room_read_indicator_key_${state.room.identifier}"),
                component: state.receipts!,
                room: state.room,
              )
            : null,
        processAutofill: (text) => AutofillUtils.search(text, state.room),
      ),
    );
  }
}
