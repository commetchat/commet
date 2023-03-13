import 'package:commet/config/app_config.dart';
import 'package:commet/config/build_config.dart';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:tiamat/config/config.dart';
import 'package:tiamat/tiamat.dart';

import '../atoms/icon_button.dart' as i;

enum MessageInputSendResult { clearText, unhandled }

class MessageInput extends StatefulWidget {
  const MessageInput({super.key, this.maxHeight = 200, this.onSendMessage});
  final double maxHeight;
  final MessageInputSendResult Function(String message)? onSendMessage;

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

          if (controller.text.isEmpty) {
            return KeyEventResult.handled;
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
    MessageInputSendResult? result = widget.onSendMessage?.call(controller.text);
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
              boxShadow: [BoxShadow(color: Colors.black.withAlpha(50), blurRadius: 20)],
              color: Theme.of(context).extension<ExtraColors>()!.surfaceHigh1,
              borderRadius: BorderRadius.circular(s(5))),
          child: Padding(
            padding: const EdgeInsets.all(0.0),
            child: Row(
              children: [
                Flexible(
                  child: ConstrainedBox(
                      constraints: BoxConstraints.loose(Size.fromHeight(widget.maxHeight)),
                      child: Padding(
                        padding: EdgeInsets.fromLTRB(s(8), s(9), s(8), s(9)),
                        child: Material(
                          color: Colors.transparent,
                          child: Row(
                            children: [
                              Expanded(
                                child: RawKeyboardListener(
                                  focusNode: textFocus,
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
                              ),
                              Row(children: [
                                i.IconButton(size: s(24), icon: Icons.face),
                                Padding(
                                  padding: EdgeInsets.fromLTRB(s(10), 0, 0, 0),
                                  child:
                                      i.IconButton(onPressed: () => sendMessage.call(), size: s(24), icon: Icons.send),
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
