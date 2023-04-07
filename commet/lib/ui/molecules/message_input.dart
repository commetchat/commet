import 'package:commet/config/app_config.dart';
import 'package:commet/config/build_config.dart';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:tiamat/config/config.dart';
import 'package:tiamat/tiamat.dart';
import 'package:tiamat/tiamat.dart' as tiamat;
import '../../generated/l10n.dart';
import '../atoms/icon_button.dart' as i;

enum MessageInputSendResult { clearText, unhandled }

class MessageInput extends StatefulWidget {
  const MessageInput({super.key, this.maxHeight = 200, this.onSendMessage, this.onFocusChanged});
  final double maxHeight;
  final MessageInputSendResult Function(String message)? onSendMessage;
  final void Function(bool focused)? onFocusChanged;

  @override
  State<MessageInput> createState() => MessageInputState();
}

class MessageInputState extends State<MessageInput> {
  late FocusNode textFocus;
  late TextEditingController controller;

  void unfocus() {
    textFocus.unfocus();
  }

  @override
  void initState() {
    controller = TextEditingController();

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

    MessageInputSendResult? result = widget.onSendMessage?.call(controller.text.trim());
    if (result == MessageInputSendResult.clearText) {
      controller.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Tile(
      child: Padding(
        padding: EdgeInsets.all(s(8.0)),
        child: Tile(
          decoration: BoxDecoration(
              //boxShadow: [BoxShadow(color: Colors.black.withAlpha(50), blurRadius: 20)],
              color: Theme.of(context).extension<ExtraColors>()!.surfaceLow2,
              borderRadius: BorderRadius.circular(8)),
          child: Padding(
            padding: const EdgeInsets.all(0.0),
            child: Row(
              children: [
                Flexible(
                  child: ConstrainedBox(
                      constraints: BoxConstraints.loose(Size.fromHeight(widget.maxHeight)),
                      child: Padding(
                        padding: EdgeInsets.fromLTRB(8, 9, 8, 9),
                        child: Material(
                          color: Colors.transparent,
                          child: Row(
                            children: [
                              Expanded(
                                child: RawKeyboardListener(
                                  focusNode: textFocus,
                                  child: Stack(
                                    children: [
                                      Focus(
                                        onFocusChange: (value) {
                                          widget.onFocusChanged?.call(value);
                                        },
                                        child: TextField(
                                          controller: controller,
                                          decoration: null,
                                          maxLines: null,
                                          cursorColor: Theme.of(context).colorScheme.onPrimary,
                                          cursorWidth: 1,
                                          onChanged: (value) {
                                            setState(() {});
                                          },
                                        ),
                                      ),
                                      if (controller.text.isEmpty)
                                        IgnorePointer(
                                          ignoring: true,
                                          child: Padding(
                                            padding: const EdgeInsets.all(2.0),
                                            child: tiamat.Text(T.of(context).sendAMessagePrompt,
                                                type: TextType.label, color: Theme.of(context).iconTheme.color),
                                          ),
                                        )
                                    ],
                                  ),
                                ),
                              ),
                              Row(children: [
                                const i.IconButton(size: 24, icon: Icons.face),
                                Padding(
                                  padding: const EdgeInsets.fromLTRB(10, 0, 0, 0),
                                  child: i.IconButton(onPressed: sendMessage, size: 24, icon: Icons.send),
                                ),
                              ])
                            ],
                          ),
                        ),
                      )),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
