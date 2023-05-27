import 'dart:async';

import 'package:commet/config/build_config.dart';
import 'package:commet/ui/molecules/attachment_icon.dart';
import 'package:commet/ui/pages/chat/chat_page.dart';
import 'package:file_picker/file_picker.dart';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:tiamat/config/config.dart';
import 'package:tiamat/tiamat.dart';
import 'package:tiamat/tiamat.dart' as tiamat;
import '../../client/attachment.dart';
import '../../generated/l10n.dart';

enum MessageInputSendResult { success, unhandled }

class MessageInput extends StatefulWidget {
  const MessageInput(
      {super.key,
      this.maxHeight = 200,
      this.onSendMessage,
      this.isRoomE2EE = false,
      this.onFocusChanged,
      this.readIndicator,
      this.relatedEventBody,
      this.relatedEventSenderColor,
      this.relatedEventSenderName,
      this.interactionType,
      this.focusKeyboard,
      this.setInputText,
      this.isProcessing = false,
      this.editLastMessage,
      this.attachments,
      this.addAttachment,
      this.removeAttachment,
      this.cancelReply});
  final double maxHeight;
  final double size = 48;
  final bool isRoomE2EE;
  final MessageInputSendResult Function(String message)? onSendMessage;
  final Widget? readIndicator;
  final String? relatedEventBody;
  final String? relatedEventSenderName;
  final Color? relatedEventSenderColor;
  final List<PendingFileAttachment>? attachments;
  final EventInteractionType? interactionType;
  final Stream<void>? focusKeyboard;
  final Stream<String>? setInputText;
  final bool isProcessing;
  final void Function(bool focused)? onFocusChanged;
  final void Function()? cancelReply;
  final void Function()? editLastMessage;
  final void Function(PendingFileAttachment attachment)? addAttachment;
  final void Function(PendingFileAttachment attachment)? removeAttachment;

  @override
  State<MessageInput> createState() => MessageInputState();
}

class MessageInputState extends State<MessageInput> {
  late FocusNode textFocus;
  late TextEditingController controller;
  bool showHint = true;
  StreamSubscription? keyboardFocusSubscription;
  StreamSubscription? setInputTextSubscription;
  void unfocus() {
    textFocus.unfocus();
  }

  void onKeyboardFocusRequested() {
    textFocus.requestFocus();
  }

  void onSetInputText(String newText) {
    controller.text = newText;
    controller.selection =
        TextSelection(baseOffset: newText.length, extentOffset: newText.length);
  }

  @override
  void dispose() {
    keyboardFocusSubscription?.cancel();
    setInputTextSubscription?.cancel();
    super.dispose();
  }

  @override
  void initState() {
    controller = TextEditingController();
    keyboardFocusSubscription =
        widget.focusKeyboard?.listen((_) => onKeyboardFocusRequested());

    setInputTextSubscription = widget.setInputText?.listen(onSetInputText);

    controller.addListener(() {
      setState(() {
        showHint = controller.text.isEmpty;
      });
    });

    textFocus = FocusNode(onKey: onKey);

    super.initState();
  }

  void sendMessage() {
    if (widget.attachments == null || widget.attachments!.isEmpty) {
      if (controller.text.isEmpty) return;
      if (controller.text.trim().isEmpty) return;
    }

    widget.onSendMessage?.call(controller.text.trim());
  }

  KeyEventResult onKey(FocusNode node, RawKeyEvent event) {
    if (BuildConfig.MOBILE) return KeyEventResult.ignored;

    if (event.isKeyPressed(LogicalKeyboardKey.enter)) {
      if (event.isShiftPressed) {
        return KeyEventResult.ignored;
      }

      sendMessage();
      return KeyEventResult.handled;
    }

    if (event.isKeyPressed(LogicalKeyboardKey.escape)) {
      doCancelInteraction();
      return KeyEventResult.handled;
    }

    if (event.isKeyPressed(LogicalKeyboardKey.arrowUp) &&
        controller.text.isEmpty) {
      widget.editLastMessage?.call();
    }

    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Opacity(
        opacity: widget.isProcessing ? 0.5 : 1,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8.0, 8, 8, 4),
          child: Tile(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (widget.interactionType != null) interactionText(),
                if (widget.attachments != null &&
                    widget.attachments!.isNotEmpty)
                  displayAttachments(),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 200),
                  child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.max,
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(0, 0, 4, 0),
                          child: SizedBox(
                            width: widget.size,
                            height: widget.size,
                            child: tiamat.IconButton(
                              icon: Icons.add,
                              size: 24,
                              onPressed: addAttachment,
                            ),
                          ),
                        ),
                        Flexible(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: Container(
                              decoration: BoxDecoration(
                                  color: Theme.of(context)
                                      .extension<ExtraColors>()!
                                      .surfaceLow2),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: Padding(
                                      padding:
                                          const EdgeInsets.fromLTRB(0, 2, 4, 2),
                                      child: Stack(
                                        children: [
                                          TextField(
                                            controller: controller,
                                            focusNode: textFocus,
                                            contextMenuBuilder:
                                                contextMenuBuilder,
                                            enabled:
                                                widget.isProcessing != true,
                                            style: Theme.of(context)
                                                .textTheme
                                                .bodyMedium,
                                            decoration: InputDecoration(
                                              prefix: const SizedBox(
                                                width: 8,
                                                height: 10,
                                              ),
                                              hintText: widget.isRoomE2EE
                                                  ? T.current
                                                      .sendEncryptedMessagePrompt
                                                  : T.current
                                                      .sendAMessagePrompt,
                                            ),
                                            //decoration: null,
                                            maxLines: null,
                                            cursorColor: Theme.of(context)
                                                .colorScheme
                                                .onPrimary,
                                            cursorWidth: 1,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.all(2.0),
                                    child: SizedBox(
                                        width: widget.size,
                                        height: widget.size,
                                        child: const tiamat.IconButton(
                                          icon: Icons.face,
                                          size: 24,
                                        )),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(4, 0, 0, 0),
                          child: SizedBox(
                              width: widget.size,
                              height: widget.size,
                              child: tiamat.IconButton(
                                icon: Icons.send,
                                onPressed: sendMessage,
                                size: 24,
                              )),
                        )
                      ]),
                ),
                SizedBox(
                  height: 25,
                  child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Expanded(
                          child: SizedBox(),
                        ),
                        if (widget.readIndicator != null)
                          Padding(
                            padding: const EdgeInsets.fromLTRB(8, 0, 0, 0),
                            child: SizedBox(
                              width: 150,
                              child: widget.readIndicator!,
                            ),
                          )
                      ]),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }

  void addAttachment() async {
    FilePickerResult? result = await FilePicker.platform
        .pickFiles(type: FileType.image, withData: true);

    if (result != null) {
      for (var file in result.files) {
        var attachment = PendingFileAttachment(
            name: file.name, path: file.path, data: file.bytes);
        widget.addAttachment?.call(attachment);
      }
    }
  }

  void doCancelInteraction() {
    if (widget.interactionType == EventInteractionType.edit) {
      controller.clear();
    }

    widget.cancelReply?.call();
  }

  Widget interactionText() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 0, 0, 4),
      child: SizedBox(
        height: 24,
        child: Row(
          children: [
            SizedBox(
              width: 24,
              height: 24,
              child: tiamat.IconButton(
                icon: Icons.cancel_outlined,
                size: 16,
                onPressed: doCancelInteraction,
              ),
            ),
            Icon(widget.interactionType == EventInteractionType.reply
                ? Icons.keyboard_arrow_right_rounded
                : widget.interactionType == EventInteractionType.edit
                    ? Icons.edit
                    : null),
            tiamat.Text.name(
              widget.relatedEventSenderName!,
              color: widget.relatedEventSenderColor,
            ),
            Flexible(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(4, 0, 4, 0),
                child: tiamat.Text(
                  widget.relatedEventBody ?? "Unknown",
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  color: Theme.of(context).colorScheme.secondary,
                ),
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget displayAttachments() {
    return SizedBox(
      child: Row(
        children: widget.attachments!.map((e) {
          return Padding(
            padding: const EdgeInsets.all(2.0),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(5),
              child: GestureDetector(
                onTap: () {},
                child: SizedBox(
                  height: 40,
                  width: 40,
                  child: AttachmentIcon(
                    e,
                    removeAttachment: () => widget.removeAttachment?.call(e),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget contextMenuBuilder(
      BuildContext context, EditableTextState editableTextState) {
    return AdaptiveTextSelectionToolbar.editable(
      anchors: editableTextState.contextMenuAnchors,
      clipboardStatus: ClipboardStatus.pasteable,
      // to apply the normal behavior when click on copy (copy in clipboard close toolbar)
      // use an empty function `() {}` to hide this option from the toolbar
      onCopy: () =>
          editableTextState.copySelection(SelectionChangedCause.toolbar),
      // to apply the normal behavior when click on cut
      onCut: () =>
          editableTextState.cutSelection(SelectionChangedCause.toolbar),
      onPaste: () {
        // HERE will be called when the paste button is clicked in the toolbar
        // apply your own logic here

        // to apply the normal behavior when click on paste (add in input and close toolbar)
        editableTextState.pasteText(SelectionChangedCause.toolbar);
      },
      // to apply the normal behavior when click on select all
      onSelectAll: () =>
          editableTextState.selectAll(SelectionChangedCause.toolbar),
    );
  }
}
