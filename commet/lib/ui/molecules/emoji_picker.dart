import 'package:commet/utils/emoji/emoticon.dart';
import 'package:commet/utils/emoji/unicode_emoji.dart';
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
          future: UnicodeEmojis.load(),
          builder: (BuildContext context, AsyncSnapshot<dynamic> snapshot) =>
              snapshot.hasData
                  ? EmojiPicker(
                      snapshot.data as List<EmoticonPack>,
                      onEmoticonPressed: (emoticon) {
                        // ignore: avoid_print
                        print("Emoticon Clicked: ${emoticon.slug}");
                      },
                    )
                  : const Center(
                      child: CircularProgressIndicator(),
                    )));
}

class EmojiPicker extends StatelessWidget {
  const EmojiPicker(this.packs,
      {super.key, this.size = 38, this.onEmoticonPressed});
  final void Function(Emoticon emoticon)? onEmoticonPressed;
  final List<EmoticonPack> packs;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Tile.low1(
        child: Material(
            child: SizedBox(
                child: ListView.builder(
      itemCount: packs.length,
      itemBuilder: (BuildContext context, int packIndex) {
        return buildListItem(packIndex);
      },
    ))));
  }

  Column buildListItem(int packIndex) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        tiamat.Text.labelLow(packs[packIndex].displayName),
        Wrap(
          alignment: WrapAlignment.start,
          runSpacing: 1,
          spacing: 1,
          children:
              packs[packIndex].emotes.map((e) => buildEmoticon(e)).toList(),
        )
      ],
    );
  }

  Widget buildEmoticon(Emoticon emoticon) {
    return SizedBox(
        width: size,
        height: size,
        child: InkWell(
            borderRadius: BorderRadius.circular(10),
            onTap: () => onEmoticonPressed?.call(emoticon),
            mouseCursor: SystemMouseCursors.click,
            child: Padding(
                padding: const EdgeInsets.all(5.0),
                child: Center(child: EmojiWidget(emoticon)))));
  }
}
