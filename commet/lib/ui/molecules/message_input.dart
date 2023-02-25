import 'package:flutter/material.dart';
import 'package:flutter/src/widgets/framework.dart';
import 'package:flutter/src/widgets/placeholder.dart';

import '../../config/style/theme_extensions.dart';

class MessageInput extends StatelessWidget {
  const MessageInput({super.key, this.maxHeight = 200});
  final double maxHeight;

  @override
  Widget build(BuildContext context) {
    return Material(
        color: Theme.of(context).colorScheme.surface,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Container(
                decoration: BoxDecoration(
                    boxShadow: [BoxShadow(color: Colors.black.withAlpha(50), blurRadius: 20)],
                    color: Theme.of(context).extension<ExtraColors>()!.surfaceHigh1,
                    borderRadius: BorderRadius.all(Radius.circular(5))),
                child: Padding(
                  padding: const EdgeInsets.all(0.0),
                  child: Row(
                    children: [
                      Flexible(
                        child: ConstrainedBox(
                            constraints: BoxConstraints.loose(Size.fromHeight(maxHeight)),
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
                              child: const TextField(
                                decoration: null,
                                maxLines: null,
                                cursorColor: Colors.white,
                                cursorWidth: 1,
                              ),
                            )),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Icon(Icons.emoji_emotions),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Icon(Icons.send),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ));
  }
}
