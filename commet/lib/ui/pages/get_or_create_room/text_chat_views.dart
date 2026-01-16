import 'dart:math';

import 'package:commet/ui/atoms/emoji_reaction.dart';
import 'package:commet/ui/molecules/timeline_events/layouts/timeline_event_layout_message.dart';
import 'package:commet/utils/emoji/unicode_emoji.dart';
import 'package:flutter/material.dart';
import 'package:tiamat/tiamat.dart' as tiamat;

class TextChatCreatorDescription extends StatelessWidget {
  const TextChatCreatorDescription({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      tiamat.Text.labelLow(
          "Simple text chat, with all the features you could want! Send messages, media, stickers, GIFs and more!"),
      SizedBox(
        height: 16,
      ),
      Column(
        children: [
          TimelineEventLayoutMessage(
            senderName: "pluto",
            timestamp: "8:17",
            senderColor: Colors.pinkAccent.shade400,
            senderAvatar: AssetImage("assets/images/placeholders/avatar1.jpg"),
            formattedContent: tiamat.Text.body("This guy is a serial gamer"),
          ),
          TimelineEventLayoutMessage(
            senderName: "luna",
            timestamp: "8:30",
            senderAvatar: AssetImage("assets/images/placeholders/avatar2.jpg"),
            senderColor: Colors.cyanAccent,
            formattedContent: tiamat.Text.body("Gotta stay on that grind"),
          ),
          TimelineEventLayoutMessage(
            senderName: "luna",
            timestamp: "8:31",
            senderColor: Colors.cyanAccent,
            senderAvatar: AssetImage("assets/images/placeholders/avatar2.jpg"),
            formattedContent: tiamat.Text.body("u still wanna play smth?"),
          ),
          TimelineEventLayoutMessage(
            senderName: "pluto",
            timestamp: "8:35",
            senderColor: Colors.pinkAccent.shade400,
            senderAvatar: AssetImage("assets/images/placeholders/avatar1.jpg"),
            formattedContent:
                tiamat.Text.body("yea just gimme 1 sec im eating icecream 😋"),
            reactions:
                EmojiReaction(emoji: UnicodeEmoticon("🔥"), numReactions: 1),
          )
        ]
            .mapIndexed((e, i) => Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Transform.rotate(
                    angle: (Random((i + 12) * 7).nextDouble() - 0.5) * 0.04,
                    child: Material(
                        borderRadius: BorderRadius.circular(12),
                        clipBehavior: Clip.antiAlias,
                        color: ColorScheme.of(context).surfaceContainerLow,
                        child: InkWell(
                          onTap: () {},
                          child: Padding(
                            padding: EdgeInsets.all(8),
                            child: e,
                          ),
                        )),
                  ),
                ))
            .toList(),
      )
    ]);
  }
}

class TextChatCreatorForm extends StatefulWidget {
  const TextChatCreatorForm({super.key});

  @override
  State<TextChatCreatorForm> createState() => _TextChatCreatorFormState();
}

class _TextChatCreatorFormState extends State<TextChatCreatorForm> {
  @override
  Widget build(BuildContext context) {
    return const Placeholder();
  }
}
