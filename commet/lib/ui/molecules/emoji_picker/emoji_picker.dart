import 'package:flutter/material.dart';
import 'package:tiamat/tiamat.dart';
import 'package:commet/utils/emoji/emoji_pack.dart';
import 'package:commet/ui/atoms/emoji_widget.dart';

import 'package:widgetbook_annotation/widgetbook_annotation.dart';

@WidgetbookUseCase(name: 'Emoji Picker', type: EmojiPickerWidget)
@Deprecated("widgetbook")
Widget emojiPickerWidget(BuildContext context) {
  return SizedBox(
      width: 100,
      height: 100,
      child: FutureBuilder(
          future: EmojiPack.defaults(),
          builder: (BuildContext context, AsyncSnapshot<dynamic> snapshot) =>
              snapshot.hasData
                  ? EmojiPickerWidget(snapshot.data as List<EmojiPack>)
                  : const Center(
                      child: CircularProgressIndicator(),
                    )));
}

class EmojiPickerWidget extends StatelessWidget {
  const EmojiPickerWidget(this.packs, {super.key});

  final List<EmojiPack> packs;

  @override
  Widget build(BuildContext context) {
    return Panel(
        child: SizedBox(
            width: 90,
            height: 84,
            child: ListView.builder(
              itemCount: packs.length,
              itemBuilder: (BuildContext context, int packIndex) {
                return GridView.count(
                  crossAxisCount: 8,
                  shrinkWrap: true,
                  children: packs[packIndex]
                      .emoji
                      .map((e) => EmojiWidget(e))
                      .toList(),
                );
              },
            )));
  }
}
