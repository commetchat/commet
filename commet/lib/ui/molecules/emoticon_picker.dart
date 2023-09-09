import 'package:commet/config/build_config.dart';
import 'package:commet/ui/molecules/emoji_picker.dart';
import 'package:commet/ui/molecules/gif_picker.dart';
import 'package:commet/ui/molecules/sticker_picker.dart';
import 'package:commet/utils/emoji/unicode_emoji.dart';
import 'package:commet/utils/gif_search/gif_search_result.dart';
import 'package:commet/utils/gif_search/tenor_search.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart';
import 'package:tiamat/tiamat.dart' as tiamat;

import '../../client/components/emoticon/emoji_pack.dart';
import '../../client/components/emoticon/emoticon.dart';

@UseCase(name: 'Emoticon Picker', type: EmoticonPicker)
@Deprecated("widgetbook")
Widget wbEmoticonPicker(BuildContext context) {
  return Center(
    child: SizedBox(
        //width: 350,
        height: 450,
        child: FutureBuilder(
            future: UnicodeEmojis.load(),
            builder: (BuildContext context, AsyncSnapshot<dynamic> snapshot) =>
                snapshot.hasData
                    ? EmoticonPicker(
                        emoji: snapshot.data as List<EmoticonPack>,
                        stickers: snapshot.data as List<EmoticonPack>,
                      )
                    : const Center(
                        child: CircularProgressIndicator(),
                      ))),
  );
}

@UseCase(name: 'Emoticon Picker With Gif', type: EmoticonPicker)
@Deprecated("widgetbook")
Widget wbEmoticonPickerWithGif(BuildContext context) {
  return Center(
    child: SizedBox(
        //width: 350,
        height: 450,
        child: FutureBuilder(
            future: UnicodeEmojis.load(),
            builder: (BuildContext context, AsyncSnapshot<dynamic> snapshot) =>
                snapshot.hasData
                    ? EmoticonPicker(
                        emoji: snapshot.data as List<EmoticonPack>,
                        stickers: snapshot.data as List<EmoticonPack>,
                        allowGifSearch: true,
                      )
                    : const Center(
                        child: CircularProgressIndicator(),
                      ))),
  );
}

class EmoticonPicker extends StatefulWidget {
  const EmoticonPicker({
    super.key,
    required this.emoji,
    required this.stickers,
    this.allowGifSearch = false,
    this.onEmojiPressed,
    this.onStickerPressed,
    this.onGifPressed,
    this.emojiSize = 38,
    this.packSize = 32,
    this.packListAxis = Axis.vertical,
  });
  final List<EmoticonPack> emoji;
  final List<EmoticonPack> stickers;
  final bool allowGifSearch;
  final void Function(Emoticon emoticon)? onEmojiPressed;
  final void Function(Emoticon emoticon)? onStickerPressed;
  final Future<void> Function(GifSearchResult emoticon)? onGifPressed;
  final double emojiSize;
  final double packSize;
  final Axis packListAxis;

  @override
  State<EmoticonPicker> createState() => _EmoticonPickerState();
}

class _EmoticonPickerState extends State<EmoticonPicker>
    with TickerProviderStateMixin {
  late TabController controller;

  String get labelEmojiPickerEmojiTab => Intl.message("Emoji",
      desc: "Label for the emoji tab in emoji picker",
      name: "labelEmojiPickerEmojiTab");

  String get labelEmojiPickerStickerTab => Intl.message("Sticker",
      desc: "Label for the sticker tab in the emoji picker",
      name: "labelEmojiPickerStickerTab");

  String get labelEmojiPickerGifTab => Intl.message("Gif",
      desc: "Label for the gif search tab in the emoji picker",
      name: "labelEmojiPickerGifTab");

  @override
  void initState() {
    controller = TabController(length: 3, vsync: this);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Expanded(
            child: TabBarView(controller: controller, children: [
              Tab(
                child: EmojiPicker(
                  widget.emoji,
                  packButtonSize: BuildConfig.MOBILE ? 42 : 32,
                  size: BuildConfig.MOBILE ? 42 : 38,
                  onlyEmoji: true,
                  onEmoticonPressed: (emoticon) =>
                      widget.onEmojiPressed?.call(emoticon),
                ),
              ),
              Tab(
                child: StickerPicker(
                  canSearchGif: widget.allowGifSearch,
                  packs: widget.stickers,
                  search: TenorSearch.search,
                  stickerPicked: (sticker) =>
                      widget.onStickerPressed?.call(sticker),
                ),
              ),
              if (widget.allowGifSearch)
                Tab(
                  child: GifPicker(
                    search: TenorSearch.search,
                    gifPicked: widget.onGifPressed,
                  ),
                )
            ]),
          ),
          tiamat.Tile.low3(
            child: SizedBox(
              height: 40,
              child: TabBar(controller: controller, tabs: [
                Tab(
                  text: labelEmojiPickerEmojiTab,
                ),
                Tab(text: labelEmojiPickerStickerTab),
                if (widget.allowGifSearch) Tab(text: labelEmojiPickerGifTab)
              ]),
            ),
          ),
        ],
      ),
    );
  }
}
