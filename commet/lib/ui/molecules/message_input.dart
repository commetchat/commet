import 'dart:async';

import 'package:commet/config/build_config.dart';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:tiamat/config/config.dart';
import 'package:tiamat/tiamat.dart';
import 'package:tiamat/tiamat.dart' as tiamat;
import '../../generated/l10n.dart';

enum MessageInputSendResult { clearText, unhandled }

class MessageInput extends StatefulWidget {
  const MessageInput(
      {super.key,
      this.maxHeight = 200,
      this.onSendMessage,
      this.isRoomE2EE = false,
      this.onFocusChanged,
      this.readIndicator,
      this.replyingToBody,
      this.replyingToColor,
      this.replyingToName,
      this.focusKeyboard,
      this.cancelReply});
  final double maxHeight;
  final double size = 48;
  final bool isRoomE2EE;
  final MessageInputSendResult Function(String message)? onSendMessage;
  final Widget? readIndicator;
  final String? replyingToBody;
  final String? replyingToName;
  final Color? replyingToColor;
  final Stream<void>? focusKeyboard;
  final void Function(bool focused)? onFocusChanged;
  final void Function()? cancelReply;

  @override
  State<MessageInput> createState() => MessageInputState();
}

class MessageInputState extends State<MessageInput> {
  late FocusNode textFocus;
  late TextEditingController controller;
  bool showHint = true;
  StreamSubscription? keyboardFocusSubscription;

  void unfocus() {
    textFocus.unfocus();
  }

  void onKeyboardFocusRequested() {
    textFocus.requestFocus();
  }

  @override
  void dispose() {
    keyboardFocusSubscription?.cancel();
    super.dispose();
  }

  @override
  void initState() {
    controller = TextEditingController();
    keyboardFocusSubscription =
        widget.focusKeyboard?.listen((_) => onKeyboardFocusRequested());

    controller.addListener(() {
      setState(() {
        showHint = controller.text.isEmpty;
      });
    });

    textFocus = FocusNode(
      onKey: (node, event) {
        if (BuildConfig.MOBILE) return KeyEventResult.ignored;

        if (event.isKeyPressed(LogicalKeyboardKey.enter)) {
          if (event.isShiftPressed) {
            return KeyEventResult.ignored;
          }

          sendMessage();
          return KeyEventResult.handled;
        }
        return KeyEventResult.ignored;
      },
    );

    super.initState();
  }

  void sendMessage() {
    if (controller.text.isEmpty) return;
    if (controller.text.trim().isEmpty) return;

    MessageInputSendResult? result =
        widget.onSendMessage?.call(controller.text.trim());
    if (result == MessageInputSendResult.clearText) {
      controller.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8.0, 8, 8, 4),
        child: Tile(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (widget.replyingToName != null) replyText(),
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
                          child: const tiamat.IconButton(
                            icon: Icons.add,
                            size: 24,
                          ),
                        ),
                      ),
                      Flexible(
                        child: Container(
                          decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(10),
                              color: Theme.of(context)
                                  .extension<ExtraColors>()!
                                  .surfaceLow2),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Padding(
                                  padding:
                                      const EdgeInsets.fromLTRB(8, 14, 4, 12),
                                  child: Stack(
                                    children: [
                                      TextField(
                                        controller: controller,
                                        focusNode: textFocus,
                                        decoration: null,
                                        maxLines: null,
                                        cursorColor: Theme.of(context)
                                            .colorScheme
                                            .onPrimary,
                                        cursorWidth: 1,
                                      ),
                                      if (showHint)
                                        IgnorePointer(
                                          ignoring: true,
                                          child: Padding(
                                            padding: const EdgeInsets.fromLTRB(
                                                2, 2, 0, 0),
                                            child: tiamat.Text(
                                                T
                                                    .of(context)
                                                    .sendAMessagePrompt,
                                                type: TextType.label,
                                                color: Theme.of(context)
                                                    .iconTheme
                                                    .color),
                                          ),
                                        )
                                    ],
                                  ),
                                ),
                              ),
                              if (widget.isRoomE2EE)
                                const SizedBox(
                                  width: 22,
                                  child: Padding(
                                    padding: EdgeInsets.fromLTRB(8, 17, 0, 0),
                                    child: Icon(
                                      Icons.lock_outline,
                                      size: 18,
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
                      Padding(
                        padding: const EdgeInsets.fromLTRB(8, 0, 0, 0),
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
    );
  }

  Widget replyText() {
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
                onPressed: widget.cancelReply,
              ),
            ),
            const Icon(Icons.keyboard_arrow_right_rounded),
            tiamat.Text.name(
              widget.replyingToName!,
              color: widget.replyingToColor,
            ),
            Flexible(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(4, 0, 4, 0),
                child: tiamat.Text(
                  widget.replyingToBody ?? "Unknown",
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
}
