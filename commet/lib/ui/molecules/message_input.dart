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
      this.onFocusChanged});
  final double maxHeight;
  final double size = 48;
  final MessageInputSendResult Function(String message)? onSendMessage;
  final void Function(bool focused)? onFocusChanged;

  @override
  State<MessageInput> createState() => MessageInputState();
}

class MessageInputState extends State<MessageInput> {
  late FocusNode textFocus;
  late TextEditingController controller;
  bool showHint = true;

  void unfocus() {
    textFocus.unfocus();
  }

  @override
  void initState() {
    controller = TextEditingController();

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
        padding: const EdgeInsets.all(8.0),
        child: Tile(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
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
                                      RawKeyboardListener(
                                        focusNode: textFocus,
                                        child: TextField(
                                          controller: controller,
                                          decoration: null,
                                          maxLines: null,
                                          cursorColor: Theme.of(context)
                                              .colorScheme
                                              .onPrimary,
                                          cursorWidth: 1,
                                        ),
                                      ),
                                      if (showHint)
                                        IgnorePointer(
                                          ignoring: true,
                                          child: Padding(
                                            padding: const EdgeInsets.fromLTRB(
                                                0, 2, 0, 0),
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
              const SizedBox(
                height: 20,
              )
            ],
          ),
        ),
      ),
    );
  }
}
