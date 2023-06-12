import 'package:commet/utils/emoji/emoticon.dart';
import 'package:commet/utils/emoji/unicode_emoji.dart';
import 'package:flutter/material.dart';
import 'package:tiamat/atoms/image_button.dart';
import 'package:tiamat/config/style/theme_extensions.dart';
import 'package:tiamat/tiamat.dart' as tiamat;
import 'package:commet/utils/emoji/emoji_pack.dart';
import 'package:commet/ui/atoms/emoji_widget.dart';
import '../atoms/tooltip.dart' as t;

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
      {super.key,
      this.size = 38,
      this.onEmoticonPressed,
      this.packButtonSize = 32});
  final void Function(Emoticon emoticon)? onEmoticonPressed;
  final List<EmoticonPack> packs;
  final double size;
  final double packButtonSize;

  @override
  Widget build(BuildContext context) {
    return Material(
        color: Colors.transparent, child: buildWithVerticalList(context));
  }

  Row buildWithVerticalList(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.max,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        tiamat.Tile.low3(
          child: Padding(
            padding: const EdgeInsets.all(4.0),
            child: SizedBox(
              width: packButtonSize,
              child: ScrollConfiguration(
                behavior:
                    ScrollConfiguration.of(context).copyWith(scrollbars: false),
                child: ListView.builder(
                  itemCount: packs.length,
                  itemBuilder: (context, index) {
                    return buildPackButton(index);
                  },
                ),
              ),
            ),
          ),
        ),
        Container(child: buildEmojiList()),
      ],
    );
  }

  Padding buildPackButton(int index) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 4, 0, 4),
      child: SizedBox(
        height: packButtonSize,
        width: packButtonSize,
        child: t.Tooltip(
          text: packs[index].displayName,
          preferredDirection: AxisDirection.right,
          child: ImageButton(
            size: packButtonSize,
            iconSize: packButtonSize - 8,
            icon: packs[index].icon,
            image: packs[index].image,
          ),
        ),
      ),
    );
  }

  Expanded buildEmojiList() {
    return Expanded(
      child: ListView.builder(
        itemCount: packs.length,
        itemBuilder: (BuildContext context, int packIndex) {
          return buildListItem(packIndex);
        },
      ),
    );
  }

  Widget buildListItem(int packIndex) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 5, 4, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(0, 4, 0, 0),
            child: tiamat.Text.labelLow(packs[packIndex].displayName),
          ),
          Wrap(
            alignment: WrapAlignment.start,
            runSpacing: 1,
            spacing: 1,
            children:
                packs[packIndex].emotes.map((e) => buildEmoticon(e)).toList(),
          )
        ],
      ),
    );
  }

  Widget buildEmoticon(Emoticon emoticon) {
    return SizedBox(
        width: size,
        height: size,
        child: InkWell(
            borderRadius: BorderRadius.circular(3),
            onTap: () => onEmoticonPressed?.call(emoticon),
            mouseCursor: SystemMouseCursors.click,
            child: Padding(
                padding: const EdgeInsets.all(2.0),
                child: Center(
                    child: EmojiWidget(
                  emoticon,
                  height: size,
                )))));
  }
}
