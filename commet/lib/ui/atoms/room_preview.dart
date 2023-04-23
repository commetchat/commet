import 'package:commet/client/preview_data.dart';
import 'package:flutter/material.dart';
import 'package:tiamat/tiamat.dart';
import 'package:tiamat/tiamat.dart' as tiamat;

class RoomPreview extends StatelessWidget {
  const RoomPreview({required this.previewData, super.key});
  final PreviewData previewData;
  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        if (previewData.avatar != null)
          ImageButton(size: 90, image: previewData.avatar!),
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (previewData.displayName != null)
                Flexible(
                    child: tiamat.Text.largeTitle(previewData.displayName!)),
              if (previewData.topic != null)
                Flexible(child: tiamat.Text.label(previewData.topic!))
            ],
          ),
        )
      ],
    );
  }
}
