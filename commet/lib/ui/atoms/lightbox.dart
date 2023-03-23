import 'dart:async';

import 'package:commet/config/build_config.dart';
import 'package:flutter/material.dart';
import 'package:flutter/src/widgets/framework.dart';
import 'package:flutter/src/widgets/placeholder.dart';
import 'package:tiamat/atoms/popup_dialog.dart';
import 'dart:ui' as ui;

class Lightbox extends StatefulWidget {
  const Lightbox({required this.image, super.key});
  final ImageProvider image;
  @override
  State<Lightbox> createState() => _LightboxState();

  static void show(BuildContext context, {required ImageProvider image}) {
    showGeneralDialog(
        context: context,
        barrierDismissible: true,
        barrierLabel: "LIGHTBOX",
        barrierColor: PopupDialog.barrierColor,
        pageBuilder: (context, _, __) {
          return Lightbox(
            image: image,
          );
        },
        transitionDuration: const Duration(milliseconds: 300),
        transitionBuilder: (context, animation, secondaryAnimation, child) => SlideTransition(
              position: Tween(begin: const Offset(0, 1), end: const Offset(0, 0))
                  .animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic)),
              child: child,
            ));
  }
}

class _LightboxState extends State<Lightbox> {
  double aspectRatio = 1;

  @override
  void initState() {
    super.initState();
    getImageInfo();
  }

  void getImageInfo() async {
    var image = await getImage();
    setState(() {
      aspectRatio = image.width / image.height;
    });
  }

  Future<ui.Image> getImage() {
    Completer<ui.Image> completer = new Completer<ui.Image>();
    widget.image.resolve(new ImageConfiguration()).addListener(ImageStreamListener((info, synchronousCall) {
      completer.complete(info.image);
    }));
    return completer.future;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(BuildConfig.MOBILE ? 10 : 100.0),
      child: Container(
        alignment: Alignment.center,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: AspectRatio(
            aspectRatio: aspectRatio,
            child: Image(
              image: widget.image,
              isAntiAlias: true,
              filterQuality: FilterQuality.high,
            ),
          ),
        ),
      ),
    );
  }
}
