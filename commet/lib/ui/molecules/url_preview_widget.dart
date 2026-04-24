import 'dart:math';

import 'package:commet/client/components/url_preview/url_preview_component.dart';
import 'package:commet/ui/atoms/lightbox.dart';
import 'package:commet/ui/atoms/message_attachment.dart';
import 'package:commet/ui/atoms/shimmer_loading.dart';
import 'package:flutter/material.dart';
import 'package:tiamat/atoms/tile.dart';
import 'package:tiamat/tiamat.dart' as tiamat;

class UrlPreviewWidget extends StatefulWidget {
  const UrlPreviewWidget(this.data, {super.key, this.onTap});
  final UrlPreviewData? data;
  final void Function()? onTap;

  @override
  State<UrlPreviewWidget> createState() => _UrlPreviewWidgetState();
}

class _UrlPreviewWidgetState extends State<UrlPreviewWidget> {
  double titleWidth = 0;
  double bodyWidth1 = 0;
  double bodyWidth2 = 0;

  @override
  void initState() {
    var rng = Random();
    titleWidth = (rng.nextDouble() * 50) + 50;
    bodyWidth1 = (rng.nextDouble() * 200) + 100;
    bodyWidth2 = (rng.nextDouble() * 200) + 100;

    super.initState();
  }

  @override
  void didChangeDependencies() {
    setState(() {});
    super.didChangeDependencies();
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Tile.surfaceContainer(
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: widget.onTap,
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ConstrainedBox(
                      constraints:
                          const BoxConstraints(maxWidth: 300, maxHeight: 240),
                      child: widget.data == null
                          ? buildLoadingDisplay()
                          : Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              mainAxisAlignment: MainAxisAlignment.start,
                              children: [
                                Align(
                                    alignment: Alignment.topLeft,
                                    child: body(context)),
                                if (hasBody)
                                  const SizedBox(
                                    width: 10,
                                    height: 10,
                                  ),
                                if (widget.data!.image != null &&
                                    widget.data?.video == null)
                                  Flexible(child: image()),
                                if (widget.data!.video != null)
                                  MessageAttachment(
                                    previewMedia: true,
                                    widget.data!.video!,
                                    constrainSize: false,
                                  )
                              ],
                            ),
                    )
                  ]),
            ),
          ),
        ),
      ),
    );
  }

  Widget buildLoadingDisplay() {
    var color = Theme.of(context).colorScheme.surfaceContainerLowest;
    return Shimmer(
      child: ShimmerLoading(
        isLoading: true,
        child: SizedBox(
          height: 300,
          child: Row(
            children: [
              Flexible(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Container(
                      height: 14,
                      width: titleWidth,
                      decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(4), color: color),
                    ),
                    const SizedBox(
                      height: 8,
                    ),
                    Container(
                      height: 10,
                      width: bodyWidth1,
                      decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(4), color: color),
                    ),
                    const SizedBox(
                      height: 5,
                    ),
                    Container(
                      height: 10,
                      width: bodyWidth2,
                      decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(4), color: color),
                    ),
                    SizedBox(
                      height: 8,
                    ),
                    ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: ConstrainedBox(
                            constraints: const BoxConstraints(
                                maxHeight: 180, maxWidth: 300),
                            child: Container(
                              color: color,
                            ))),
                  ],
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget image() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(4),
      child: InkWell(
        onTap: widget.data?.type != UrlDestinationType.video
            ? () {
                Lightbox.show(context, image: widget.data!.image);
              }
            : null,
        child: Image(
          image: widget.data!.image!,
          filterQuality: FilterQuality.medium,
          fit: BoxFit.cover,
        ),
      ),
    );
  }

  bool get hasBody =>
      widget.data?.siteName != null ||
      widget.data?.title != null ||
      widget.data?.description != null;

  Widget body(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.data!.siteName != null)
          tiamat.Text.labelLow(
            widget.data!.siteName!,
            maxLines: 1,
            overflow: TextOverflow.fade,
          ),
        Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (widget.data!.title != null)
              tiamat.Text.labelEmphasised(
                widget.data!.title!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            if (widget.data!.description != null)
              tiamat.Text.tiny(
                widget.data!.description!,
                maxLines: 2,
                color: Theme.of(context).colorScheme.secondary,
                overflow: TextOverflow.ellipsis,
              )
          ],
        )
      ],
    );
  }
}
