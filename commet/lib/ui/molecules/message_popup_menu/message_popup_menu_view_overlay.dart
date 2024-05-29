import 'package:commet/client/timeline.dart';
import 'package:commet/ui/molecules/emoji_picker.dart';
import 'package:commet/ui/molecules/message_popup_menu/message_popup_menu.dart';
import 'package:commet/utils/event_bus.dart';
import 'package:flutter/material.dart';
import 'package:just_the_tooltip/just_the_tooltip.dart';
import 'dart:async';

import 'package:commet/client/components/emoticon/emoticon.dart';
import 'package:commet/utils/common_strings.dart';

import 'package:flutter/material.dart' as m;
import 'package:tiamat/atoms/context_menu.dart';
import 'package:tiamat/config/style/theme_extensions.dart';

import 'package:tiamat/tiamat.dart' as tiamat;

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

  static const interactableTypes = [
    EventType.message,
    EventType.emote,
    EventType.sticker
  ];

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
              if (interactableTypes.contains(widget.state.event.type))
                buildMenuEntry(m.Icons.reply, CommonStrings.promptReply,
                    callback: () {
                  widget.state.setReplyingEvent();
                }),
              if (interactableTypes.contains(widget.state.event.type))
                buildMenuEntry(
                    m.Icons.add_reaction, CommonStrings.promptAddReaction,
                    callback: toggleTooltipMenu),
              if (widget.state.isEditable)
                buildMenuEntry(m.Icons.edit, CommonStrings.promptEdit,
                    callback: () {
                  widget.state.setEditingEvent();
                }),
              if (widget.state.isDeletable)
                buildMenuEntry(m.Icons.delete, CommonStrings.promptDelete,
                    callback: () {
                  widget.state.deleteEvent();
                }),
              if (widget.state.canSaveAttachment)
                buildMenuEntry(m.Icons.download, CommonStrings.promptDownload,
                    callback: () {
                  widget.state.saveAttachment();
                }),
              buildMenuEntry(m.Icons.more_vert, CommonStrings.promptOptions,
                  items: [
                    ContextMenuItem(
                        text: "Show Source",
                        icon: Icons.code,
                        onPressed: () => widget.state.showSource(context)),
                    if (interactableTypes.contains(widget.state.event.type))
                      ContextMenuItem(
                          text: "Reply in Thread",
                          icon: Icons.message,
                          onPressed: () => EventBus.openThread.add((
                                widget.state.timeline.client.identifier,
                                widget.state.timeline.room.identifier,
                                widget.state.event.eventId
                              )))
                  ]),
            ],
          ),
        ),
      ),
    );
  }

  Widget buildMenuEntry(IconData icon, String label,
      {Function()? callback, List<ContextMenuItem>? items}) {
    const double size = 32;
    var pad = const EdgeInsets.all(2);
    return tiamat.Tooltip(
      text: label,
      child: m.Padding(
        padding: const EdgeInsets.fromLTRB(0, 0, 0, 0),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(size / 2),
          child: Material(
            color: Colors.transparent,
            child: m.SizedBox(
              width: size,
              height: size,
              child: items != null
                  ? ContextMenu(
                      modal: true,
                      items: items,
                      child: Padding(
                        padding: pad,
                        child: Icon(
                          icon,
                          size: size / 1.5,
                        ),
                      ),
                    )
                  : InkWell(
                      onTap: callback,
                      child: Padding(
                          padding: pad,
                          child: Icon(
                            icon,
                            size: size / 1.5,
                          )),
                    ),
            ),
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
