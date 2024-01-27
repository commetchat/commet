import 'dart:async';

import 'package:commet/client/components/emoticon/emoticon.dart';
import 'package:commet/client/components/emoticon/emoticon_component.dart';
import 'package:commet/client/timeline.dart';
import 'package:commet/ui/atoms/code_block.dart';
import 'package:commet/ui/molecules/message_popup_menu/message_popup_menu_view_overlay.dart';
import 'package:commet/ui/molecules/message_popup_menu/message_popup_menu_view_dialog.dart';
import 'package:commet/ui/navigation/adaptive_dialog.dart';
import 'package:flutter/material.dart';
import '../../../client/client.dart';
import 'package:flutter/services.dart' as services;

class MessagePopupMenu extends StatefulWidget {
  final TimelineEvent event;
  final Timeline timeline;
  final bool isEditable;
  final bool isDeletable;
  final Stream<int>? onMessageChanged;
  final bool asDialog;
  const MessagePopupMenu(this.event, this.timeline,
      {super.key,
      this.setEditingEvent,
      this.onMessageChanged,
      this.setReplyingEvent,
      this.isDeletable = false,
      this.addReaction,
      this.onPopupStateChanged,
      this.asDialog = false,
      this.isEditable = false});

  final Function(TimelineEvent? event)? setReplyingEvent;
  final Function(TimelineEvent? event)? setEditingEvent;
  final Function(TimelineEvent event, Emoticon emoticon)? addReaction;
  final Function(bool state)? onPopupStateChanged;

  @override
  State<MessagePopupMenu> createState() => MessagePopupMenuState();
}

class MessagePopupMenuState extends State<MessagePopupMenu> {
  bool get isEditable => widget.isEditable;
  bool get isDeletable => widget.isDeletable;
  Timeline get timeline => widget.timeline;
  TimelineEvent get event => widget.event;
  Stream<int>? get onMessageChanged => widget.onMessageChanged;
  RoomEmoticonComponent? emoticons;
  @override
  void initState() {
    emoticons = widget.timeline.room.getComponent<RoomEmoticonComponent>();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.asDialog) return MessagePopupMenuViewDialog(this);

    return MessagePopupMenuViewOverlay(this);
  }

  void deleteEvent() {
    AdaptiveDialog.confirmation(context).then((value) {
      if (value == true) {
        widget.timeline.deleteEvent(event);
      }
    });
  }

  void setReplyingEvent() {
    widget.setReplyingEvent?.call(event);
  }

  void setEditingEvent() {
    widget.setEditingEvent?.call(event);
  }

  void addReaction(Emoticon emoticon) {
    widget.addReaction?.call(event, emoticon);
  }

  void onPopupStateChanged(bool state) {
    widget.onPopupStateChanged?.call(state);
  }

  void copyToClipboard() {
    services.Clipboard.setData(services.ClipboardData(text: event.body!));
  }

  void showSource(BuildContext context) {
    AdaptiveDialog.show(
      context,
      title: "Source",
      builder: (context) {
        return SelectionArea(
          child: Codeblock(text: event.rawContent, language: "json"),
        );
      },
    );
  }
}
