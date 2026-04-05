import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:tiamat/tiamat.dart' as tiamat;

class TimelineEventViewSticker extends StatefulWidget {
  const TimelineEventViewSticker(this.image,
      {this.previewMedia = false,
      this.stickerName,
      this.isGif = false,
      this.isFavoriteGif = false,
      this.markAsFavorite,
      super.key});
  final bool previewMedia;
  final String? stickerName;
  final ImageProvider image;
  final bool isGif;
  final bool isFavoriteGif;
  final Function(bool favorite)? markAsFavorite;

  @override
  State<TimelineEventViewSticker> createState() =>
      _TimelineEventViewStickerState();
}

class _TimelineEventViewStickerState extends State<TimelineEventViewSticker> {
  bool showSticker = false;
  bool hovered = false;
  bool isFavorite = false;

  static String get promptShowSticker => Intl.message(
        "Show sticker",
        name: "promptShowSticker",
        desc:
            "Prompt to display a sticker, shown when media previews are disabled",
      );

  @override
  void initState() {
    showSticker = widget.previewMedia;
    isFavorite = widget.isFavoriteGif;
    super.initState();
  }

  @override
  void didUpdateWidget(covariant TimelineEventViewSticker oldWidget) {
    setState(() {
      isFavorite = widget.isFavoriteGif;
    });

    super.didUpdateWidget(oldWidget);
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: SizedBox(
        height: 200,
        child: showSticker
            ? MouseRegion(
                onEnter: (event) {
                  setState(() {
                    hovered = true;
                  });
                },
                onExit: (event) {
                  setState(() {
                    hovered = false;
                  });
                },
                child: Stack(
                  alignment: AlignmentGeometry.topRight,
                  children: [
                    GestureDetector(
                      onTap: widget.previewMedia == false
                          ? () => setState(() {
                                showSticker = !showSticker;
                              })
                          : null,
                      child: Image(
                        image: widget.image,
                        fit: BoxFit.cover,
                        filterQuality: FilterQuality.medium,
                      ),
                    ),
                    if (hovered)
                      Padding(
                        padding: const EdgeInsets.all(2.0),
                        child: SizedBox(
                            width: 30,
                            height: 30,
                            child: tiamat.CircleButton(
                              icon: isFavorite
                                  ? Icons.star_rounded
                                  : Icons.star_outline_rounded,
                              radius: 20,
                              color: ColorScheme.of(context)
                                  .surfaceContainer
                                  .withAlpha(80),
                              iconColor: isFavorite
                                  ? ColorScheme.of(context).primary
                                  : ColorScheme.of(context).onSurface,
                              onPressed: () {
                                widget.markAsFavorite?.call(!isFavorite);
                              },
                            )),
                      )
                  ],
                ),
              )
            : SizedBox(
                width: 200,
                child: Material(
                  color: Theme.of(context).colorScheme.surfaceBright,
                  child: InkWell(
                    onTap: () => setState(() {
                      showSticker = !showSticker;
                    }),
                    child: Center(
                        child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          tiamat.Text.label(promptShowSticker),
                          if (widget.stickerName != null)
                            tiamat.Text.labelLow(widget.stickerName!)
                        ],
                      ),
                    )),
                  ),
                ),
              ),
      ),
    );
  }
}
