import 'package:commet/client/components/emoticon/emoticon.dart';
import 'package:commet/config/build_config.dart';
import 'package:commet/ui/atoms/emoji_reaction.dart';
import 'package:commet/utils/text_utils.dart';
import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';
import 'package:tiamat/tiamat.dart';
import 'package:tiamat/tiamat.dart' as tiamat;
import 'package:flutter/material.dart' as material;

class Message extends StatefulWidget {
  const Message(
      {super.key,
      required this.senderName,
      required this.senderColor,
      required this.sentTimeStamp,
      required this.body,
      required this.currentUserIdentifier,
      this.senderAvatar,
      this.replyBody,
      this.replySenderColor,
      this.replySenderName,
      this.edited = false,
      this.onDoubleTap,
      this.reactions,
      this.onReactionTapped,
      this.onLongPress,
      this.isInReply = false,
      this.child,
      this.showSender = true});
  final double avatarSize = 32;

  final bool showSender;
  final String senderName;
  final Color? senderColor;

  final String? replyBody;
  final String? replySenderName;
  final Color? replySenderColor;
  final bool isInReply;

  final ImageProvider? senderAvatar;
  final DateTime sentTimeStamp;

  final String currentUserIdentifier;

  final bool edited;

  final Widget body;

  final Widget? child;

  final Map<Emoticon, Set<String>>? reactions;

  final Function()? onLongPress;
  final Function()? onDoubleTap;
  final Function(Emoticon emote)? onReactionTapped;

  @override
  State<Message> createState() => _MessageState();
}

class _MessageState extends State<Message> {
  bool hovered = false;
  bool editMode = false;

  String get messageEditedMarker => Intl.message("(Edited)",
      name: "messageEditedMarker",
      desc: "Short text to mark that a message has been edited");

  @override
  Widget build(BuildContext context) {
    return material.Material(
        color: material.Colors.transparent,
        child: BuildConfig.MOBILE
            ? material.InkWell(
                onLongPress: widget.onLongPress,
                onDoubleTap: widget.onDoubleTap,
                child: buildContent(),
              )
            : buildContent());
  }

  @override
  void dispose() {
    super.dispose();
  }

  Widget buildContent() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 2, 8, 2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (widget.isInReply) replyText(),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              avatar(),
              Flexible(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 0, 0, 0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (widget.showSender)
                        Padding(
                          padding: const EdgeInsets.fromLTRB(0, 0, 0, 0),
                          child: Row(
                            children: [
                              senderName(),
                              timeStamp(),
                            ],
                          ),
                        ),
                      body(),
                      if (widget.edited) edited(),
                      if (widget.child != null) widget.child!,
                      if (widget.reactions != null) reactions(),
                    ],
                  ),
                ),
              )
            ],
          ),
        ],
      ),
    );
  }

  Widget avatar() {
    return SizedBox(
      width: widget.avatarSize,
      height: widget.showSender ? widget.avatarSize : 0,
      child: widget.showSender
          ? Avatar(
              radius: widget.avatarSize / 2,
              placeholderText: widget.senderName,
              image: widget.senderAvatar,
              placeholderColor: widget.senderColor,
            )
          : null,
    );
  }

  Widget senderName() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 0, 4, 1),
      child: SizedBox(
        child: tiamat.Text.name(
          widget.senderName,
          color: widget.senderColor,
        ),
      ),
    );
  }

  Widget replyText() {
    return SizedBox(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          SizedBox(
            width: widget.avatarSize,
          ),
          const Icon(material.Icons.keyboard_arrow_right_rounded),
          tiamat.Text.name(
            widget.replySenderName ?? "Loading...",
            color: widget.replySenderColor,
          ),
          Flexible(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(4, 0, 4, 0),
              child: tiamat.Text(
                widget.replyBody ?? "Unknown",
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                color: material.Theme.of(context).colorScheme.secondary,
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget timeStamp() {
    return AnimatedOpacity(
      opacity: hovered ? 1 : 0,
      duration: const Duration(milliseconds: 200),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(4, 0, 4, 0),
        child: SizedBox(
          child: tiamat.Text.labelLow(
              TextUtils.timestampToLocalizedTime(widget.sentTimeStamp)),
        ),
      ),
    );
  }

  Widget body() {
    return widget.body;
  }

  Widget edited() {
    return tiamat.Text.labelLow(messageEditedMarker);
  }

  Widget reactions() {
    return Wrap(
        spacing: 3,
        runSpacing: 3,
        direction: material.Axis.horizontal,
        children: widget.reactions!.keys.map((key) {
          var value = widget.reactions![key]!;
          return EmojiReaction(
              emoji: key,
              onTapped: widget.onReactionTapped,
              numReactions: value.length,
              highlighted: value.contains(widget.currentUserIdentifier));
        }).toList());
  }
}
