import 'package:commet/client/components/emoticon/emoticon.dart';
import 'package:flutter/material.dart';
import 'package:tiamat/tiamat.dart' as tiamat;

// ignore: must_be_immutable
class EmojiWidget extends StatelessWidget {
  final Emoticon emoji;
  double height;
  EdgeInsetsGeometry padding;

  EmojiWidget(this.emoji,
      {super.key,
      this.height = 24,
      this.padding = const EdgeInsetsGeometry.all(0)});

  @override
  Widget build(BuildContext context) {
    return Padding(
        padding: const EdgeInsets.fromLTRB(2, 0, 2, 0),
        child: emoji.image != null
            ? SizedBox(
                width: height,
                height: height,
                child: FadeInImage(
                  placeholder: tiamat.transparentImage.image,
                  fadeInDuration: Durations.medium1,
                  filterQuality: FilterQuality.medium,
                  fit: BoxFit.contain,
                  width: height,
                  height: height,
                  image: emoji.image!,
                ),
              )
            : SizedBox(
                height: height,
                child: FittedBox(
                  fit: BoxFit.cover,
                  child: Padding(
                    padding: padding,
                    child: Text(
                      emoji.slug,
                    ),
                  ),
                ),
              ));
  }
}
