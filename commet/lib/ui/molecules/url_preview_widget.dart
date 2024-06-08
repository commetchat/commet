import 'dart:math';

import 'package:commet/client/components/url_preview/url_preview_component.dart';
import 'package:commet/ui/atoms/shimmer_loading.dart';
import 'package:flutter/material.dart';
import 'package:tiamat/atoms/tile.dart';
import 'package:tiamat/config/style/theme_extensions.dart';
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
      child: Tile.low1(
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
                          const BoxConstraints.tightFor(height: 70, width: 500),
                      child: widget.data == null
                          ? buildLoadingDisplay()
                          : Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (widget.data!.image != null) image(),
                                const SizedBox(
                                  width: 10,
                                ),
                                body(context)
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
        child: Row(
          children: [
            ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: ConstrainedBox(
                    constraints:
                        const BoxConstraints(maxHeight: 70, maxWidth: 100),
                    child: Container(
                      color: color,
                    ))),
            const SizedBox(
              width: 10,
            ),
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
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget image() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(4),
      child: ConstrainedBox(
          constraints: const BoxConstraints(maxHeight: 70, maxWidth: 100),
          child: Image(
            image: widget.data!.image!,
            filterQuality: FilterQuality.medium,
          )),
    );
  }

  Widget body(BuildContext context) {
    return Flexible(
      child: Column(
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
      ),
    );
  }
}
