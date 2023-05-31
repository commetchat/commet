import 'package:flutter/material.dart';
import 'package:tiamat/tiamat.dart';
import 'package:commet/utils/emoji/emoji_pack.dart';

// Future<void> emojiPacks() {
//   var packs = EmojiPack.defaults();
//   return EmojiPickerWidget(packs);
// }

class EmojiPickerWidget extends StatelessWidget {
  var emojiPacks = EmojiPack.defaults()

  @override
  Widget build(BuildContext context) {
    return Panel(
        child: ListView.builder(
          itemCount: emojiPacks.length,
    ));
  }
}
