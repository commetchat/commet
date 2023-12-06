import 'package:commet/ui/molecules/message_input.dart';
import 'package:commet/ui/molecules/read_indicator.dart';
import 'package:commet/ui/molecules/timeline_viewer.dart';
import 'package:commet/ui/organisms/chat/chat.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:tiamat/tiamat.dart';

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
      : state.room.client.getPeer(state.interactingEvent!.senderId).displayName;

  Color? get relatedEventSenderColor => state.interactingEvent == null
      ? null
      : state.room.getColorOfUser(state.interactingEvent!.senderId);

  @override
  Widget build(BuildContext context) {
    return Tile(
      borderLeft: true,
      child: Column(children: [
        Expanded(child: timeline()),
        input(),
      ]),
    );
  }

  Widget timeline() {
    return state.timeline == null
        ? const Center(
            child: CircularProgressIndicator(),
          )
        : TimelineViewer(
            timeline: state.timeline!,
            markAsRead: state.room.timeline!.markAsRead,
            setReplyingEvent: (event) => state.setInteractingEvent(event,
                type: EventInteractionType.reply),
            setEditingEvent: (event) => state.setInteractingEvent(event,
                type: EventInteractionType.edit),
            onAddReaction: state.addReaction,
          );
  }

  Widget input() {
    return MessageInput(
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
      isProcessing: state.processing,
      enabled: state.room.permissions.canSendMessage,
      typingUsernames:
          state.room.typingPeers.map((e) => e.displayName).toList(),
      relatedEventBody: state.interactingEvent?.body,
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
      readIndicator: ReadIndicator(
        key: ValueKey("room_read_indicator_key_${state.room.identifier}"),
        room: state.room,
        initialList: state.room.timeline?.receipts,
      ),
    );
  }
}
