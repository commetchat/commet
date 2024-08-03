import 'package:commet/config/build_config.dart';
import 'package:commet/ui/molecules/emoji_picker.dart';
import 'package:commet/client/components/emoticon/emoji_pack.dart';
import 'package:commet/client/components/gif/gif_search_result.dart';
import 'package:flutter/material.dart';

import '../../client/components/emoticon/emoticon.dart';

class StickerPicker extends StatefulWidget {
  const StickerPicker(
      {super.key,
      this.packs,
      this.canSearchGif = false,
      this.search,
      this.gifPicked,
      this.size = BuildConfig.MOBILE ? 125 : 125,
      this.packSize = BuildConfig.MOBILE ? 48 : 42,
      this.stickerPicked});
  final bool canSearchGif;
  final List<EmoticonPack>? packs;
  final Function(Emoticon sticker)? stickerPicked;
  final Function(GifSearchResult gif)? gifPicked;
  final double size;
  final double packSize;

  final Future<List<GifSearchResult>> Function(String query)? search;

  @override
  State<StickerPicker> createState() => _StickerPickerState();
}

class _StickerPickerState extends State<StickerPicker> {
  @override
  Widget build(BuildContext context) {
    return buildStickers();
  }

  Widget buildStickers() {
    return EmojiPicker(
      widget.packs!,
      packButtonSize: widget.packSize,
      size: widget.size,
      staggered: true,
      onlyStickers: true,
      onEmoticonPressed: (e) => widget.stickerPicked?.call(e),
    );
  }
}
