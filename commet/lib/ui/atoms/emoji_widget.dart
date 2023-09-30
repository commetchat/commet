import 'package:commet/client/components/emoticon/emoticon.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

// ignore: must_be_immutable
class EmojiWidget extends StatelessWidget {
  final Emoticon emoji;
  double height;

  EmojiWidget(this.emoji, {super.key, this.height = 24});

  @override
  Widget build(BuildContext context) {
    return Padding(
        padding: const EdgeInsets.fromLTRB(2, 0, 2, 0),
        child: emoji.image != null
            ? SizedBox(
                width: height,
                height: height,
                child: Image(
                  filterQuality: FilterQuality.medium,
                  isAntiAlias: true,
                  width: height,
                  height: height,
                  image: emoji.image!,
                ),
              )
            : SizedBox(
                height: height,
                child: FittedBox(
                  fit: BoxFit.cover,
                  child: Text(
                    emoji.slug,
                  ),
                ),
              ));
  }
}
