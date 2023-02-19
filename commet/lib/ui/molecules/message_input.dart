import 'package:flutter/material.dart';
import 'package:flutter/src/widgets/framework.dart';
import 'package:flutter/src/widgets/placeholder.dart';

class MessageInput extends StatelessWidget {
  const MessageInput({super.key});

  @override
  Widget build(BuildContext context) {
    return Material(
        child: Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Container(
            decoration:
                BoxDecoration(color: Colors.black.withAlpha(30), borderRadius: BorderRadius.all(Radius.circular(10))),
            child: Padding(
              padding: const EdgeInsets.all(0.0),
              child: Row(
                children: [
                  Flexible(
                      child: Padding(
                    padding: const EdgeInsets.fromLTRB(8, 0, 8, 0),
                    child: const TextField(),
                  )),
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
