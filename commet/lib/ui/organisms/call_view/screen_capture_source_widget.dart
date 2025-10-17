import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';

import 'package:tiamat/tiamat.dart' as tiamat;

class ScreenCaptureSourceWidget extends StatefulWidget {
  const ScreenCaptureSourceWidget(this.source, this.onThumbnailChanged,
      {this.onTap, super.key});
  final DesktopCapturerSource source;
  final Stream<DesktopCapturerSource> onThumbnailChanged;
  final Function()? onTap;

  @override
  State<ScreenCaptureSourceWidget> createState() =>
      _ScreenCaptureSourceWidgetState();
}

class _ScreenCaptureSourceWidgetState extends State<ScreenCaptureSourceWidget> {
  late List<StreamSubscription> subs;
  Uint8List? thumbnailData = null;

  @override
  void initState() {
    super.initState();

    subs = [
      widget.source.onThumbnailChanged.stream.listen((event) {
        setState(() {
          thumbnailData = event;
        });
      }),
      widget.onThumbnailChanged.listen((source) {
        if (source.id == widget.source.id) {
          setState(() {
            thumbnailData ??= source.thumbnail;
          });
        }
      })
    ];
  }

  @override
  void dispose() {
    for (var sub in subs) {
      sub.cancel();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: tiamat.Tile.low(
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: widget.onTap,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
                  child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: buildImage()),
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: tiamat.Text.labelLow(widget.source.name),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget buildImage() {
    if (thumbnailData != null) {
      return Image.memory(thumbnailData!);
    } else {
      return const SizedBox(
        width: 200,
        height: 200,
        child: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }
  }
}
