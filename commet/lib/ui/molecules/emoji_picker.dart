import 'package:commet/client/components/emoticon/emoticon.dart';
import 'package:commet/config/build_config.dart';
import 'package:commet/utils/autofill_utils.dart';
import 'package:flutter/material.dart';
import 'package:tiamat/atoms/image_button.dart';
import 'package:tiamat/tiamat.dart' as tiamat;
import 'package:commet/client/components/emoticon/emoji_pack.dart';
import 'package:commet/ui/atoms/emoji_widget.dart';

class EmojiPicker extends StatefulWidget {
  EmojiPicker(this.packs,
      {super.key,
      this.size = BuildConfig.MOBILE ? 48 : 42,
      this.onEmoticonPressed,
      this.packButtonSize = BuildConfig.MOBILE ? 48 : 42,
      this.onlyEmoji = false,
      this.onlyStickers = false,
      this.staggered = false,
      this.searchDelegate,
      this.focus,
      this.preferredTooltipDirection = AxisDirection.right,
      this.packListAxis = Axis.vertical});
  final void Function(Emoticon emoticon)? onEmoticonPressed;
  final List<EmoticonPack> packs;
  final double size;
  final Axis packListAxis;
  final FocusNode? focus;
  final double packButtonSize;
  final bool staggered;
  final bool onlyStickers;
  final bool onlyEmoji;
  final List<AutofillSearchResultEmoticon> Function(String text)?
      searchDelegate;
  final AxisDirection preferredTooltipDirection;

  @override
  State<EmojiPicker> createState() => _EmojiPickerState();
}

class _EmojiPickerState extends State<EmojiPicker> {
  int crossAxisCount = 12;
  double searchBarSize = 50;
  double headerSize = 40;
  GlobalKey key = GlobalKey();
  ScrollController controller = ScrollController();
  TextEditingController textController = TextEditingController();

  List<AutofillSearchResultEmoticon>? searchResults;

  @override
  void initState() {
    super.initState();
  }

  List<Emoticon> getEmoticonList(EmoticonPack pack) {
    if (widget.onlyEmoji) {
      return pack.emoji;
    }

    if (widget.onlyStickers) {
      return pack.stickers;
    }

    return pack.emotes;
  }

  void onSearchTextChanged(String value) {
    setState(() {
      if (value == "") {
        searchResults = null;
      } else {
        searchResults = widget.searchDelegate?.call(value);
      }
    });
  }

  void jumpToPack(int packIndex) {
    if (packIndex == 0) {
      controller.jumpTo(0);
      return;
    }

    if (key.currentContext?.findRenderObject() != null) {
      var renderBox = key.currentContext!.findRenderObject() as RenderBox;
      var boxSize = renderBox.size.width / crossAxisCount.toDouble();

      double offset = 0;
      if (widget.searchDelegate != null) {
        offset += searchBarSize.toDouble();
      }

      for (int i = 0; i < packIndex; i++) {
        offset += headerSize;

        var numEmotes = getEmoticonList(widget.packs[i]).length;
        var numRows = (numEmotes / crossAxisCount).ceil();

        offset += numRows.toDouble() * boxSize;
      }

      controller.jumpTo(offset);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Material(
        color: Colors.transparent,
        child: widget.packListAxis == Axis.vertical
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
              width: widget.packButtonSize,
              child: ScrollConfiguration(
                behavior:
                    ScrollConfiguration.of(context).copyWith(scrollbars: false),
                child: ListView.builder(
                  itemCount: widget.packs.length,
                  padding: EdgeInsets.all(0),
                  itemBuilder: (context, index) {
                    return Padding(
                      padding: const EdgeInsets.fromLTRB(0, 2, 0, 2),
                      child: buildPackButton(index, () {
                        jumpToPack(index);
                      }),
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
              constraints: BoxConstraints(maxHeight: widget.packButtonSize),
              child: ScrollConfiguration(
                behavior:
                    ScrollConfiguration.of(context).copyWith(scrollbars: false),
                child: ListView.builder(
                  padding: EdgeInsets.all(0),
                  scrollDirection: Axis.horizontal,
                  itemCount: widget.packs.length,
                  itemBuilder: (context, index) {
                    return Padding(
                      padding: const EdgeInsets.fromLTRB(2, 0, 2, 0),
                      child: buildPackButton(index, () {
                        jumpToPack(index);
                      }),
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
        text: widget.packs[index].displayName,
        preferredDirection: widget.preferredTooltipDirection,
        child: ImageButton(
          size: widget.packButtonSize,
          iconSize: widget.packButtonSize - 8,
          icon: widget.packs[index].icon,
          image: widget.packs[index].image,
          onTap: onTap,
        ),
      ),
    );
  }

  Expanded buildEmojiList() {
    return Expanded(
        key: key,
        child: LayoutBuilder(builder: (context, constraints) {
          var count = (constraints.maxWidth / widget.size).toInt();
          if (count != crossAxisCount) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              setState(() {
                crossAxisCount = count;
              });
            });
          }

          return CustomScrollView(
            controller: controller,
            slivers: [
              if (widget.searchDelegate != null)
                SliverList(
                    delegate: SliverChildListDelegate([
                  SizedBox(
                      height: searchBarSize,
                      child: Container(
                        color:
                            Theme.of(context).colorScheme.surfaceContainerLow,
                        child: Center(
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(8, 0, 8, 0),
                            child: TextField(
                              focusNode: widget.focus,
                              controller: textController,
                              onChanged: onSearchTextChanged,
                              decoration: InputDecoration(
                                  border: InputBorder.none,
                                  hintText: "Search",
                                  icon: Icon(Icons.search)),
                            ),
                          ),
                        ),
                      ))
                ])),
              if (searchResults?.isEmpty == true)
                SliverList(
                    delegate: SliverChildListDelegate([
                  SizedBox(
                    height: 50,
                    child: Center(
                        child: tiamat.Text.labelLow("No results found :(")),
                  ),
                ])),
              if (searchResults?.isNotEmpty == true)
                SliverGrid.builder(
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: crossAxisCount),
                  itemCount: searchResults!.length,
                  itemBuilder: (context, index) {
                    var emote = searchResults![index].emoticon;
                    return buildEmoticon(emote);
                  },
                ),
              if (searchResults == null)
                for (var pack in widget.packs) ...[
                  SliverList(
                      delegate: SliverChildListDelegate([
                    SizedBox(
                      height: headerSize,
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(8, 0, 8, 0),
                        child: Align(
                            alignment: AlignmentGeometry.centerLeft,
                            child: Text(pack.displayName)),
                      ),
                    ),
                  ])),
                  SliverGrid.builder(
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: crossAxisCount),
                    itemCount: getEmoticonList(pack).length,
                    itemBuilder: (context, index) {
                      var emote = getEmoticonList(pack)[index];
                      return buildEmoticon(emote);
                    },
                  )
                ],
            ],
          );
        }));
  }

  Widget buildEmoticon(Emoticon emoticon) {
    return SizedBox(
        width: widget.size,
        height: widget.size,
        child: InkWell(
            borderRadius: BorderRadius.circular(3),
            onTap: () => widget.onEmoticonPressed?.call(emoticon),
            mouseCursor: SystemMouseCursors.click,
            child: Padding(
                padding: const EdgeInsets.all(2.0),
                child: Center(
                    child: EmojiWidget(
                  emoticon,
                  height: widget.size,
                )))));
  }
}
