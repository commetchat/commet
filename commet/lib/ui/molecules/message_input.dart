import 'package:commet/config/app_config.dart';
import 'package:commet/ui/atoms/background.dart';
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
        child: Column(
      children: [
        Padding(
          padding: EdgeInsets.all(s(8.0)),
          child: Background.surface(
            context,
            decoration: BoxDecoration(
                boxShadow: [BoxShadow(color: Colors.black.withAlpha(50), blurRadius: 20)],
                color: Theme.of(context).extension<ExtraColors>()!.surfaceHigh1,
                borderRadius: BorderRadius.all(Radius.circular(s(5)))),
            child: Padding(
              padding: const EdgeInsets.all(0.0),
              child: Row(
                children: [
                  Flexible(
                    child: ConstrainedBox(
                        constraints: BoxConstraints.loose(Size.fromHeight(maxHeight)),
                        child: Padding(
                          padding: EdgeInsets.fromLTRB(s(8), s(8), s(8), s(8)),
                          child: const TextField(
                            decoration: null,
                            maxLines: null,
                            cursorColor: Colors.white,
                            cursorWidth: 1,
                          ),
                        )),
                  ),
                  Padding(
                    padding: EdgeInsets.all(s(8.0)),
                    child: Icon(Icons.emoji_emotions),
                  ),
                  Padding(
                    padding: EdgeInsets.all(s(8.0)),
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
