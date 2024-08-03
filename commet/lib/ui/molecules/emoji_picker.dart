import 'package:commet/client/components/emoticon/emoticon.dart';
import 'package:commet/config/build_config.dart';
import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import 'package:tiamat/atoms/image_button.dart';
import 'package:tiamat/tiamat.dart' as tiamat;
import 'package:commet/client/components/emoticon/emoji_pack.dart';
import 'package:commet/ui/atoms/emoji_widget.dart';

class EmojiPicker extends StatelessWidget {
  EmojiPicker(this.packs,
      {super.key,
      this.size = BuildConfig.MOBILE ? 48 : 42,
      this.onEmoticonPressed,
      this.packButtonSize = BuildConfig.MOBILE ? 48 : 42,
      this.onlyEmoji = false,
      this.onlyStickers = false,
      this.staggered = false,
      this.preferredTooltipDirection = AxisDirection.right,
      this.packListAxis = Axis.vertical});
  final void Function(Emoticon emoticon)? onEmoticonPressed;
  final List<EmoticonPack> packs;
  final double size;
  final Axis packListAxis;
  final double packButtonSize;
  final bool staggered;
  final bool onlyStickers;
  final bool onlyEmoji;
  final AxisDirection preferredTooltipDirection;

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
        tiamat.Tile.low(
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
                              duration: const Duration(milliseconds: 200))),
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
        tiamat.Tile.low(
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
                              duration: const Duration(milliseconds: 200))),
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
      child: tiamat.Tooltip(
        text: packs[index].displayName,
        preferredDirection: preferredTooltipDirection,
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
          return staggered
              ? buildListItemStaggered(packIndex)
              : buildListItem(packIndex);
        },
      ),
    );
  }

  Widget buildListItem(int packIndex) {
    var pack = packs[packIndex];
    var list = onlyEmoji
        ? pack.emoji
        : onlyStickers
            ? pack.stickers
            : pack.emotes;

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
            children: list.map((e) => buildEmoticon(e)).toList(),
          )
        ],
      ),
    );
  }

  Widget buildListItemStaggered(int packIndex) {
    var pack = packs[packIndex];
    var list = onlyEmoji
        ? pack.emoji
        : onlyStickers
            ? pack.stickers
            : pack.emotes;

    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 5, 4, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(0, 4, 0, 0),
            child: tiamat.Text.labelLow(packs[packIndex].displayName),
          ),
          MasonryGridView.extent(
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 8,
            mainAxisSpacing: 3,
            maxCrossAxisExtent: size,
            shrinkWrap: true,
            itemCount: list.length,
            itemBuilder: (context, index) {
              return InkWell(
                  borderRadius: BorderRadius.circular(8),
                  onTap: () => onEmoticonPressed?.call(list[index]),
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: FittedBox(
                        fit: BoxFit.cover, child: EmojiWidget(list[index])),
                  ));
            },
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
