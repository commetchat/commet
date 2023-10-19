import 'package:commet/ui/molecules/emoji_picker.dart';
import 'package:commet/ui/molecules/message_popup_menu/message_popup_menu.dart';
import 'package:commet/ui/navigation/adaptive_dialog.dart';
import 'package:flutter/material.dart';
import 'package:just_the_tooltip/just_the_tooltip.dart';
import 'dart:async';

import 'package:commet/client/components/emoticon/emoticon.dart';
import 'package:commet/utils/common_strings.dart';

import 'package:flutter/material.dart' as m;
import 'package:tiamat/config/style/theme_extensions.dart';
import 'package:tiamat/tiamat.dart' as tiamat;

import '../../atoms/tooltip.dart' as t;

class MessagePopupMenuViewOverlay extends StatefulWidget {
  final MessagePopupMenuState state;

  const MessagePopupMenuViewOverlay(this.state, {super.key});

  @override
  State<MessagePopupMenuViewOverlay> createState() =>
      _MessagePopupMenuViewOverlayState();
}

class _MessagePopupMenuViewOverlayState
    extends State<MessagePopupMenuViewOverlay> {
  JustTheController controller = JustTheController();
  PageStorageBucket storage = PageStorageBucket();
  StreamSubscription? sub;

  @override
  void initState() {
    super.initState();
    sub = widget.state.onMessageChanged?.listen(onMessageChanged);
    controller.addListener(onTooltipControllerStateChanged);
  }

  @override
  void dispose() {
    sub?.cancel();
    controller.removeListener(onTooltipControllerStateChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return JustTheTooltip(
        tailLength: 0,
        tailBaseWidth: 0,
        isModal: true,
        controller: controller,
        shadow: const Shadow(color: Colors.transparent),
        content: PageStorage(
          bucket: storage,
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
                  child: widget.state.emoticons != null
                      ? EmojiPicker(
                          widget.state.emoticons!.availableEmoji,
                          onEmoticonPressed: onEmoticonPicked,
                        )
                      : Container(),
                ),
              ),
            ),
          ),
        ),
        preferredDirection: AxisDirection.up,
        child: buildMenu(context));
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
              buildMenuEntry(m.Icons.reply, CommonStrings.promptReply, () {
                widget.state.setReplyingEvent();
              }),
              buildMenuEntry(m.Icons.add_reaction,
                  CommonStrings.promptAddReaction, toggleTooltipMenu),
              if (widget.state.isEditable)
                buildMenuEntry(m.Icons.edit, CommonStrings.promptEdit, () {
                  widget.state.setEditingEvent();
                }),
              if (widget.state.isDeletable)
                buildMenuEntry(m.Icons.delete, CommonStrings.promptDelete, () {
                  AdaptiveDialog.confirmation(context).then((value) {
                    if (value == true) {
                      widget.state.deleteEvent();
                    }
                  });
                }),
              buildMenuEntry(
                  m.Icons.more_vert, CommonStrings.promptOptions, () => null),
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
    widget.state.addReaction(emoticon);
  }

  void onTooltipControllerStateChanged() {
    widget.state
        .onPopupStateChanged(controller.value == TooltipStatus.isShowing);
  }
}
