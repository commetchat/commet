import 'package:commet/client/timeline.dart';
import 'package:commet/main.dart';
import 'package:commet/ui/molecules/emoji_picker.dart';
import 'package:commet/ui/molecules/message_popup_menu/message_popup_menu.dart';
import 'package:commet/ui/molecules/timeline_event.dart';
import 'package:commet/utils/common_strings.dart';
import 'package:commet/utils/notification/notification_content.dart';
import 'package:flutter/material.dart';
import 'package:tiamat/tiamat.dart' as tiamat;

class MessagePopupMenuViewDialog extends StatelessWidget {
  final MessagePopupMenuState state;

  const MessagePopupMenuViewDialog(this.state, {super.key});

  @override
  Widget build(BuildContext context) {
    return buildMessageMenu(context, state.event);
  }

  Widget buildMessageMenu(BuildContext context, TimelineEvent event) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(10, 10, 10, 0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ShaderMask(
              shaderCallback: (bounds) {
                return const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.white,
                    Colors.transparent,
                  ],
                  stops: [0.90, 1.0],
                ).createShader(bounds);
              },
              child: SizedBox(
                height: 100,
                child: Center(
                  child: SingleChildScrollView(
                    physics: const NeverScrollableScrollPhysics(),
                    child: SizedBox(
                      child: TimelineEventView(
                          event: event, timeline: state.timeline),
                    ),
                  ),
                ),
              ),
            ),
            SizedBox(
              height: 50,
              child: tiamat.TextButton(
                CommonStrings.promptReply,
                icon: Icons.reply,
                onTap: () {
                  state.setReplyingEvent();
                  Navigator.pop(context);
                },
              ),
            ),
            if (state.emoticons != null)
              SizedBox(
                height: 50,
                child: tiamat.TextButton(
                  CommonStrings.promptAddReaction,
                  icon: Icons.add_reaction_rounded,
                  onTap: () {
                    Navigator.pop(context);
                    showReactionMenu(event, context);
                  },
                ),
              ),
            if (state.isEditable)
              SizedBox(
                height: 50,
                child: tiamat.TextButton(
                  CommonStrings.promptEdit,
                  icon: Icons.edit,
                  onTap: () {
                    state.setEditingEvent();
                    Navigator.pop(context);
                  },
                ),
              ),
            if (state.isDeletable)
              SizedBox(
                height: 50,
                child: tiamat.TextButton(
                  CommonStrings.promptDelete,
                  icon: Icons.delete_forever,
                  onTap: () {
                    Navigator.pop(context);
                    state.deleteEvent();
                  },
                ),
              ),
            SizedBox(
              height: 50,
              child: tiamat.TextButton(
                CommonStrings.promptCopy,
                icon: Icons.copy,
                onTap: () {
                  state.copyToClipboard();
                  Navigator.pop(context);
                },
              ),
            ),
            if (preferences.developerMode)
              SizedBox(
                height: 50,
                child: tiamat.TextButton(
                  "Send Notification",
                  icon: Icons.notification_add,
                  onTap: () async {
                    var room = state.timeline.room;
                    var user = room.client.getPeer(state.event.senderId);
                    await user.loading;

                    var content = MessageNotificationContent(
                      senderName: user.displayName,
                      senderImage: user.avatar,
                      roomName: room.displayName,
                      roomId: room.identifier,
                      roomImage: await room.getShortcutImage(),
                      content: event.body ?? "Sent a message",
                      clientId: room.client.identifier,
                      eventId: event.eventId,
                      isDirectMessage: room.isDirectMessage,
                    );

                    notificationManager.notify(content, bypassModifiers: true);
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }

  void showReactionMenu(TimelineEvent event, BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.6,
          minChildSize: 0.6,
          builder: (context, scrollController) {
            return SizedBox(
                height: 700,
                child: EmojiPicker(state.emoticons!.availableEmoji,
                    size: 48,
                    packButtonSize: 40, onEmoticonPressed: (emoticon) {
                  state.addReaction(emoticon);
                  Navigator.pop(context);
                }));
          },
        );
      },
    );
  }
}
