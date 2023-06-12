import 'package:commet/utils/emoji/emoticon.dart';
import 'package:commet/utils/emoji/unicode_emoji.dart';
import 'package:flutter/material.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
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
  EmojiPicker(this.packs,
      {super.key,
      this.size = 38,
      this.onEmoticonPressed,
      this.packButtonSize = 32,
      this.packListAxis = Axis.vertical});
  final void Function(Emoticon emoticon)? onEmoticonPressed;
  final List<EmoticonPack> packs;
  final double size;
  final Axis packListAxis;
  final double packButtonSize;

  final ItemScrollController itemScrollController = ItemScrollController();

  @override
  Widget build(BuildContext context) {
    return Material(
        color: Colors.transparent,
        child: packListAxis == Axis.vertical
            ? buildWithVerticalList(context)
            : buildWithHorizontalList(context));
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
                    return Padding(
                      padding: const EdgeInsets.fromLTRB(0, 2, 0, 2),
                      child: buildPackButton(
                          index,
                          () => itemScrollController.scrollTo(
                              index: index,
                              curve: Curves.easeOutExpo,
                              duration: Duration(milliseconds: 200))),
                    );
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

  Widget buildWithHorizontalList(BuildContext context) {
    return Column(
      children: [
        tiamat.Tile.low3(
          child: Padding(
            padding: const EdgeInsets.all(4.0),
            child: ConstrainedBox(
              constraints: BoxConstraints(maxHeight: packButtonSize),
              child: ScrollConfiguration(
                behavior:
                    ScrollConfiguration.of(context).copyWith(scrollbars: false),
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: packs.length,
                  itemBuilder: (context, index) {
                    return Padding(
                      padding: const EdgeInsets.fromLTRB(2, 0, 2, 0),
                      child: buildPackButton(
                          index,
                          () => itemScrollController.scrollTo(
                              index: index,
                              curve: Curves.easeOutExpo,
                              duration: Duration(milliseconds: 200))),
                    );
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

  Widget buildPackButton(int index, void Function()? onTap) {
    return SizedBox(
      child: t.Tooltip(
        text: packs[index].displayName,
        preferredDirection: AxisDirection.right,
        child: ImageButton(
          size: packButtonSize,
          iconSize: packButtonSize - 8,
          icon: packs[index].icon,
          image: packs[index].image,
          onTap: onTap,
        ),
      ),
    );
  }

  Expanded buildEmojiList() {
    return Expanded(
      child: ScrollablePositionedList.builder(
        itemScrollController: itemScrollController,
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
