import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:tiamat/tiamat.dart' as tiamat;

class TimelineEventViewSticker extends StatefulWidget {
  const TimelineEventViewSticker(this.image,
      {this.previewMedia = false, this.stickerName, super.key});
  final bool previewMedia;
  final String? stickerName;
  final ImageProvider image;

  @override
  State<TimelineEventViewSticker> createState() =>
      _TimelineEventViewStickerState();
}

class _TimelineEventViewStickerState extends State<TimelineEventViewSticker> {
  bool showSticker = false;

  static String get promptShowSticker => Intl.message(
        "Show sticker",
        name: "promptShowSticker",
        desc:
            "Prompt to display a sticker, shown when media previews are disabled",
      );

  @override
  void initState() {
    showSticker = widget.previewMedia;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: SizedBox(
        height: 200,
        child: showSticker
            ? GestureDetector(
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
