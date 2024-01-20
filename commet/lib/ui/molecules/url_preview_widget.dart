import 'package:commet/client/components/url_preview/url_preview_component.dart';
import 'package:flutter/material.dart';
import 'package:tiamat/atoms/tile.dart';
import 'package:tiamat/tiamat.dart' as tiamat;

class UrlPreviewWidget extends StatelessWidget {
  const UrlPreviewWidget(this.data, {super.key, this.onTap});
  final UrlPreviewData data;
  final void Function()? onTap;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Tile.low1(
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (data.image != null) image(),
                        const SizedBox(
                          width: 10,
                        ),
                        body(context)
                      ],
                    )
                  ]),
            ),
          ),
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
            image: data.image!,
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
          if (data.siteName != null) tiamat.Text.labelLow(data.siteName!),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (data.title != null) tiamat.Text.labelEmphasised(data.title!),
              if (data.description != null)
                tiamat.Text.tiny(
                  data.description!,
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
