import 'package:commet/ui/molecules/emoji_picker.dart';
import 'package:commet/client/components/emoticon/emoji_pack.dart';
import 'package:commet/utils/gif_search/gif_search_result.dart';
import 'package:commet/utils/gif_search/tenor_search.dart';
import 'package:flutter/material.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart';

import '../../config/build_config.dart';
import '../../client/components/emoticon/emoticon.dart';
import '../../utils/emoji/unicode_emoji.dart';

@WidgetbookUseCase(name: 'Sticker Picker', type: StickerPicker)
@Deprecated("widgetbook")
Widget wbStickerPickerDefault(BuildContext context) {
  return Center(
    child: SizedBox(
        height: 350,
        child: FutureBuilder(
            future: UnicodeEmojis.load(),
            builder: (BuildContext context, AsyncSnapshot<dynamic> snapshot) =>
                snapshot.hasData
                    ? StickerPicker(
                        packs: snapshot.data as List<EmoticonPack>,
                        search: TenorSearch.search,
                        canSearchGif: true,
                        stickerPicked: (sticker) =>
                            // ignore: avoid_print
                            print("Sticker picked: ${sticker.shortcode}"),
                        gifPicked: (gif) =>
                            // ignore: avoid_print
                            print("Gif picked: ${gif.fullResUrl}"),
                      )
                    : const Center(
                        child: CircularProgressIndicator(),
                      ))),
  );
}

@WidgetbookUseCase(name: 'Sticker Picker Search Disabled', type: StickerPicker)
@Deprecated("widgetbook")
Widget wbStickerPickerNoSearch(BuildContext context) {
  return Center(
    child: SizedBox(
        height: 350,
        child: FutureBuilder(
            future: UnicodeEmojis.load(),
            builder: (BuildContext context, AsyncSnapshot<dynamic> snapshot) =>
                snapshot.hasData
                    ? StickerPicker(
                        packs: snapshot.data as List<EmoticonPack>,
                        stickerPicked: (sticker) =>
                            // ignore: avoid_print
                            print("Sticker picked: ${sticker.shortcode}"),
                        canSearchGif: false,
                      )
                    : const Center(
                        child: CircularProgressIndicator(),
                      ))),
  );
}

class StickerPicker extends StatefulWidget {
  const StickerPicker(
      {super.key,
      this.packs,
      this.canSearchGif = false,
      this.search,
      this.gifPicked,
      this.stickerPicked});
  final bool canSearchGif;
  final List<EmoticonPack>? packs;
  final Function(Emoticon sticker)? stickerPicked;
  final Function(GifSearchResult gif)? gifPicked;

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
      packButtonSize: BuildConfig.MOBILE ? 42 : 32,
      size: 100,
      staggered: true,
      onlyStickers: true,
      onEmoticonPressed: (e) => widget.stickerPicked?.call(e),
    );
  }
}
