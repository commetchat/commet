import 'package:commet/client/client.dart';
import 'package:commet/client/room.dart';
import 'package:commet/client/room_preview.dart';
import 'package:flutter/material.dart';
import 'package:tiamat/tiamat.dart';
import 'package:tiamat/tiamat.dart' as tiamat;

class RoomPreviewView extends StatelessWidget {
  const RoomPreviewView({required this.previewData, super.key});
  final RoomPreview previewData;
  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        if (previewData.avatar != null)
          ImageButton(
            size: 90,
            image: previewData.avatar!,
            placeholderColor: previewData.color,
            placeholderText: previewData.displayName,
          ),
        Flexible(
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                tiamat.Text.largeTitle(previewData.displayName),
                Row(
                  spacing: 8,
                  children: [
                    if (previewData.type != null)
                      tiamat.Tooltip(
                          text: previewData.type!.string,
                          child: Icon(size: 15, previewData.type!.icon)),
                    if (previewData.numMembers != null)
                      Row(
                        children: [
                          Icon(size: 15, Icons.people),
                          tiamat.Text.labelLow("${previewData.numMembers}")
                        ],
                      ),
                    Icon(
                        size: 15,
                        switch (previewData.visibility) {
                          null => Icons.lock,
                          RoomVisibility.public => Icons.public,
                          RoomVisibility.private => Icons.lock,
                          RoomVisibility.invite => Icons.lock,
                          RoomVisibility.knock => Icons.lock,
                        })
                  ],
                ),
                if (previewData.topic != null)
                  Flexible(
                      child: tiamat.Text.labelLow(
                    previewData.topic!,
                  ))
              ],
            ),
          ),
        )
      ],
    );
  }
}
