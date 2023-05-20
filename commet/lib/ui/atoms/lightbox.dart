import 'dart:async';

import 'package:commet/cache/file_provider.dart';
import 'package:commet/config/build_config.dart';
import 'package:commet/ui/molecules/video_player/video_player.dart';
import 'package:flutter/material.dart';
import 'package:tiamat/atoms/popup_dialog.dart';
import 'dart:ui' as ui;

class Lightbox extends StatefulWidget {
  const Lightbox({
    this.image,
    this.video,
    this.thumbnail,
    this.aspectRatio,
    super.key,
  });
  final ImageProvider? image;
  final FileProvider? video;
  final ImageProvider? thumbnail;
  final double? aspectRatio;

  @override
  State<Lightbox> createState() => _LightboxState();

  static void show(
    BuildContext context, {
    ImageProvider? image,
    ImageProvider? thumbnail,
    FileProvider? video,
    double? aspectRatio,
  }) {
    showGeneralDialog(
        context: context,
        barrierDismissible: false,
        barrierLabel: "LIGHTBOX",
        barrierColor: PopupDialog.barrierColor,
        pageBuilder: (context, _, __) {
          return Lightbox(
            image: image,
            video: video,
            aspectRatio: aspectRatio,
            thumbnail: thumbnail,
          );
        },
        transitionDuration: const Duration(milliseconds: 300),
        transitionBuilder: (context, animation, secondaryAnimation, child) =>
            SlideTransition(
              position:
                  Tween(begin: const Offset(0, 1), end: const Offset(0, 0))
                      .animate(CurvedAnimation(
                          parent: animation, curve: Curves.easeOutCubic)),
              child: child,
            ));
  }
}

class _LightboxState extends State<Lightbox> {
  double aspectRatio = 1;
  @override
  void initState() {
    super.initState();

    if (widget.aspectRatio == null) {
      getImageInfo();
    } else {
      aspectRatio = widget.aspectRatio!;
    }
  }

  void getImageInfo() async {
    var image = await getImage();
    setState(() {
      aspectRatio = image.width / image.height;
    });
  }

  Future<ui.Image> getImage() {
    Completer<ui.Image> completer = Completer<ui.Image>();

    widget.image!
        .resolve(const ImageConfiguration())
        .addListener(ImageStreamListener((info, synchronousCall) {
      if (!completer.isCompleted) {
        completer.complete(info.image);
      }
    }));
    return completer.future;
  }

  void dismiss() {
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        dismiss();
      },
      child: Container(
        color: Colors.transparent,
        child: Padding(
          padding: const EdgeInsets.all(BuildConfig.MOBILE ? 10 : 100.0),
          child: SafeArea(
            child: Container(
              alignment: Alignment.center,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: AspectRatio(
                    aspectRatio: aspectRatio,
                    child: widget.image != null
                        ? Image(
                            fit: BoxFit.cover,
                            image: widget.image!,
                            isAntiAlias: true,
                            filterQuality: FilterQuality.medium,
                          )
                        : widget.video != null
                            ? VideoPlayer(
                                widget.video!,
                                showProgressBar: true,
                                canGoFullscreen: false,
                                thumbnail: widget.thumbnail,
                              )
                            : const Placeholder()),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
