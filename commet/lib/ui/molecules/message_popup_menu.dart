import 'dart:async';

import 'package:commet/client/components/emoticon/emoticon.dart';
import 'package:commet/client/components/emoticon/emoticon_component.dart';
import 'package:commet/client/timeline.dart';
import 'package:commet/ui/molecules/emoji_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:just_the_tooltip/just_the_tooltip.dart';

import 'package:flutter/material.dart' as m;
import 'package:tiamat/config/style/theme_extensions.dart';
import 'package:tiamat/tiamat.dart' as tiamat;

import '../../client/client.dart';
import '../atoms/tooltip.dart' as t;

class MessagePopupMenu extends StatefulWidget {
  final TimelineEvent event;
  final Timeline timeline;
  final bool isEditable;
  final Stream<int>? onMessageChanged;

  const MessagePopupMenu(this.event, this.timeline,
      {super.key,
      this.setEditingEvent,
      this.onMessageChanged,
      this.setReplyingEvent,
      this.addReaction,
      this.isEditable = false});

  final Function(TimelineEvent? event)? setReplyingEvent;
  final Function(TimelineEvent? event)? setEditingEvent;
  final Function(TimelineEvent event, Emoticon emoticon)? addReaction;

  @override
  State<MessagePopupMenu> createState() => MessagePopupMenuState();
}

class MessagePopupMenuState extends State<MessagePopupMenu> {
  JustTheController controller = JustTheController();
  PageStorageBucket storage = PageStorageBucket();
  RoomEmoticonComponent? emoticons;
  StreamSubscription? sub;

  @override
  void initState() {
    super.initState();
    emoticons = widget.timeline.room.getComponent<RoomEmoticonComponent>();
    sub = widget.onMessageChanged?.listen(onMessageChanged);
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
        child: JustTheTooltip(
            tailLength: 0,
            tailBaseWidth: 0,
            isModal: true,
            controller: controller,
            shadow: const Shadow(color: Colors.transparent),
            backgroundColor:
                kDebugMode ? Colors.red.withAlpha(40) : Colors.transparent,
            content: MouseRegion(
              child: PageStorage(
                bucket: storage,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                  child: DecoratedBox(
                    decoration: BoxDecoration(boxShadow: [
                      BoxShadow(
                          blurRadius: 10,
                          spreadRadius: 2,
                          color: Theme.of(context).shadowColor),
                    ]),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(5),
                      child: Container(
                        color: Theme.of(context).colorScheme.surface,
                        child: SizedBox(
                          width: 300,
                          height: 300,
                          child: emoticons != null
                              ? EmojiPicker(
                                  emoticons!.availableEmoji,
                                  onEmoticonPressed: onEmoticonPicked,
                                )
                              : Container(),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            preferredDirection: AxisDirection.up,
            child: buildMenu(context)));
  }

  void toggleTooltipMenu() {
    if (controller.value == TooltipStatus.isHidden) {
      controller.showTooltip();
    } else {
      controller.hideTooltip();
    }
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
                widget.setReplyingEvent?.call(widget.event);
              }),
              buildMenuEntry(
                  m.Icons.add_reaction, "Add Reaction", toggleTooltipMenu),
              if (widget.isEditable && widget.event.editable)
                buildMenuEntry(m.Icons.edit, "Edit", () {
                  widget.setEditingEvent?.call(widget.event);
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
          child: tiamat.IconButton(
            size: 20,
            icon: icon,
            onPressed: () => callback?.call(),
          ),
        ),
      ),
    );
  }

  void onMessageChanged(int event) {
    controller.hideTooltip();
  }

  void onEmoticonPicked(Emoticon emoticon) {
    controller.hideTooltip();
    widget.addReaction?.call(widget.event, emoticon);
  }
}
