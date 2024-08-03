import 'package:commet/client/components/gif/gif_component.dart';
import 'package:commet/config/build_config.dart';
import 'package:commet/ui/molecules/emoji_picker.dart';
import 'package:commet/ui/molecules/gif_picker.dart';
import 'package:commet/ui/molecules/sticker_picker.dart';
import 'package:commet/client/components/gif/gif_search_result.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:tiamat/tiamat.dart' as tiamat;

import '../../client/components/emoticon/emoji_pack.dart';
import '../../client/components/emoticon/emoticon.dart';

class EmoticonPicker extends StatefulWidget {
  const EmoticonPicker({
    super.key,
    required this.emoji,
    required this.stickers,
    this.allowGifSearch = false,
    this.onEmojiPressed,
    this.onStickerPressed,
    this.onGifPressed,
    this.gifComponent,
    this.packListAxis = Axis.vertical,
  });
  final List<EmoticonPack> emoji;
  final List<EmoticonPack> stickers;
  final GifComponent? gifComponent;
  final bool allowGifSearch;
  final void Function(Emoticon emoticon)? onEmojiPressed;
  final void Function(Emoticon emoticon)? onStickerPressed;
  final Future<void> Function(GifSearchResult emoticon)? onGifPressed;
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
                  onlyEmoji: true,
                  onEmoticonPressed: (emoticon) =>
                      widget.onEmojiPressed?.call(emoticon),
                ),
              ),
              Tab(
                child: StickerPicker(
                  packs: widget.stickers,
                  stickerPicked: (sticker) =>
                      widget.onStickerPressed?.call(sticker),
                ),
              ),
              if (widget.allowGifSearch && widget.gifComponent != null)
                Tab(
                  child: GifPicker(
                    search: widget.gifComponent!.search,
                    placeholderText: widget.gifComponent!.searchPlaceholder,
                    gifPicked: widget.onGifPressed,
                  ),
                )
            ]),
          ),
          tiamat.Tile.low(
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
