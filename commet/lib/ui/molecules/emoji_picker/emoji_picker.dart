import 'package:flutter/material.dart';
import 'package:tiamat/tiamat.dart';
import 'package:tiamat/tiamat.dart' as tiamat;
import 'package:commet/utils/emoji/emoji_pack.dart';
import 'package:commet/ui/atoms/emoji_widget.dart';

import 'package:widgetbook_annotation/widgetbook_annotation.dart';

@WidgetbookUseCase(name: 'Emoji Picker', type: EmojiPicker)
@Deprecated("widgetbook")
Widget wbEmojiPickerDefault(BuildContext context) {
  return SizedBox(
      width: 350,
      height: 350,
      child: FutureBuilder(
          future: EmojiPack.defaults(),
          builder: (BuildContext context, AsyncSnapshot<dynamic> snapshot) =>
              snapshot.hasData
                  ? EmojiPicker(snapshot.data as List<EmojiPack>)
                  : const Center(
                      child: CircularProgressIndicator(),
                    )));
}

class EmojiPicker extends StatelessWidget {
  const EmojiPicker(this.packs, {super.key});

  final List<EmojiPack> packs;

  @override
  Widget build(BuildContext context) {
    return Tile.low1(
        child: Material(
            child: SizedBox(
                child: ListView.builder(
      itemCount: packs.length,
      itemBuilder: (BuildContext context, int packIndex) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            tiamat.Text.labelLow(packs[packIndex].name),
            Wrap(
              spacing: 5,
              runSpacing: 10,
              children: packs[packIndex]
                  .emoji
                  .map((e) => InkWell(
                      onTap: () {},
                      onHover: (value) {},
                      mouseCursor: SystemMouseCursors.click,
                      child: Padding(
                          padding: const EdgeInsets.all(5.0),
                          child: EmojiWidget(e))))
                  .toList(),
            )
          ],
        );
      },
    ))));
  }
}
