import 'package:commet/utils/emoji/emoji.dart';
import 'package:flutter/widgets.dart';

// ignore: must_be_immutable
class EmojiWidget extends StatelessWidget {
  final Emoji emoji;
  double? height;

  EmojiWidget(this.emoji, {super.key, this.height = 24});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(2, 0, 2, 0),
      child: Image(
        filterQuality: FilterQuality.medium,
        isAntiAlias: true,
        width: height,
        height: height,
        image: emoji.image,
      ),
    );
  }
}
